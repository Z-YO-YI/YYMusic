package io.github.z_y_o_y_i.yymusic

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

/** Debug-only provider for the generated Phase 4D audio fixture. */
class NativeAudioPocProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String? =
        if (isFixtureUri(uri)) "audio/wav" else null

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r" || !isFixtureUri(uri)) {
            throw FileNotFoundException("Unavailable POC fixture")
        }
        val appContext = context ?: throw FileNotFoundException("Unavailable POC context")
        val fixture = File(appContext.cacheDir, FIXTURE_FILE_NAME)
        if (!fixture.isFile || fixture.length() <= WAV_HEADER_LENGTH) {
            throw FileNotFoundException("Unavailable POC fixture")
        }
        return ParcelFileDescriptor.open(fixture, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? =
        throw UnsupportedOperationException("Read-only POC provider")

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int =
        throw UnsupportedOperationException("Read-only POC provider")

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = throw UnsupportedOperationException("Read-only POC provider")

    private fun isFixtureUri(uri: Uri): Boolean {
        val expectedAuthority = "${context?.packageName}.native-audio-poc"
        return uri.scheme == "content" &&
            uri.authority == expectedAuthority &&
            uri.pathSegments == listOf(FIXTURE_URI_SEGMENT)
    }

    private companion object {
        const val FIXTURE_FILE_NAME = "native-audio-poc-content.wav"
        const val FIXTURE_URI_SEGMENT = "generated-tone.wav"
        const val WAV_HEADER_LENGTH = 44L
    }
}
