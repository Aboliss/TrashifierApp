package com.aboliss.trashifier

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.FileProvider
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

/**
 * Backup and sharing for the Flutter side, without third-party plugins:
 * Android's file picker (Storage Access Framework) to save and open backups,
 * the share sheet to send a schedule file, Google's code scanner to read a
 * schedule QR code, and links/files opened with Trashifier.
 *
 * Everything read here comes from outside the app; it is size-capped and
 * handed to Dart as text, where ScheduleCodec validates it.
 */
class TransferChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val main = Handler(Looper.getMainLooper())

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSaveContent: String? = null

    /** A link or file the app was opened with, until Dart asks for it. */
    private var initialIncoming: Map<String, String>? = null
    private var initialAsked = false

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveFile" -> saveFile(call, result)
            "openFile" -> openFile(result)
            "shareFile" -> shareFile(call, result)
            "scanQr" -> scanQr(result)
            "initialIncoming" -> {
                initialAsked = true
                result.success(initialIncoming)
                initialIncoming = null
            }
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Save and open (Storage Access Framework)
    // -------------------------------------------------------------------------

    private fun saveFile(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        val content = call.argument<String>("content")
        if (name == null || content == null) {
            result.error("bad_args", "name and content are required", null)
            return
        }
        if (!claim(result)) return
        pendingSaveContent = content
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = JSON
            putExtra(Intent.EXTRA_TITLE, name)
        }
        launch(intent, REQUEST_SAVE)
    }

    private fun openFile(result: MethodChannel.Result) {
        if (!claim(result)) return
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            // Chat apps often save JSON as plain text or octet-stream.
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(JSON, "text/plain", "application/octet-stream"))
        }
        launch(intent, REQUEST_OPEN)
    }

    /** One picker at a time; a second call while one is open fails. */
    private fun claim(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error("busy", "Another file picker is open", null)
            return false
        }
        pendingResult = result
        return true
    }

    private fun launch(intent: Intent, requestCode: Int) {
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (e: ActivityNotFoundException) {
            finish { it.error("unavailable", "No file picker on this device", null) }
        }
    }

    /** Returns true when [requestCode] was one of ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return false
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pendingSaveContent = null
            finish { it.success(null) }
            return true
        }
        if (requestCode == REQUEST_SAVE) {
            val content = pendingSaveContent ?: ""
            pendingSaveContent = null
            thread {
                try {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use {
                        it.write(content.toByteArray(Charsets.UTF_8))
                    } ?: throw IllegalStateException("No output stream")
                    finish { it.success(true) }
                } catch (e: Exception) {
                    Log.w(TAG, "Saving the backup failed", e)
                    finish { it.error("write_failed", e.message, null) }
                }
            }
        } else {
            thread {
                val text = readCapped(uri)
                finish {
                    if (text == null) it.error("read_failed", "Could not read the file", null)
                    else if (text.length > MAX_CHARS) it.error("too_large", "File too large", null)
                    else it.success(text)
                }
            }
        }
        return true
    }

    private fun finish(block: (MethodChannel.Result) -> Unit) {
        main.post {
            val result = pendingResult ?: return@post
            pendingResult = null
            block(result)
        }
    }

    /**
     * Reads at most [MAX_CHARS] + 1 characters, so an oversized file is
     * detected without loading all of it. Null when it can't be read.
     */
    private fun readCapped(uri: Uri): String? = try {
        activity.contentResolver.openInputStream(uri)?.use { input ->
            val reader = input.reader(Charsets.UTF_8)
            val buffer = CharArray(MAX_CHARS + 1)
            var read = 0
            while (read < buffer.size) {
                val n = reader.read(buffer, read, buffer.size - read)
                if (n < 0) break
                read += n
            }
            String(buffer, 0, read)
        }
    } catch (e: Exception) {
        Log.w(TAG, "Reading $uri failed", e)
        null
    }

    // -------------------------------------------------------------------------
    // Share sheet
    // -------------------------------------------------------------------------

    private fun shareFile(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        val content = call.argument<String>("content")
        val title = call.argument<String>("title") ?: ""
        if (name == null || content == null || name.contains('/')) {
            result.error("bad_args", "name and content are required", null)
            return
        }
        try {
            val dir = File(activity.cacheDir, SHARE_DIR).apply { mkdirs() }
            val file = File(dir, name)
            file.writeText(content, Charsets.UTF_8)
            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", file)
            val send = Intent(Intent.ACTION_SEND).apply {
                type = JSON
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, title)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(send, title).apply {
                // Trashifier accepts schedule files too; don't offer it here.
                putExtra(
                    Intent.EXTRA_EXCLUDE_COMPONENTS,
                    arrayOf(ComponentName(activity, activity::class.java)),
                )
            }
            activity.startActivity(chooser)
            result.success(null)
        } catch (e: Exception) {
            Log.w(TAG, "Sharing failed", e)
            result.error("share_failed", e.message, null)
        }
    }

    // -------------------------------------------------------------------------
    // QR scanner (Google Play services, no camera permission needed)
    // -------------------------------------------------------------------------

    private fun scanQr(result: MethodChannel.Result) {
        val options = GmsBarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
        val scanner = GmsBarcodeScanning.getClient(activity, options)
        // The scanner UI is a Play services module; it is requested at install
        // time (manifest meta-data), and here again in case that didn't happen.
        ModuleInstall.getClient(activity)
            .installModules(ModuleInstallRequest.newBuilder().addApi(scanner).build())
            .addOnSuccessListener {
                scanner.startScan()
                    .addOnSuccessListener { result.success(it.rawValue) }
                    .addOnCanceledListener { result.success(null) }
                    .addOnFailureListener {
                        Log.w(TAG, "QR scan failed", it)
                        result.error("unavailable", it.message, null)
                    }
            }
            .addOnFailureListener {
                // No Play services (or no network for the first download).
                Log.w(TAG, "Scanner module unavailable", it)
                result.error("unavailable", it.message, null)
            }
    }

    // -------------------------------------------------------------------------
    // Opened with Trashifier: trashifier://import links and shared files
    // -------------------------------------------------------------------------

    /** Handles an intent that started or reached the activity. */
    fun handleIntent(intent: Intent?, initial: Boolean) {
        intent ?: return
        val link = intent.data?.takeIf { it.scheme == LINK_SCHEME }
        if (link != null) {
            deliver(mapOf("kind" to "link", "value" to link.toString()), initial)
            return
        }
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> streamExtra(intent)
            else -> null
        }
        if (uri == null || uri.scheme != "content") return
        thread {
            val text = readCapped(uri)
            main.post {
                val incoming = when {
                    text == null -> mapOf("kind" to "error", "value" to "read_failed")
                    text.length > MAX_CHARS -> mapOf("kind" to "error", "value" to "too_large")
                    else -> mapOf("kind" to "file", "value" to text)
                }
                deliver(incoming, initial)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
        }

    private fun deliver(incoming: Map<String, String>, initial: Boolean) {
        if (initial && !initialAsked) {
            // Dart isn't listening yet; it asks via "initialIncoming".
            initialIncoming = incoming
        } else {
            channel.invokeMethod("incoming", incoming)
        }
    }

    companion object {
        const val CHANNEL = "com.trashifier_app/transfer"
        private const val TAG = "TrashifierTransfer"
        private const val JSON = "application/json"
        private const val LINK_SCHEME = "trashifier"
        private const val SHARE_DIR = "shared"
        private const val REQUEST_SAVE = 7301
        private const val REQUEST_OPEN = 7302

        /** Same cap as ScheduleCodec.maxFileChars. */
        private const val MAX_CHARS = 512 * 1024
    }
}
