package com.dorehami.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "dorehami/updater"
    private val maxBytes = 250L * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "downloadAndInstall") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                val sha = call.argument<String>("sha256")
                if (url == null || sha == null || !url.startsWith("https://")) {
                    result.error("bad_args", "آدرس یا هش نامعتبر است", null)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls()
                ) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success("need_permission")
                    return@setMethodCallHandler
                }
                thread {
                    try {
                        val file = download(url, sha)
                        runOnUiThread {
                            install(file)
                            result.success("started")
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("failed", e.message ?: "خطای نامشخص", null)
                        }
                    }
                }
            }
    }

    private fun download(url: String, expectedSha: String): File {
        val dir = File(cacheDir, "updates")
        dir.mkdirs()
        val file = File(dir, "dorehami-update.apk")
        if (file.exists()) file.delete()

        val conn = URL(url).openConnection() as HttpURLConnection
        conn.connectTimeout = 15000
        conn.readTimeout = 30000
        try {
            if (conn.responseCode != 200) {
                throw Exception("پاسخ سرور نامعتبر است (${conn.responseCode})")
            }
            val length = conn.contentLengthLong
            if (length <= 0 || length > maxBytes) {
                throw Exception("اندازه فایل نامعتبر است")
            }
            val digest = MessageDigest.getInstance("SHA-256")
            var total = 0L
            conn.inputStream.use { input ->
                file.outputStream().use { output ->
                    val buf = ByteArray(64 * 1024)
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        total += n
                        if (total > maxBytes) throw Exception("حجم فایل بیش از حد مجاز است")
                        digest.update(buf, 0, n)
                        output.write(buf, 0, n)
                    }
                }
            }
            val actual = digest.digest().joinToString("") { "%02x".format(it) }
            if (actual != expectedSha.lowercase()) {
                file.delete()
                throw Exception("هش فایل با مقدار اعلام‌شده مطابقت ندارد؛ نصب متوقف شد")
            }
            return file
        } finally {
            conn.disconnect()
        }
    }

    private fun install(file: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
