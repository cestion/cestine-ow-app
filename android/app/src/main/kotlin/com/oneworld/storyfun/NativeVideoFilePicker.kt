package com.oneworld.storyfun

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.StatFs
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Reads the selected URI metadata before creating an app-owned file copy.
 *
 * file_picker exposes a local path only after copying the entire URI into the
 * app cache. For a video above the product limit that means waiting for a copy
 * that will immediately be rejected. This picker rejects known oversize files
 * first and also enforces the limit while copying providers that omit SIZE.
 */
class NativeVideoFilePicker(private val activity: Activity) {
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingResult: MethodChannel.Result? = null
    private var maxBytes: Long = 0

    fun pick(source: String, maxBytes: Long, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("already_active", "A video picker request is already active", null)
            return
        }
        this.pendingResult = result
        this.maxBytes = maxBytes

        val intent = if (source == "gallery") {
            Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
                type = "video/*"
            }
        } else {
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "video/*"
            }
        }.apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        if (intent.resolveActivity(activity.packageManager) == null) {
            finishError("source_unavailable", "No application can select a video")
            return
        }
        activity.startActivityForResult(intent, REQUEST_CODE)
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            finishSuccess(mapOf("status" to "canceled"))
            return true
        }

        val uri = data.data!!
        val name = queryDisplayName(uri)
        val declaredSize = querySize(uri)
        if (declaredSize > maxBytes) {
            finishSuccess(mapOf("status" to "tooLarge", "sizeBytes" to declaredSize))
            return true
        }
        if (declaredSize > 0 && !hasCopySpace(declaredSize)) {
            finishError("insufficient_storage", "Not enough device storage to prepare this video")
            return true
        }

        executor.execute { copyAcceptedVideo(uri, name, declaredSize) }
        return true
    }

    private fun copyAcceptedVideo(uri: Uri, displayName: String, declaredSize: Long) {
        val outputDir = File(activity.cacheDir, "storyfun_video_picker/${UUID.randomUUID()}")
        val output = File(outputDir, safeFileName(displayName))
        try {
            outputDir.mkdirs()
            val input = activity.contentResolver.openInputStream(uri)
                ?: throw IOException("The selected video cannot be opened")
            var copied = 0L
            input.use { source ->
                FileOutputStream(output).use { target ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    while (true) {
                        val count = source.read(buffer)
                        if (count < 0) break
                        copied += count
                        if (copied > maxBytes) {
                            throw VideoTooLargeException(copied)
                        }
                        target.write(buffer, 0, count)
                    }
                    target.fd.sync()
                }
            }
            finishSuccess(
                mapOf(
                    "status" to "selected",
                    "path" to output.absolutePath,
                    "name" to displayName,
                    "sizeBytes" to if (declaredSize > 0) declaredSize else copied,
                ),
            )
        } catch (error: VideoTooLargeException) {
            output.delete()
            outputDir.delete()
            finishSuccess(mapOf("status" to "tooLarge", "sizeBytes" to error.bytes))
        } catch (error: SecurityException) {
            output.delete()
            outputDir.delete()
            finishError("permission_denied", error.message ?: "Video access was denied")
        } catch (error: Exception) {
            output.delete()
            outputDir.delete()
            val code = if (!hasCopySpace(MIN_FREE_BYTES)) "insufficient_storage" else "copy_failed"
            finishError(code, error.message ?: "Could not prepare the selected video")
        }
    }

    private fun queryDisplayName(uri: Uri): String {
        activity.contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) {
                    val value = cursor.getString(index)
                    if (!value.isNullOrBlank()) return value
                }
            }
        }
        return uri.lastPathSegment?.substringAfterLast('/')?.ifBlank { null } ?: "video.mp4"
    }

    private fun querySize(uri: Uri): Long {
        activity.contentResolver.query(
            uri,
            arrayOf(OpenableColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (index >= 0 && !cursor.isNull(index)) {
                    val size = cursor.getLong(index)
                    if (size > 0) return size
                }
            }
        }
        return try {
            activity.contentResolver.openAssetFileDescriptor(uri, "r")?.use { descriptor ->
                descriptor.length.takeIf { it > 0 } ?: 0
            } ?: 0
        } catch (_: Exception) {
            0
        }
    }

    private fun safeFileName(name: String): String {
        val basename = File(name).name.replace(Regex("[\\u0000-\\u001f]"), "_")
        return basename.ifBlank { "video.mp4" }
    }

    private fun hasCopySpace(requiredBytes: Long): Boolean {
        return try {
            val available = StatFs(activity.cacheDir.absolutePath).availableBytes
            available >= requiredBytes + COPY_HEADROOM_BYTES
        } catch (_: Exception) {
            true
        }
    }

    private fun finishSuccess(value: Map<String, Any>) {
        val result = pendingResult ?: return
        pendingResult = null
        activity.runOnUiThread { result.success(value) }
    }

    private fun finishError(code: String, message: String) {
        val result = pendingResult ?: return
        pendingResult = null
        activity.runOnUiThread { result.error(code, message, null) }
    }

    private class VideoTooLargeException(val bytes: Long) : IOException()

    companion object {
        private const val REQUEST_CODE = 0x5346
        private const val COPY_HEADROOM_BYTES = 64L * 1024 * 1024
        private const val MIN_FREE_BYTES = 16L * 1024 * 1024
        private const val DEFAULT_BUFFER_SIZE = 1024 * 1024
    }
}
