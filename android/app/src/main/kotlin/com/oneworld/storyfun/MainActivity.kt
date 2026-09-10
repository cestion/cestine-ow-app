package com.oneworld.storyfun

import android.content.Intent
import android.os.Build
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.CookieHandler
import java.net.HttpCookie
import java.net.URI
import java.text.DecimalFormatSymbols
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.oneworld.storyfun/cloudfront"
    private val NUMBER_FORMAT_CHANNEL = "com.oneworld.storyfun/number_format"
    private val VIDEO_FILE_PICKER_CHANNEL = "com.oneworld.storyfun/video_file_picker"
    private val DEVICE_CHANNEL = "com.oneworld.storyfun/device"
    private lateinit var videoFilePicker: NativeVideoFilePicker
    private val jvmCookieManager = java.net.CookieManager().also {
        CookieHandler.setDefault(it)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        videoFilePicker = NativeVideoFilePicker(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VIDEO_FILE_PICKER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickVideo" -> {
                    val source = call.argument<String>("source") ?: "files"
                    val maxBytes = call.argument<Number>("maxBytes")?.toLong() ?: 0L
                    if (maxBytes <= 0) {
                        result.error("invalid_args", "maxBytes must be positive", null)
                    } else {
                        videoFilePicker.pick(source, maxBytes, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NUMBER_FORMAT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSeparators" -> {
                    val symbols = DecimalFormatSymbols.getInstance(Locale.getDefault())
                    result.success(
                        mapOf(
                            "decimalSeparator" to symbols.decimalSeparator.toString(),
                            "groupingSeparator" to symbols.groupingSeparator.toString(),
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isEmulator" -> result.success(isEmulator())
                "setKeepScreenOn" -> {
                    val keepOn = call.arguments as? Boolean ?: false
                    runOnUiThread {
                        if (keepOn) {
                            window.addFlags(
                                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                            )
                        } else {
                            window.clearFlags(
                                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                            )
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyCookies" -> {
                        val policy = call.argument<String>("policy")
                        val signature = call.argument<String>("signature")
                        val keyPairId = call.argument<String>("keyPairId")
                        val expires = call.argument<Number>("expires")?.toLong()
                        val mediaUrl = call.argument<String>("mediaAccessUrl") ?: ""
                        if (policy == null || signature == null || keyPairId == null || mediaUrl.isEmpty()) {
                            result.error("invalid_args", "missing cookie fields", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val host = URI(mediaUrl).host ?: ""
                            val cookieDomain = if (host.contains(".")) {
                                val parts = host.split(".")
                                ".${parts.takeLast(2).joinToString(".")}"
                            } else host

                            val cookieManager = CookieManager.getInstance()
                            val expiresAttr = if (expires != null && expires > 0) {
                                val maxAge = Math.max(0L, expires - System.currentTimeMillis() / 1000)
                                "; max-age=$maxAge"
                            } else ""
                            val attrSuffix = "; path=/; domain=$cookieDomain; Secure; SameSite=None$expiresAttr"

                            cookieManager.setCookie("https://$host", "CloudFront-Policy=$policy$attrSuffix")
                            cookieManager.setCookie("https://$host", "CloudFront-Signature=$signature$attrSuffix")
                            cookieManager.setCookie("https://$host", "CloudFront-Key-Pair-Id=$keyPairId$attrSuffix")
                            cookieManager.flush()

                            // JVM cookies for ExoPlayer
                            val uri = URI("https://$host")
                            val policyCookie = HttpCookie("CloudFront-Policy", policy).apply {
                                path = "/"
                                domain = cookieDomain
                                secure = true
                            }
                            val signatureCookie = HttpCookie("CloudFront-Signature", signature).apply {
                                path = "/"
                                domain = cookieDomain
                                secure = true
                            }
                            val keyPairIdCookie = HttpCookie("CloudFront-Key-Pair-Id", keyPairId).apply {
                                path = "/"
                                domain = cookieDomain
                                secure = true
                            }
                            jvmCookieManager.cookieStore.add(uri, policyCookie)
                            jvmCookieManager.cookieStore.add(uri, signatureCookie)
                            jvmCookieManager.cookieStore.add(uri, keyPairIdCookie)

                            result.success(null)
                        } catch (e: Exception) {
                            result.error("cookie_error", e.message, null)
                        }
                    }
                    "clearCookies" -> {
                        val mediaUrl = call.argument<String>("mediaAccessUrl") ?: ""
                        if (mediaUrl.isEmpty()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        try {
                            val host = URI(mediaUrl).host ?: ""
                            val cookieManager = CookieManager.getInstance()
                            val expired = "; path=/; domain=.${host.split(".").takeLast(2).joinToString(".")}; expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure; SameSite=None"
                            listOf("CloudFront-Policy", "CloudFront-Signature", "CloudFront-Key-Pair-Id").forEach {
                                cookieManager.setCookie("https://$host", "$it=$expired")
                            }
                            cookieManager.flush()

                            val uri = URI("https://$host")
                            val store = jvmCookieManager.cookieStore
                            store.get(uri)
                                .filter {
                                    it.name == "CloudFront-Policy" ||
                                        it.name == "CloudFront-Signature" ||
                                        it.name == "CloudFront-Key-Pair-Id"
                                }
                                .forEach { store.remove(uri, it) }

                            result.success(null)
                        } catch (e: Exception) {
                            result.error("cookie_error", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Android emulator image (ranchu / goldfish). Its `c2.goldfish.*` decoders
     * recycle graphic buffers across streams without clearing them, so after a
     * resolution change the new frame only covers part of the buffer and the
     * rest still shows the previous video.
     */
    private fun isEmulator(): Boolean {
        val hardware = Build.HARDWARE.lowercase(Locale.ROOT)
        val product = Build.PRODUCT.lowercase(Locale.ROOT)
        val fingerprint = Build.FINGERPRINT.lowercase(Locale.ROOT)
        return hardware == "ranchu" ||
            hardware == "goldfish" ||
            hardware.startsWith("vbox") ||
            product.startsWith("sdk_gphone") ||
            product.startsWith("sdk_google") ||
            product == "google_sdk" ||
            product == "sdk" ||
            product == "emulator" ||
            fingerprint.startsWith("generic") ||
            fingerprint.contains("/sdk_gphone")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::videoFilePicker.isInitialized &&
            videoFilePicker.handleActivityResult(requestCode, resultCode, data)
        ) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}



dsadsadsa
dsadsadsadsadsadsa
