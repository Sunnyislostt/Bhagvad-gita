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
                    val originalScript = call.argument<String>("originalScript")
                    val translationEnglish = call.argument<String>("translationEnglish")
                    val chapter = call.argument<Int>("chapter") ?: 0
                    val verseNumber = call.argument<Int>("verseNumber") ?: 0
                    val displayLanguage = sanitizeLanguage(
                        call.argument<String>("displayLanguage"),
                    )

                    if (originalScript.isNullOrBlank() || translationEnglish.isNullOrBlank()) {
                        result.error(
                            "INVALID_ARGS",
                            "Missing required verse data",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    saveVerseForWidget(
                        originalScript = originalScript,
                        translationEnglish = translationEnglish,
                        chapter = chapter,
                        verseNumber = verseNumber,
                        displayLanguage = displayLanguage,
                    )
                    VerseWidgetProvider.updateAll(this)
                    result.success(true)
                }

                "setWidgetLanguage" -> {
                    val displayLanguage = sanitizeLanguage(
                        call.argument<String>("displayLanguage"),
                    )
                    saveWidgetLanguage(displayLanguage)
                    VerseWidgetProvider.updateAll(this)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun sanitizeLanguage(rawLanguage: String?): String {
        return when (rawLanguage) {
            "sanskrit" -> "sanskrit"
            else -> "english"
        }
    }

    private fun saveVerseForWidget(
        originalScript: String,
        translationEnglish: String,
        chapter: Int,
        verseNumber: Int,
        displayLanguage: String,
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_HAS_DATA, true)
            .putString(KEY_ORIGINAL_SCRIPT, originalScript)
            .putString(KEY_TRANSLATION_ENGLISH, translationEnglish)
            .putInt(KEY_CHAPTER, chapter)
            .putInt(KEY_VERSE_NUMBER, verseNumber)
            .putString(KEY_DISPLAY_LANGUAGE, displayLanguage)
            .apply()
    }

    private fun saveWidgetLanguage(displayLanguage: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_DISPLAY_LANGUAGE, displayLanguage)
            .apply()
    }

    companion object {
        const val CHANNEL_NAME = "bhagvad_gita_app/widget"
        const val PREFS_NAME = "verse_widget_prefs"
        const val KEY_HAS_DATA = "has_data"
        const val KEY_ORIGINAL_SCRIPT = "original_script"
        const val KEY_TRANSLATION_ENGLISH = "translation_english"
        const val KEY_CHAPTER = "chapter"
        const val KEY_VERSE_NUMBER = "verse_number"
        const val KEY_DISPLAY_LANGUAGE = "display_language"
    }
}
