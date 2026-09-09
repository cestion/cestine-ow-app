package com.huddlecommunity.better_native_video_player

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.content.pm.ActivityInfo
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.PixelCopy
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.accessibility.CaptioningManager
import android.widget.FrameLayout
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import androidx.media3.ui.SubtitleView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import io.flutter.plugin.platform.PlatformView

/**
 * Main platform view for the native video player
 * Handles fullscreen natively without creating multiple platform views
 */
@UnstableApi
class VideoPlayerView(
    private val context: Context,
    private val viewId: Long,
    private val args: Map<String, Any>?,
    binaryMessenger: io.flutter.plugin.common.BinaryMessenger
) : PlatformView, VideoPlayerBackend {

    companion object {
        private const val TAG = "VideoPlayerView"
    }

    override val backendViewId: Long get() = viewId

    // The display-independent half (player, handlers, channels, viewport
    // capping, common dispose) lives in the session; this class keeps the
    // Android View display path and native fullscreen.
    private val session: PlayerBackendSession

    // Heavy display path: full Media3 PlayerView (inflates the complete
    // controller UI even with useController = false). Null when the
    // lightweight path is active.
    private val playerView: PlayerView?

    // Lightweight display path (lightweightInlineViews config + hidden
    // controls): bare SurfaceView in a top-crop cover frame, plus a
    // SubtitleView wired to the player's cues so captions (including the
    // native sidecar track used during PiP/fullscreen) keep rendering.
    private val lightSurfaceView: SurfaceView?

    // Same role as [lightSurfaceView] when androidTextureViewSurface is on:
    // a TextureView keeps the platform view on Flutter's Texture Layer Hybrid
    // Composition path, so Flutter clipping and z-order apply to the video.
    // Exactly one of the two is non-null on the lightweight path.
    private val lightTextureView: TextureView?
    private val lightSubtitleView: SubtitleView?
    private val lightListener: Player.Listener?

    // Opaque black view stacked above the lightweight SurfaceView (the same
    // role as PlayerView's shutter). Covers the surface between a source
    // switch and the new stream's first frame, so a resize in that window
    // cannot re-present a buffer left in the queue by the previous stream.
    private var lightShutterView: View? = null

    // Reports the video's display size to Dart in both display paths so the
    // Flutter sidecar-subtitle overlay can anchor captions to the video's
    // content rect (e.g. portrait fullscreen with a 16:9 video).
    private val videoSizeListener: Player.Listener

    // The view that displays video, whichever path is active; moved between
    // the inline container and the fullscreen dialog.
    private val videoContentView: View

    private val player: ExoPlayer get() = session.player
    private val controllerId: Int? get() = session.controllerId

    // Container that holds the player view
    // This is what Flutter sees - the player view can be moved in/out of it
    private val containerView: FrameLayout

    // Track fullscreen state
    private var isFullScreen: Boolean = false

    // Track disposal state to prevent events after disposal
    private var isDisposed: Boolean = false

    // True while this view's display surface is attached to the player.
    private var videoOutputBound: Boolean = false

    // Set when the output really must be re-attached: a sibling view was
    // disposed, this view re-entered the hierarchy, or the Surface was
    // destroyed (background / platform view recycle).
    //
    // Do NOT rebind unconditionally. `clearVideoSurfaceView` +
    // `setVideoSurfaceView` forces MediaCodec.setOutputSurface, which bumps
    // the surface generation; frames already queued from the previous
    // generation are rejected (`queueBuffer failed: -32`) and the SurfaceView
    // keeps compositing the last decoded frame of the *previous* video —
    // visible as a frozen postage stamp over the new card.
    private var needsSurfaceRebind: Boolean = false

    // Fullscreen dialog
    private var fullscreenDialog: Dialog? = null

    // Store original system UI flags and orientation
    private var originalSystemUiVisibility: Int = 0
    private var originalOrientation: Int = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED

    /// Last successful PixelCopy / retriever JPEG for [captureCurrentFrame]
    /// retries within the same session (first-frame cache).
    @Volatile
    private var lastFrameJpeg: ByteArray? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private val captureExecutor = Executors.newSingleThreadExecutor()

    init {
        NpLog.d(TAG, "Creating VideoPlayerView with id: $viewId")

        // Extract initial fullscreen state from args
        isFullScreen = args?.get("isFullScreen") as? Boolean ?: false
        NpLog.d(TAG, "Initial fullscreen state: $isFullScreen")

        session = PlayerBackendSession(
            context = context,
            viewId = viewId,
            args = args,
            binaryMessenger = binaryMessenger,
            onSiblingDisposed = {
                // A sibling's dispose may have detached the shared player's
                // output — this is a real rebind trigger.
                needsSurfaceRebind = true
                reconnectSurface()
                // Emit current state after reconnecting to ensure UI stays in sync
                session.emitCurrentState()
            }
        )

        // Set fullscreen callback for method handler
        session.methodHandler.onFullscreenRequest = { enterFullscreen ->
            handleFullscreenToggleNative(enterFullscreen)
        }

        // Create the display view: a full PlayerView, or — when the app
        // opted into lightweightInlineViews and this view hides native
        // controls — a bare SurfaceView + SubtitleView in an
        // AspectRatioFrameLayout (PlayerView inflates its complete controller
        // UI even when useController is false).
        val showNativeControls = session.showNativeControls
        val useLightView =
            (args?.get("lightweightInlineViews") as? Boolean ?: false) && !showNativeControls
        if (useLightView) {
            playerView = null
            val contentFrame = TopCropAspectFrameLayout(context).apply {
                // Cover-fill, top-aligned — short collapsed bands (comment /
                // drama sheet) keep the upper frame instead of center-crop.
                clipChildren = true
            }
            // A SurfaceView forces the engine off Texture Layer Hybrid
            // Composition (VIEW_TYPES_REQUIRE_NON_TLHC) and onto full hybrid
            // composition, where the surface is its own compositor layer that
            // ignores Flutter clipping and z-order. A TextureView stays on
            // TLHC, so Flutter can clip and order the video like any widget.
            val useTextureView = args?.get("androidTextureViewSurface") as? Boolean ?: false
            val surfaceView = if (useTextureView) null else SurfaceView(context)
            val textureView = if (useTextureView) TextureView(context) else null
            val displayView: View = surfaceView ?: textureView!!
            contentFrame.addView(
                displayView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            val shutterView = View(context).apply {
                setBackgroundColor(android.graphics.Color.BLACK)
            }
            contentFrame.addView(
                shutterView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            val subtitleView = SubtitleView(context).apply {
                setUserDefaultStyle()
                setUserDefaultTextSize()
            }
            contentFrame.addView(
                subtitleView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            if (textureView != null) {
                // Media3 installs its own SurfaceTextureListener here, so do
                // not add one — a destroyed SurfaceTexture is detected via
                // TextureView.isAvailable in isDisplaySurfaceValid() instead.
                player.setVideoTextureView(textureView)
            } else {
                player.setVideoSurfaceView(surfaceView!!)
                surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
                    override fun surfaceCreated(holder: SurfaceHolder) = Unit

                    override fun surfaceChanged(
                        holder: SurfaceHolder,
                        format: Int,
                        width: Int,
                        height: Int
                    ) = Unit

                    override fun surfaceDestroyed(holder: SurfaceHolder) {
                        // Media3 re-attaches on recreate, but the next explicit
                        // ensureSurfaceConnected must be allowed through.
                        needsSurfaceRebind = true
                    }
                })
            }
            videoOutputBound = true

            // Seed state for shared players already mid-playback, then track it
            lightShutterView = shutterView
            // TextureView samples through GL; on emulator software decoders the
            // first buffer can present coded-frame padding (green strip) before
            // the crop transform settles. Always cover until the first frame
            // callback — even when videoSize is already known from a sibling.
            shutterView.visibility =
                if (useTextureView || player.videoSize.width <= 0) {
                    View.VISIBLE
                } else {
                    View.GONE
                }
            applyLightAspectRatio(contentFrame, player.videoSize, surfaceView)
            subtitleView.setCues(player.currentCues.cues)
            val listener = object : Player.Listener {
                override fun onVideoSizeChanged(videoSize: VideoSize) {
                    applyLightAspectRatio(contentFrame, videoSize, surfaceView)
                }

                override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                    // REPEAT is the same stream seeking back to 0 (native
                    // REPEAT_MODE_ONE). Raising the black shutter races
                    // emulator soft-decode paths that often never emit a
                    // second onRenderedFirstFrame, leaving a permanent black
                    // tile after each loop. Keep the last frame visible.
                    if (reason == Player.MEDIA_ITEM_TRANSITION_REASON_REPEAT) {
                        return
                    }
                    // New stream: hide the surface until it renders. Buffers
                    // from the previous stream stay in the queue and a resize
                    // (feed scroll clipping the platform view) makes
                    // SurfaceFlinger re-present one, stretched into the new
                    // bounds — the mismatched thumbnail over the current card.
                    shutterView.visibility = View.VISIBLE
                }

                override fun onRenderedFirstFrame() {
                    shutterView.visibility = View.GONE
                }

                override fun onCues(cueGroup: CueGroup) {
                    subtitleView.setCues(cueGroup.cues)
                }
            }
            player.addListener(listener)
            lightSurfaceView = surfaceView
            lightTextureView = textureView
            lightSubtitleView = subtitleView
            lightListener = listener
            videoContentView = contentFrame
            NpLog.d(
                TAG,
                "Lightweight ${if (useTextureView) "TextureView" else "SurfaceView"} " +
                    "configured (controls hidden)"
            )
        } else {
            lightSurfaceView = null
            lightTextureView = null
            lightSubtitleView = null
            lightListener = null
            playerView = PlayerView(context).apply {
                this.player = this@VideoPlayerView.player
                useController = showNativeControls
                controllerShowTimeoutMs = 5000
                controllerHideOnTouch = true

                // Hide unnecessary buttons: settings, next, previous
                setShowNextButton(false)
                setShowPreviousButton(false)
                // Note: There's no direct method to hide settings button, but we can hide it via layout

                // Configure HDR rendering
                if (!session.enableHDR) {
                    NpLog.d(TAG, "🎨 HDR disabled for PlayerView - ExoPlayer will tone-map to SDR")
                    // ExoPlayer handles tone-mapping automatically, but we can hint at the surface level
                    // Note: More explicit control would require custom RenderersFactory
                } else {
                    NpLog.d(TAG, "🎨 HDR enabled for PlayerView")
                }

                NpLog.d(TAG, "PlayerView configured")
            }
            videoContentView = playerView
            videoOutputBound = true
        }

        applyEmbeddedTextScale()

        // Report the video's display size to Dart so the sidecar subtitle
        // overlay can pin captions to the video's content rect. Covers both
        // display paths; platform views handle crop/rotation natively, so no
        // Dart-side rotation correction is needed.
        videoSizeListener = object : Player.Listener {
            override fun onVideoSizeChanged(videoSize: VideoSize) {
                sendVideoSize(videoSize)
            }
        }
        player.addListener(videoSizeListener)
        sendVideoSize(player.videoSize)

        // For shared players that already existed, ensure surface is properly connected
        // This is crucial when returning to a video after calling releaseResources()
        if (session.isSharedPlayer) {
            NpLog.d(TAG, "Ensuring surface connection for existing shared player")
            videoContentView.post { rebindVideoOutput() }
        }

        // Create container view that holds the player view
        // This allows us to move the player view in/out for fullscreen.
        // Gravity.CENTER is required: AspectRatioFrameLayout (lightweight) and
        // PlayerView's content frame measure themselves to the video aspect and
        // would otherwise stick to TOP|START inside this FrameLayout — landscape
        // clips appear glued to the top of the feed.
        containerView = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(android.graphics.Color.BLACK)
            addView(videoContentView, contentLayoutParams())
        }

        // For shared players, also reconnect when this view is attached to a window.
        // Surface may not be ready in init; attaching ensures we rebind once the view is in the hierarchy.
        if (session.isSharedPlayer) {
            containerView.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    containerView.removeOnAttachStateChangeListener(this)
                    needsSurfaceRebind = true
                    reconnectSurface()
                }
                override fun onViewDetachedFromWindow(v: View) {}
            })
        }

        // Set up fullscreen button listener after PlayerView is configured
        // (the lightweight path has no controller, hence no fullscreen button)
        playerView?.let { pv -> pv.post {
            pv.setFullscreenButtonClickListener { enteringFullScreen ->
                NpLog.d(TAG, "Fullscreen button clicked, wants to enter: $enteringFullScreen, current state: $isFullScreen")
                
                // The button sends us the state it wants to ENTER
                // If we're already in that state, the button is out of sync (e.g., when Flutter triggered fullscreen)
                // In that case, we should do the opposite action
                val shouldEnter = if (isFullScreen && enteringFullScreen) {
                    // Button wants to enter fullscreen, but we're already in fullscreen
                    // This means the button icon is out of sync - we should exit instead
                    NpLog.d(TAG, "Button out of sync: wants to enter but already in fullscreen, exiting instead")
                    false
                } else if (!isFullScreen && !enteringFullScreen) {
                    // Button wants to exit fullscreen, but we're not in fullscreen
                    // This means the button icon is out of sync - we should enter instead
                    NpLog.d(TAG, "Button out of sync: wants to exit but not in fullscreen, entering instead")
                    true
                } else {
                    // Button is in sync with our state
                    enteringFullScreen
                }
                
                handleFullscreenToggleNative(shouldEnter)
            }
        } }

        // Handlers, observer, event channel and SharedPlayerManager
        // registration all live in the session (created above).

        NpLog.d(TAG, "VideoPlayerView initialized")
    }

    override fun getView(): View {
        // Return the container view, not the player view directly
        // This allows us to move the player view in/out for fullscreen
        return containerView
    }

    /**
     * Handles method calls from Flutter
     */
    override fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setShowNativeControls" -> {
                val show = call.argument<Boolean>("show") ?: true
                if (playerView != null) {
                    playerView.useController = show
                } else if (show) {
                    // Documented lightweightInlineViews limitation: a bare
                    // SurfaceView cannot render controls; recreate the view
                    // with showNativeControls instead.
                    NpLog.w(TAG, "setShowNativeControls(true) ignored - view $viewId is a lightweight SurfaceView")
                }
                result.success(null)
            }
            "ensureSurfaceConnected" -> {
                // Called when reconnecting after all platform views were disposed (list→detail→back).
                reconnectSurface()
                result.success(null)
            }
            "setUserInteractionEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                containerView.isClickable = enabled
                containerView.isFocusable = enabled
                containerView.isFocusableInTouchMode = enabled
                // When disabled, do not consume touches so overlays / system
                // sheets above can receive outside-dismiss taps.
                if (enabled) {
                    containerView.setOnTouchListener(null)
                } else {
                    containerView.setOnTouchListener { _, _ -> false }
                }
                result.success(null)
            }
            "setViewportSize" -> {
                val width = (call.argument<Number>("width"))?.toInt() ?: 0
                val height = (call.argument<Number>("height"))?.toInt() ?: 0
                session.setViewportSize(width, height, isFullScreen)
                result.success(null)
            }
            "setEmbeddedTextScale" -> {
                val scale = (call.argument<Number>("scale"))?.toFloat() ?: 1f
                session.setEmbeddedTextScale(scale)
                applyEmbeddedTextScale()
                result.success(null)
            }
            "captureCurrentFrame" -> handleCaptureCurrentFrame(call, result)
            else -> {
                session.methodHandler.handleMethodCall(call, result)
            }
        }
    }

    /**
     * Handles fullscreen toggle natively by moving the player view between container and fullscreen dialog
     * This uses ONE PlayerView instead of creating multiple platform views
     */
    private fun handleFullscreenToggleNative(enteringFullScreen: Boolean) {
        // Don't handle fullscreen if already disposed
        if (isDisposed) {
            NpLog.d(TAG, "Ignoring fullscreen toggle - view is disposed")
            return
        }

        // Get activity from plugin (most reliable) or context
        val activity = NativeVideoPlayerPlugin.getActivity() ?: getActivity(context)
        if (activity == null) {
            NpLog.e(TAG, "Cannot get Activity, cannot handle fullscreen")
            return
        }

        NpLog.d(TAG, "Got activity: ${activity.javaClass.simpleName}")

        if (enteringFullScreen) {
            // Fullscreen shows the full display: lift the viewport quality cap
            session.clearViewportConstraints()
            enterFullscreenNative(activity)

            // Notify Flutter that fullscreen was entered
            session.eventHandler.sendEvent("fullscreenChange", mapOf("isFullscreen" to true))
        } else {
            exitFullscreenNative(activity)
            session.restoreViewportConstraints()

            // Notify Flutter that fullscreen was exited
            session.eventHandler.sendEvent("fullscreenChange", mapOf("isFullscreen" to false))
        }

        // Update internal state
        isFullScreen = enteringFullScreen

        // Update the fullscreen button icon to reflect the new state
        // Use a delay to ensure the view transition has completed
        playerView?.postDelayed({
            updateFullscreenButtonState(enteringFullScreen)
        }, 100)
    }

    /**
     * Gets the Activity from a Context, handling ContextWrapper cases
     */
    private fun getActivity(context: Context?): Activity? {
        if (context == null) {
            NpLog.e(TAG, "Context is null")
            return null
        }

        NpLog.d(TAG, "Context type: ${context.javaClass.name}")

        if (context is Activity) {
            NpLog.d(TAG, "Context is Activity")
            return context
        }

        if (context is android.content.ContextWrapper) {
            NpLog.d(TAG, "Context is ContextWrapper, unwrapping...")
            return getActivity(context.baseContext)
        }

        NpLog.e(TAG, "Context is neither Activity nor ContextWrapper")
        return null
    }

    /**
     * Enters fullscreen by removing the player view from the container and adding it to a fullscreen dialog
     */
    private fun enterFullscreenNative(activity: Activity) {
        NpLog.d(TAG, "Entering fullscreen natively")

        // Store original orientation
        originalOrientation = activity.requestedOrientation

        // Hide system UI on the activity window
        activity.window?.let { activityWindow ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val controller = WindowCompat.getInsetsController(activityWindow, activityWindow.decorView)
                controller.hide(WindowInsetsCompat.Type.systemBars())
                controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            } else {
                @Suppress("DEPRECATION")
                activityWindow.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    )
            }
        }

        // Remove player view from container (important: remove from parent first!)
        (videoContentView.parent as? ViewGroup)?.removeView(videoContentView)

        // Create fullscreen dialog with black background and no title bar
        fullscreenDialog = Dialog(activity, android.R.style.Theme_Black_NoTitleBar_Fullscreen).apply {
            setContentView(videoContentView)

            // Handle back button to exit fullscreen
            setOnKeyListener { _, keyCode, event ->
                if (keyCode == android.view.KeyEvent.KEYCODE_BACK && event.action == android.view.KeyEvent.ACTION_UP) {
                    // Trigger the fullscreen toggle to exit (it will handle state and events)
                    videoContentView.post {
                        handleFullscreenToggleNative(false)
                    }
                    true
                } else {
                    false
                }
            }

            // Handle dialog dismissal
            setOnDismissListener {
                // Ensure we exit fullscreen if dialog is dismissed
                if (isFullScreen) {
                    exitFullscreenNative(activity)
                    isFullScreen = false
                }
            }

            show()
        }

        // Set fullscreen mode on dialog window
        fullscreenDialog?.window?.let { window ->
            // Make dialog cover the entire screen including status bar and navigation bar
            window.setLayout(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT
            )

            // Draw over the status bar and navigation bar areas
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                window.attributes.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }

            // Set window flags to cover everything
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ API
                window.setDecorFitsSystemWindows(false)
                val controller = WindowCompat.getInsetsController(window, window.decorView)
                controller.hide(WindowInsetsCompat.Type.systemBars())
                controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    )
            }

            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }

        // Allow all orientations in fullscreen
        activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR

        NpLog.d(TAG, "Entered fullscreen natively")
    }

    /**
     * Exits fullscreen by removing the player view from the dialog and adding it back to the container
     */
    private fun exitFullscreenNative(activity: Activity) {
        NpLog.d(TAG, "Exiting fullscreen natively")

        fullscreenDialog?.let { dialog ->
            // Remove player view from dialog
            (videoContentView.parent as? ViewGroup)?.removeView(videoContentView)

            // Dismiss dialog
            dialog.dismiss()
            fullscreenDialog = null
        }

        // Add player view back to container
        if (videoContentView.parent == null) {
            containerView.addView(videoContentView, contentLayoutParams())
        }

        // Force the display view to reattach its surface to the player
        // This is necessary because moving the view between parents can disconnect the surface
        videoContentView.post { rebindVideoOutput() }

        // Restore system UI on the activity window
        activity.window?.let { activityWindow ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val controller = WindowCompat.getInsetsController(activityWindow, activityWindow.decorView)
                controller.show(WindowInsetsCompat.Type.systemBars())
            } else {
                @Suppress("DEPRECATION")
                activityWindow.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
            }
        }

        // Restore original orientation
        activity.requestedOrientation = originalOrientation

        NpLog.d(TAG, "Exited fullscreen natively")
    }

    /**
     * Updates the fullscreen button icon to match the current fullscreen state
     * This is needed when fullscreen is toggled from Flutter rather than from the button itself
     */
    private fun updateFullscreenButtonState(isFullscreen: Boolean) {
        val playerView = playerView ?: return
        try {
            // Access the fullscreen button using reflection
            // The button is part of the PlayerView's controller
            val fullscreenButton = playerView.findViewById<android.widget.ImageButton>(
                androidx.media3.ui.R.id.exo_fullscreen
            )
            
            if (fullscreenButton != null) {
                NpLog.d(TAG, "Fullscreen button found, current selected state: ${fullscreenButton.isSelected}, setting to: $isFullscreen")
                
                // Try multiple approaches to update the button icon
                
                // Approach 1: Update selected state
                fullscreenButton.isSelected = isFullscreen
                fullscreenButton.refreshDrawableState()
                
                // Approach 2: Update content description (helps with accessibility)
                fullscreenButton.contentDescription = if (isFullscreen) "Exit fullscreen" else "Enter fullscreen"
                
                // Approach 3: Directly set the image resource based on fullscreen state
                // ExoPlayer uses exo_icon_fullscreen_enter and exo_icon_fullscreen_exit
                try {
                    val iconResourceId = if (isFullscreen) {
                        androidx.media3.ui.R.drawable.exo_icon_fullscreen_exit
                    } else {
                        androidx.media3.ui.R.drawable.exo_icon_fullscreen_enter
                    }
                    fullscreenButton.setImageResource(iconResourceId)
                    NpLog.d(TAG, "Set fullscreen button icon directly to: ${if (isFullscreen) "exit" else "enter"}")
                } catch (e: Exception) {
                    NpLog.w(TAG, "Could not set fullscreen button icon directly: ${e.message}")
                }
                
                // Force redraw
                fullscreenButton.invalidate()
                
                NpLog.d(TAG, "Fullscreen button state updated successfully (new selected=${fullscreenButton.isSelected})")
            } else {
                NpLog.w(TAG, "Fullscreen button not found in PlayerView")
            }
        } catch (e: Exception) {
            NpLog.e(TAG, "Error updating fullscreen button state: ${e.message}", e)
        }
    }

    // PiP is now handled by the floating package on the Dart side
    // All PiP-related methods have been removed

    /**
     * Reconnects the player's surface to this view's display surface
     * This is called when another platform view using the same shared player is disposed
     */
    private fun reconnectSurface() {
        if (isDisposed) {
            NpLog.d(TAG, "Ignoring surface reconnect - view is disposed")
            return
        }
        if (!needsSurfaceRebind && videoOutputBound && isDisplaySurfaceValid()) {
            // Already bound and healthy — rebinding here would only churn the
            // MediaCodec surface generation and freeze the last frame.
            NpLog.d(TAG, "Surface already connected for view $viewId - skipping rebind")
            return
        }

        NpLog.d(TAG, "Reconnecting surface for view $viewId")
        needsSurfaceRebind = false
        videoContentView.post { rebindVideoOutput() }
    }

    /** Whether this view's display surface currently has a live buffer queue. */
    private fun isDisplaySurfaceValid(): Boolean {
        lightTextureView?.let { return it.isAvailable }
        val surfaceView = lightSurfaceView ?: return true
        return surfaceView.holder.surface?.isValid == true
    }

    /**
     * Detaches and reattaches the player's video output so the surface
     * reconnects, whichever display path is active.
     */
    private fun rebindVideoOutput() {
        val playerView = playerView
        if (playerView != null) {
            val currentPlayer = playerView.player
            if (currentPlayer != null) {
                playerView.player = null
                playerView.player = currentPlayer
                NpLog.d(TAG, "Surface reconnected (PlayerView) for view $viewId")
            } else {
                NpLog.w(TAG, "Cannot reconnect surface - player is null")
            }
        } else {
            // A rebind renegotiates the buffer queue; cover the surface until
            // the player renders into it again.
            val textureView = lightTextureView
            if (textureView != null) {
                lightShutterView?.visibility = View.VISIBLE
                player.clearVideoTextureView(textureView)
                player.setVideoTextureView(textureView)
                videoOutputBound = true
                NpLog.d(TAG, "Surface reconnected (TextureView) for view $viewId")
                return
            }
            val surfaceView = lightSurfaceView ?: return
            lightShutterView?.visibility = View.VISIBLE
            player.clearVideoSurfaceView(surfaceView)
            player.setVideoSurfaceView(surfaceView)
            videoOutputBound = true
            NpLog.d(TAG, "Surface reconnected (SurfaceView) for view $viewId")
        }
    }

    /**
     * Updates the lightweight top-crop frame's video aspect (same role as
     * PlayerView's internal AspectRatioFrameLayout in the heavy path).
     */
    private fun applyLightAspectRatio(
        frame: TopCropAspectFrameLayout,
        videoSize: VideoSize,
        surfaceView: SurfaceView?
    ) {
        if (videoSize.width == 0 || videoSize.height == 0) return
        frame.setAspectRatio(videoSize.width * videoSize.pixelWidthHeightRatio / videoSize.height)
        // Pin the buffer geometry to the stream. Without this the surface
        // renegotiates its buffers every time the feed scroll resizes the
        // platform view, and each renegotiation is a window where a stale
        // slot can be presented. SurfaceFlinger scales the fixed-size buffer
        // to whatever bounds the view ends up with.
        //
        // No TextureView equivalent: SurfaceTexture.setDefaultBufferSize is
        // documented to be overridden by video producers, so it cannot pin
        // anything — it only nudges the BufferQueue's default until MediaCodec
        // dequeues again, and that window renders the coded frame's padding as
        // a green strip. MediaCodec already drives the geometry there via the
        // crop transform matrix.
        surfaceView?.holder?.setFixedSize(videoSize.width, videoSize.height)
    }

    /** MATCH_PARENT + TOP so cover-crop prefers the upper frame (faces). */
    private fun contentLayoutParams(): FrameLayout.LayoutParams {
        return FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
            Gravity.TOP or Gravity.CENTER_HORIZONTAL
        )
    }

    /**
     * Applies the session's embedded-caption text scale to both display
     * paths' SubtitleViews (issue #43). Scales relative to the user's system
     * caption preference, so 1.0 keeps the platform-default size — identical
     * to setUserDefaultTextSize().
     */
    private fun applyEmbeddedTextScale() {
        val scale = session.embeddedTextScale
        for (subtitleView in listOfNotNull(lightSubtitleView, playerView?.subtitleView)) {
            if (scale == 1f) {
                subtitleView.setUserDefaultTextSize()
            } else {
                subtitleView.setFractionalTextSize(
                    SubtitleView.DEFAULT_TEXT_SIZE_FRACTION * userCaptionFontScale() * scale
                )
            }
        }
    }

    private fun userCaptionFontScale(): Float {
        val captioningManager =
            context.getSystemService(Context.CAPTIONING_SERVICE) as? CaptioningManager
        return if (captioningManager?.isEnabled == true) captioningManager.fontScale else 1f
    }

    /**
     * Reports the video's display size to Dart (same payload the texture path
     * emits), so the Flutter sidecar-subtitle overlay can letterbox-match its
     * captions to the video. Platform views handle crop/rotation natively, so
     * [rotationCorrection] is always 0.
     */
    private fun sendVideoSize(videoSize: VideoSize) {
        if (videoSize.width == 0 || videoSize.height == 0) return
        session.eventHandler.sendEvent(
            "videoSize",
            mapOf(
                "width" to (videoSize.width * videoSize.pixelWidthHeightRatio).toInt(),
                "height" to videoSize.height,
                "rotationCorrection" to 0
            )
        )
    }

    private fun handleCaptureCurrentFrame(call: MethodCall, result: MethodChannel.Result) {
        val maxWidth = call.argument<Int>("maxWidth") ?: 720

        // A TextureView renders into the view hierarchy, so its pixels are
        // readable directly — no PixelCopy, which routinely fails on a
        // SurfaceView under hybrid composition.
        val textureView = lightTextureView
        if (textureView != null && textureView.isAvailable) {
            // getBitmap is a synchronous GPU readback on the calling thread,
            // so ask for the downscaled size directly instead of copying the
            // full view and scaling afterwards.
            val bitmap = captureTextureViewBitmap(textureView, maxWidth)
            if (bitmap != null) {
                captureExecutor.execute {
                    val jpeg = try {
                        VideoFrameCapture.bitmapToJpeg(bitmap, maxWidth)
                    } finally {
                        bitmap.recycle()
                    }
                    if (jpeg != null && jpeg.isNotEmpty()) {
                        lastFrameJpeg = jpeg
                    }
                    mainHandler.post {
                        if (isDisposed) result.success(null)
                        else result.success(jpeg ?: lastFrameJpeg)
                    }
                }
                return
            }
            if (lastFrameJpeg != null) {
                result.success(lastFrameJpeg)
                return
            }
            captureViaRetrieverAsync(maxWidth, result)
            return
        }

        val surfaceView = lightSurfaceView ?: findSurfaceView(playerView)
        if (surfaceView == null || surfaceView.width <= 0 || surfaceView.height <= 0) {
            if (lastFrameJpeg != null) {
                result.success(lastFrameJpeg)
                return
            }
            captureViaRetrieverAsync(maxWidth, result)
            return
        }
        captureFromSurfaceView(
            surfaceView = surfaceView,
            maxWidth = maxWidth,
            attempt = 0,
            onDone = { jpeg ->
                if (jpeg != null && jpeg.isNotEmpty()) {
                    lastFrameJpeg = jpeg
                    result.success(jpeg)
                } else if (lastFrameJpeg != null) {
                    // PixelCopy often fails under Flutter Hybrid Composition.
                    result.success(lastFrameJpeg)
                } else {
                    captureViaRetrieverAsync(maxWidth, result)
                }
            },
        )
    }

    /**
     * Fallback when PixelCopy cannot read the SurfaceView (common with Flutter
     * Hybrid Composition). Uses the current media URI + playhead — works for
     * unsigned HLS; may miss exact frame by a keyframe.
     */
    private fun captureViaRetrieverAsync(maxWidth: Int, result: MethodChannel.Result) {
        val uri = player.currentMediaItem?.localConfiguration?.uri?.toString()
        val positionMs = player.currentPosition
        if (uri.isNullOrEmpty()) {
            result.success(null)
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

    private fun findSurfaceView(root: View?): SurfaceView? {
        if (root is SurfaceView) return root
        if (root is ViewGroup) {
            for (i in 0 until root.childCount) {
                findSurfaceView(root.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    /**
     * PixelCopy the SurfaceView. Retries once after a frame — OEM compositors
     * and Flutter hybrid views occasionally return ERROR_SOURCE_NO_DATA.
     */
    private fun captureFromSurfaceView(
        surfaceView: SurfaceView,
        maxWidth: Int,
        attempt: Int,
        onDone: (ByteArray?) -> Unit,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            onDone(null)
            return
        }
        val width = surfaceView.width
        val height = surfaceView.height
        if (width <= 0 || height <= 0) {
            onDone(null)
            return
        }
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            PixelCopy.request(
                surfaceView,
                bitmap,
                { copyResult ->
                    if (copyResult != PixelCopy.SUCCESS) {
                        bitmap.recycle()
                        if (attempt < 1) {
                            mainHandler.postDelayed({
                                if (isDisposed) {
                                    onDone(null)
                                    return@postDelayed
                                }
                                captureFromSurfaceView(
                                    surfaceView,
                                    maxWidth,
                                    attempt + 1,
                                    onDone,
                                )
                            }, 32L)
                        } else {
                            NpLog.d(
                                TAG,
                                "PixelCopy failed result=$copyResult, using lastFrameJpeg",
                            )
                            onDone(null)
                        }
                        return@request
                    }
                    val jpeg = bitmapToJpeg(bitmap, maxWidth)
                    bitmap.recycle()
                    onDone(jpeg)
                },
                mainHandler,
            )
        } catch (e: Exception) {
            bitmap.recycle()
            NpLog.d(TAG, "PixelCopy threw: ${e.message}")
            onDone(null)
        }
    }

    private fun bitmapToJpeg(source: Bitmap, maxWidth: Int): ByteArray? =
        VideoFrameCapture.bitmapToJpeg(source, maxWidth)

    /**
     * Reads the TextureView's pixels at no more than [maxWidth] across. The
     * caller owns the returned bitmap and must recycle it.
     */
    private fun captureTextureViewBitmap(textureView: TextureView, maxWidth: Int): Bitmap? {
        val width = textureView.width
        val height = textureView.height
        if (width <= 0 || height <= 0) return null
        val targetWidth = width.coerceAtMost(maxWidth)
        val targetHeight = (height.toFloat() * targetWidth / width).toInt().coerceAtLeast(1)
        return runCatching { textureView.getBitmap(targetWidth, targetHeight) }.getOrNull()
    }

    override fun dispose() {
        NpLog.d(TAG, "VideoPlayerView dispose for id: $viewId")

        // Mark as disposed to prevent any further events
        isDisposed = true
        // shutdown(), not shutdownNow(): a dropped capture task never posts
        // back, leaving the Dart side's MethodChannel reply pending forever.
        // Queued tasks see isDisposed and answer null.
        captureExecutor.shutdown()
        lastFrameJpeg = null

        // Remove this view from the plugin's static registry (otherwise the
        // map keeps a strong reference to every view ever created)
        NativeVideoPlayerPlugin.unregisterView(viewId)

        // Exit fullscreen if active
        if (isFullScreen) {
            val activity = getActivity(context)
            if (activity != null) {
                exitFullscreenNative(activity)
            }
        }

        // Dismiss fullscreen dialog if it exists
        fullscreenDialog?.dismiss()
        fullscreenDialog = null

        // Remove fullscreen button listener to prevent clicks during disposal
        playerView?.setFullscreenButtonClickListener(null)

        NpLog.d(TAG, "dispose() - controllerId: $controllerId")

        // Remove the light display path's own listener before the common dispose
        lightListener?.let { player.removeListener(it) }
        player.removeListener(videoSizeListener)

        session.disposeCommon(detachOutput = {
            // IMPORTANT: For shared players, detach the player from this view's display
            // surface to prevent disconnecting it. Another platform view may still be
            // using the player. If we don't detach here, disposing this view will
            // disconnect the player's surface, leaving other views without video frames.
            playerView?.player = null
            lightSurfaceView?.let { player.clearVideoSurfaceView(it) }
            lightTextureView?.let { player.clearVideoTextureView(it) }
            videoOutputBound = false
            NpLog.d(TAG, "Detached player from display surface to preserve it for other views")
        })
    }
}

/**
 * Cover-fills children to a video aspect ratio, aligned to the **top** edge
 * (crop excess from the bottom / sides). [AspectRatioFrameLayout] ZOOM always
 * center-crops, which frames faces poorly in a short collapsed player band.
 *
 * Cover only — Dart sizes the Platform View to the video's aspect (letterbox
 * for landscape, contain for the collapsed sheet band), so this view's bounds
 * already carry the intended shape. Letterboxing here too would double up.
 */
@UnstableApi
private class TopCropAspectFrameLayout(context: Context) : FrameLayout(context) {
    private var videoAspect = 0f

    init {
        setBackgroundColor(android.graphics.Color.BLACK)
    }

    fun setAspectRatio(ratio: Float) {
        if (ratio == videoAspect) return
        videoAspect = ratio
        requestLayout()
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        val vw = right - left
        val vh = bottom - top
        if (vw <= 0 || vh <= 0) return

        val aspect = videoAspect
        for (i in 0 until childCount) {
            val child = getChildAt(i) ?: continue
            if (aspect <= 0f) {
                child.layout(0, 0, vw, vh)
                continue
            }
            val viewAspect = vw.toFloat() / vh.toFloat()
            val cw: Int
            val ch: Int
            if (aspect < viewAspect) {
                // Video relatively taller — fill width, overflow below.
                cw = vw
                ch = (vw / aspect).toInt()
            } else {
                // Video relatively wider — fill height, crop sides.
                ch = vh
                cw = (vh * aspect).toInt()
            }
            val cl = (vw - cw) / 2
            child.layout(cl, 0, cl + cw, ch)
        }
    }
}

