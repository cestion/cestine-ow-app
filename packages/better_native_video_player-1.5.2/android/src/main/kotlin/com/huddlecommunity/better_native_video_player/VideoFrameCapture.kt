package com.huddlecommunity.better_native_video_player

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever

/**
 * Frame-grab helpers shared by both Android display backends.
 *
 * [VideoPlayerView] reads its display view directly — PixelCopy off a
 * SurfaceView, getBitmap off a TextureView — and falls back to the
 * retriever; [TextureVideoPlayer] has no Android View to copy from, so the
 * retriever is its only path.
 */
internal object VideoFrameCapture {

    private const val TAG = "VideoFrameCapture"

    /** Downscales to [maxWidth] (never upscales) and encodes as JPEG. */
    fun bitmapToJpeg(source: Bitmap, maxWidth: Int): ByteArray? {
        val scaled = if (source.width > maxWidth) {
            val targetHeight = (source.height.toFloat() * maxWidth / source.width).toInt()
            Bitmap.createScaledBitmap(source, maxWidth, targetHeight.coerceAtLeast(1), true)
        } else {
            source
        }
        return try {
            java.io.ByteArrayOutputStream().use { stream ->
                scaled.compress(Bitmap.CompressFormat.JPEG, 75, stream)
                stream.toByteArray()
            }
        } finally {
            if (scaled !== source && !scaled.isRecycled) scaled.recycle()
        }
    }

    /**
     * Decodes the frame nearest [positionMs] straight from [uri]. Blocking —
     * call on a background executor.
     *
     * Sends no auth headers, matching the existing platform-view fallback:
     * fine for unsigned HLS, and signed sources simply return null rather
     * than a wrong frame.
     */
    fun retrieveFrameJpeg(uri: String, positionMs: Long, maxWidth: Int): ByteArray? {
        if (uri.isEmpty()) return null
        var jpeg: ByteArray? = null
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(uri, HashMap())
            val bitmap = retriever.getFrameAtTime(
                positionMs * 1000L,
                MediaMetadataRetriever.OPTION_CLOSEST,
            )
            if (bitmap != null) {
                jpeg = bitmapToJpeg(bitmap, maxWidth)
                bitmap.recycle()
            }
        } catch (e: Exception) {
            NpLog.d(TAG, "MediaMetadataRetriever capture failed: ${e.message}")
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
        return jpeg
    }
}
