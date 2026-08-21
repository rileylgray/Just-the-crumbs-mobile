package com.realgamesrealfun.justthecrumbs

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * Turns a share-sheet hand-off into the app's own deep link.
     *
     * The app_links plugin — which already carries `justthecrumbs://share/…`
     * through to Dart — deliberately ignores ACTION_SEND intents, so rather
     * than adding a second channel for shared text we rewrite the intent into
     * the VIEW intent the plugin does understand. `main.dart` picks the link
     * out of the query string from there.
     *
     * This has to happen *before* `super.onCreate`, which is where the Flutter
     * engine attaches its plugins and app_links reads the launch intent.
     */
    private fun rewriteShareIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_SEND) return
        val shared = sharedTextFrom(intent) ?: return
        intent.action = Intent.ACTION_VIEW
        intent.data = Uri.parse("justthecrumbs://import?text=" + Uri.encode(shared))
        intent.removeExtra(Intent.EXTRA_TEXT)
    }

    /**
     * The shared text, or null when the share carried none — in which case the
     * intent is left alone rather than rewritten into a link with nothing in it.
     *
     * EXTRA_TEXT is where a share sheet normally puts it, but some apps only
     * fill in the clip data, so that is checked too. Only `item.text` is read:
     * `coerceToText` would go and open a content provider on the main thread.
     */
    private fun sharedTextFrom(intent: Intent): String? {
        val extra = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!extra.isNullOrBlank()) return extra
        val clip = intent.clipData ?: return null
        for (i in 0 until clip.itemCount) {
            val text = clip.getItemAt(i).text?.toString()
            if (!text.isNullOrBlank()) return text
        }
        return null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        rewriteShareIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        rewriteShareIntent(intent)
        super.onNewIntent(intent)
    }
}
