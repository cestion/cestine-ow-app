package com.huddlecommunity.better_native_video_player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executors

/**
 * Texture rendering backend (NativeVideoPlayerConfig.androidTextureMode):
 * the player renders into a Flutter engine texture via
 * [TextureRegistry.SurfaceProducer] instead of a platform view, so feed
 * tiles become ordinary Flutter textures — no hybrid-composition cost,
 * and RepaintBoundary/raster caching work again. Blueprint:
 * video_player_android's TextureVideoPlayer (Impeller-compatible).
 *
 * Not a PlatformView: the Dart widget allocates the viewId (from
 * platformViewsRegistry, so it can never collide with real platform view
 * ids), creates this backend via the global 'createTextureView' method, and
 * renders Texture(textureId). All channel routing, events and lifecycle
 * flows are identical to a platform view thanks to [PlayerBackendSession].
 * Disposal arrives via the Dart 'viewDisposed' hook (there is no engine
 * dispose callback for plugin-owned textures).
 *
 * Capabilities: aspect ratio is Dart-side (the 'videoSize' event — there is
 * no native AspectRatioFrameLayout here); native controls are impossible
 * (documented fallback to a platform view); native fullscreen is replaced
 * by Dart fullscreen (no Android View to move into a dialog); activity-level
 * PiP and media notifications are unaffected.
 */
