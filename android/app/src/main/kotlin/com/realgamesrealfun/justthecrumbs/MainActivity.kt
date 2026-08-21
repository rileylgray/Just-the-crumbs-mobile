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
        val shared = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
        intent.action = Intent.ACTION_VIEW
        intent.data = Uri.parse("justthecrumbs://import?text=" + Uri.encode(shared))
        intent.removeExtra(Intent.EXTRA_TEXT)
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
