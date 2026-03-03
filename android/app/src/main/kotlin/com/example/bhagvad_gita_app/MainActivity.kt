package com.example.bhagvad_gita_app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setVerseForWidget" -> {
                    val chapter = call.argument<Int>("chapter")
                    val verseNumber = call.argument<Int>("verseNumber")
                    val translationEnglish = call.argument<String>("translationEnglish")

                    if (chapter == null || verseNumber == null || translationEnglish.isNullOrBlank()) {
                        result.error(
                            "INVALID_ARGS",
                            "Missing required verse data",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    saveVerseForWidget(
                        chapter = chapter,
                        verseNumber = verseNumber,
                        translationEnglish = translationEnglish,
                    )
                    VerseWidgetProvider.updateAll(this)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun saveVerseForWidget(
        chapter: Int,
        verseNumber: Int,
        translationEnglish: String,
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_HAS_DATA, true)
            .putInt(KEY_CHAPTER, chapter)
            .putInt(KEY_VERSE_NUMBER, verseNumber)
            .putString(KEY_TRANSLATION, translationEnglish)
            .apply()
    }

    companion object {
        const val CHANNEL_NAME = "bhagvad_gita_app/widget"
        const val PREFS_NAME = "verse_widget_prefs"
        const val KEY_HAS_DATA = "has_data"
        const val KEY_CHAPTER = "chapter"
        const val KEY_VERSE_NUMBER = "verse_number"
        const val KEY_TRANSLATION = "translation_english"
    }
}