@UnstableApi
class TextureVideoPlayer(
    context: Context,
    override val backendViewId: Long,
    args: Map<String, Any>?,
    binaryMessenger: BinaryMessenger,
    private val surfaceProducer: TextureRegistry.SurfaceProducer
) : VideoPlayerBackend, TextureRegistry.SurfaceProducer.Callback {

    companion object {
        private const val TAG = "TextureVideoPlayer"
    }

    private val session: PlayerBackendSession
    private val player: ExoPlayer get() = session.player

    private var isDisposed = false

    // Surface currently attached to the player (for targeted clearVideoSurface:
    // a sibling backend may have taken over the output in the meantime).
    private var attachedSurface: Surface? = null

    // A texture has no readable Android View, so captureCurrentFrame decodes
    // from the source instead of copying pixels. Off the main thread, and
    // cached so repeated asks during one session stay cheap.
    private val captureExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var lastFrameJpeg: ByteArray? = null

    private val videoSizeListener = object : Player.Listener {
        override fun onVideoSizeChanged(videoSize: VideoSize) {
            sendVideoSize(videoSize)
        }
    }

    init {
        session = PlayerBackendSession(
            context = context,
            viewId = backendViewId,
            args = args,
            binaryMessenger = binaryMessenger,
            onSiblingDisposed = {
                if (!isDisposed) {
                    attachSurface()
                    session.restoreViewportConstraints()
                    session.emitCurrentState()
                }
            }
        )

        surfaceProducer.setCallback(this)
        attachSurface()

        player.addListener(videoSizeListener)
        // Seed for shared players already mid-playback
        sendVideoSize(player.videoSize)

        NpLog.d(TAG, "TextureVideoPlayer created (viewId $backendViewId, textureId ${surfaceProducer.id()})")
    }

    private fun attachSurface() {
        val surface = surfaceProducer.surface
        player.setVideoSurface(surface)
        attachedSurface = surface
    }

    // SurfaceProducer.Callback — under Impeller the engine destroys and
    // recreates texture surfaces around backgrounding.
    override fun onSurfaceAvailable() {
        if (isDisposed) return
        NpLog.d(TAG, "Surface available for texture view $backendViewId")
        attachSurface()
    }

    override fun onSurfaceCleanup() {
        NpLog.d(TAG, "Surface cleanup for texture view $backendViewId")
        // Audio (and the media session) keep running without a video output.
        player.setVideoSurface(null)
        attachedSurface = null
    }

    private fun sendVideoSize(videoSize: VideoSize) {
        if (videoSize.width == 0 || videoSize.height == 0) return
        // SurfaceTexture-backed producers (Impeller default) crop/rotate in
        // the engine; the ImageReader backend needs Dart-side correction.
        val rotationCorrection = if (surfaceProducer.handlesCropAndRotation()) {
            0
        } else {
            player.videoFormat?.rotationDegrees ?: 0
        }
        session.eventHandler.sendEvent(
            "videoSize",
            mapOf(
                "width" to (videoSize.width * videoSize.pixelWidthHeightRatio).toInt(),
                "height" to videoSize.height,
                "rotationCorrection" to rotationCorrection
            )
        )
    }

    override fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setShowNativeControls" -> {
                val show = call.argument<Boolean>("show") ?: true
                if (show) {
                    // Documented androidTextureMode limitation: a texture has
                    // no controller UI; views needing native controls fall
                    // back to the platform view at creation.
                    NpLog.w(TAG, "setShowNativeControls(true) ignored - view $backendViewId renders as a texture")
                }
                result.success(null)
            }
            "ensureSurfaceConnected" -> {
                attachSurface()
                result.success(null)
            }
            "setViewportSize" -> {
                val width = (call.argument<Number>("width"))?.toInt() ?: 0
                val height = (call.argument<Number>("height"))?.toInt() ?: 0
                session.setViewportSize(width, height, isFullScreen = false)
                result.success(null)
            }
            "setEmbeddedTextScale" -> {
                // Texture mode has no native SubtitleView (captions render via
                // the Flutter sidecar overlay); store so a later platform-view
                // rebind of the shared session picks it up.
                val scale = (call.argument<Number>("scale"))?.toFloat() ?: 1f
                session.setEmbeddedTextScale(scale)
                result.success(null)
            }
            "enterFullScreen", "exitFullScreen" -> {
                // No Android View to move into a fullscreen dialog; the Dart
                // controller falls back to Dart fullscreen for texture views.
                result.error(
                    "TEXTURE_MODE",
                    "Native fullscreen is unavailable in texture mode; use Dart fullscreen",
                    null
                )
            }
            "captureCurrentFrame" -> handleCaptureCurrentFrame(call, result)
            else -> {
                session.methodHandler.handleMethodCall(call, result)
            }
        }
    }

    private fun handleCaptureCurrentFrame(call: MethodCall, result: MethodChannel.Result) {
        val maxWidth = call.argument<Int>("maxWidth") ?: 720
        val uri = player.currentMediaItem?.localConfiguration?.uri?.toString()
        val positionMs = player.currentPosition
        if (uri.isNullOrEmpty()) {
            result.success(lastFrameJpeg)
            return
        }
        captureExecutor.execute {
            val jpeg = VideoFrameCapture.retrieveFrameJpeg(uri, positionMs, maxWidth)
            if (jpeg != null && jpeg.isNotEmpty()) {
                lastFrameJpeg = jpeg
            }
            mainHandler.post {
                if (isDisposed) {
                    result.success(null)
                } else {
                    result.success(jpeg ?: lastFrameJpeg)
                }
            }
        }
    }

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true
        NpLog.d(TAG, "TextureVideoPlayer dispose (viewId $backendViewId)")

        // shutdown(), not shutdownNow(): a dropped capture task never posts
        // back, leaving the Dart side's MethodChannel reply pending forever.
        // Queued tasks see isDisposed and answer null.
        captureExecutor.shutdown()
        lastFrameJpeg = null
        NativeVideoPlayerPlugin.unregisterView(backendViewId)
        player.removeListener(videoSizeListener)

        session.disposeCommon(detachOutput = {
            // Targeted detach: a no-op if a sibling backend owns the output.
            attachedSurface?.let { player.clearVideoSurface(it) }
            attachedSurface = null
        })

        // Release the engine texture last (the player no longer references
        // its surface).
        surfaceProducer.release()
    }
}
