package dev.openmosh.openmosh

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Speech model files through the system DownloadManager: it keeps going in
 * the background and across network drops, shows a notification and outlives
 * the app. Files land in the app's external files dir (`voice_downloads/`),
 * which other apps may read on old Android versions, so the Dart side never
 * loads them from there: [adopt] hashes each one while copying it into private
 * storage and keeps the copy only when size and SHA-256 match.
 */
class ModelDownloads(private val context: Context) {
    private val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val hashing = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private fun base(): File {
        val dir = context.getExternalFilesDir(null) ?: error("no external files dir")
        return File(dir, "voice_downloads").canonicalFile
    }

    /** [f] resolved, refusing anything outside [root]. */
    private fun inside(root: File, f: File): File {
        val c = f.canonicalFile
        require(c.path.startsWith(root.path + File.separator)) { "path outside $root" }
        return c
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "dev.openmosh/downloads").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "enqueue" -> result.success(
                        enqueue(call.argument("url")!!, call.argument("path")!!, call.argument("title")!!),
                    )
                    "list" -> result.success(list())
                    "remove" -> {
                        val ids = call.argument<List<Number>>("ids")!!.map { it.toLong() }
                        if (ids.isNotEmpty()) manager.remove(*ids.toLongArray())
                        result.success(null)
                    }
                    "adopt" -> {
                        val path: String = call.argument("path")!!
                        val dest: String = call.argument("dest")!!
                        val sha: String = call.argument("sha256")!!
                        val size = call.argument<Number>("size")!!.toLong()
                        hashing.execute {
                            val ok = runCatching { adopt(path, dest, sha, size) }.getOrDefault(false)
                            main.post { result.success(ok) }
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("download", e.message, null)
            }
        }
    }

    private fun enqueue(url: String, path: String, title: String): Long {
        val uri = Uri.parse(url)
        require(uri.scheme == "https") { "https only" }
        val file = inside(base(), File(base(), path))
        file.delete() // A leftover would make DownloadManager pick another name.
        file.parentFile?.mkdirs()
        val request = DownloadManager.Request(uri)
            .setTitle(title)
            // The relative path travels with the row: COLUMN_LOCAL_URI stays
            // empty until the download thread has the response headers, so a
            // queued row could not be matched by its file.
            .setDescription(path)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            // The size was shown and confirmed before the tap.
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
            .setDestinationInExternalFilesDir(context, null, "voice_downloads/$path")
        return manager.enqueue(request)
    }

    private fun list(): List<Map<String, Any?>> {
        val root = base()
        val rows = mutableListOf<Map<String, Any?>>()
        manager.query(DownloadManager.Query()).use { c ->
            val id = c.getColumnIndexOrThrow(DownloadManager.COLUMN_ID)
            val desc = c.getColumnIndexOrThrow(DownloadManager.COLUMN_DESCRIPTION)
            val status = c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS)
            val got = c.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
            val total = c.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
            val reason = c.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)
            while (c.moveToNext()) {
                val rel = c.getString(desc) ?: continue
                // Not one of ours, or a path that would leave the staging dir.
                val file = runCatching { inside(root, File(root, rel)) }.getOrNull() ?: continue
                val path = file.path.removePrefix(root.path + File.separator)
                rows.add(
                    mapOf(
                        "id" to c.getLong(id),
                        "path" to path,
                        "status" to when (c.getInt(status)) {
                            DownloadManager.STATUS_PENDING -> "pending"
                            DownloadManager.STATUS_RUNNING -> "running"
                            DownloadManager.STATUS_PAUSED -> "paused"
                            DownloadManager.STATUS_SUCCESSFUL -> "done"
                            else -> "failed"
                        },
                        "received" to c.getLong(got),
                        "total" to c.getLong(total).takeIf { it >= 0 },
                        "reason" to c.getInt(reason),
                    ),
                )
            }
        }
        return rows
    }

    /** Streams the staging file into [dest] and the digest at once. */
    private fun adopt(path: String, dest: String, sha: String, size: Long): Boolean {
        val src = inside(base(), File(base(), path))
        val out = inside(File(context.filesDir, "voice_models").canonicalFile, File(dest))
        out.parentFile?.mkdirs()
        val digest = MessageDigest.getInstance("SHA-256")
        var copied = 0L
        try {
            src.inputStream().use { input ->
                out.outputStream().use { output ->
                    val buf = ByteArray(1 shl 20)
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        copied += n
                        if (copied > size) break
                        digest.update(buf, 0, n)
                        output.write(buf, 0, n)
                    }
                }
            }
            val hex = digest.digest().joinToString("") { "%02x".format(it) }
            if (copied == size && hex == sha) return true
        } catch (e: Exception) {
            // Falls through to the cleanup below.
        }
        out.delete()
        return false
    }
}
