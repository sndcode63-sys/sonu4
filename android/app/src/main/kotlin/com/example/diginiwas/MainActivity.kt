package com.example.diginiwas

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.diginiwas/media_saver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImageToGallery" -> {
                    val bytes = call.argument<ByteArray>("imageBytes")
                    val filename = call.argument<String>("fileName") ?: "DigiNiwas_Card_${System.currentTimeMillis()}.png"
                    val albumName = call.argument<String>("albumName") ?: "DigiNiwas"

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_BYTES", "Image bytes are empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedUri = saveImage(bytes, filename, albumName)
                        if (savedUri != null) {
                            result.success(savedUri.toString())
                        } else {
                            result.error("SAVE_FAILED", "Failed to save image to gallery", null)
                        }
                    } catch (e: Exception) {
                        result.error("EXCEPTION", e.message, null)
                    }
                }
                "openImageInGallery" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(Uri.parse(uriString), "image/*")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun saveImage(bytes: ByteArray, filename: String, albumName: String): Uri? {
        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val imageCollection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + File.separator + albumName)
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }

            val uri = resolver.insert(imageCollection, contentValues) ?: return null

            try {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(bytes)
                    outputStream.flush()
                }

                contentValues.clear()
                contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)
                return uri
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
        } else {
            // Android 9 (Pie) and below: Write file directly to public Pictures directory and trigger MediaScanner
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val albumDir = File(picturesDir, albumName)
            if (!albumDir.exists()) {
                albumDir.mkdirs()
            }
            val targetFile = File(albumDir, filename)
            FileOutputStream(targetFile).use { fos ->
                fos.write(bytes)
                fos.flush()
            }

            // Also insert into MediaStore so it is immediately visible in Gallery
            val contentValues = ContentValues().apply {
                put(MediaStore.Images.Media.DATA, targetFile.absolutePath)
                put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)

            // Notify MediaScanner explicitly
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(targetFile.absolutePath),
                arrayOf("image/png"),
                null
            )
            return uri ?: Uri.fromFile(targetFile)
        }
    }
}
