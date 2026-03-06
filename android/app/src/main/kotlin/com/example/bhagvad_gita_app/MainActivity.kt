package com.example.bhagvad_gita_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var widgetChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cacheWidgetLaunchAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = cacheWidgetLaunchAction(intent)
        if (!action.isNullOrBlank() && ::widgetChannel.isInitialized) {
            widgetChannel.invokeMethod(
                "onWidgetLaunchAction",
                mapOf("action" to action),
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        )
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setVerseForWidget" -> {
                    val originalScript = call.argument<String>("originalScript")
                    val translationEnglish = call.argument<String>("translationEnglish")
                    val chapter = call.argument<Int>("chapter") ?: 0
                    val verseNumber = call.argument<Int>("verseNumber") ?: 0
                    val verseLabel = call.argument<String>("verseLabel").orEmpty()
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
                        verseLabel = verseLabel,
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

                "setWidgetMode" -> {
                    val mode = sanitizeWidgetMode(call.argument<String>("mode"))
                    saveWidgetMode(mode)
                    VerseWidgetProvider.updateAll(this)
                    result.success(true)
                }

                "setWidgetTheme" -> {
                    val themeMode = sanitizeThemeMode(call.argument<String>("themeMode"))
                    saveWidgetTheme(themeMode)
                    VerseWidgetProvider.updateAll(this)
                    result.success(true)
                }

                "consumeWidgetLaunchAction" -> {
                    result.success(consumeWidgetLaunchAction())
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

    private fun sanitizeWidgetMode(rawMode: String?): String {
        return when (rawMode) {
            "random" -> "random"
            else -> "fixed"
        }
    }

    private fun sanitizeThemeMode(rawThemeMode: String?): String {
        return when (rawThemeMode) {
            THEME_LIGHT -> THEME_LIGHT
            else -> THEME_DARK
        }
    }

    private fun saveVerseForWidget(
        originalScript: String,
        translationEnglish: String,
        chapter: Int,
        verseNumber: Int,
        verseLabel: String,
        displayLanguage: String,
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_HAS_DATA, true)
            .putString(KEY_ORIGINAL_SCRIPT, originalScript)
            .putString(KEY_TRANSLATION_ENGLISH, translationEnglish)
            .putInt(KEY_CHAPTER, chapter)
            .putInt(KEY_VERSE_NUMBER, verseNumber)
            .putString(KEY_VERSE_LABEL, verseLabel.ifBlank { verseNumber.toString() })
            .putString(KEY_DISPLAY_LANGUAGE, displayLanguage)
            .putString(KEY_WIDGET_MODE, MODE_FIXED)
            .apply()
    }

    private fun saveWidgetLanguage(displayLanguage: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_DISPLAY_LANGUAGE, displayLanguage)
            .apply()
    }

    private fun saveWidgetMode(mode: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_WIDGET_MODE, mode)
            .apply()
    }

    private fun saveWidgetTheme(themeMode: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_THEME_MODE, themeMode)
            .apply()
    }

    private fun cacheWidgetLaunchAction(intent: Intent?): String? {
        val action = intent?.getStringExtra(EXTRA_WIDGET_ACTION)?.trim().orEmpty()
        if (action.isBlank()) {
            return null
        }
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_PENDING_WIDGET_ACTION, action)
            .apply()
        return action
    }

    private fun consumeWidgetLaunchAction(): String? {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val action = prefs.getString(KEY_PENDING_WIDGET_ACTION, null)
        if (!action.isNullOrBlank()) {
            prefs.edit().remove(KEY_PENDING_WIDGET_ACTION).apply()
        }
        return action
    }

    companion object {
        const val CHANNEL_NAME = "bhagvad_gita_app/widget"
        const val PREFS_NAME = "verse_widget_prefs"
        const val KEY_HAS_DATA = "has_data"
        const val KEY_ORIGINAL_SCRIPT = "original_script"
        const val KEY_TRANSLATION_ENGLISH = "translation_english"
        const val KEY_CHAPTER = "chapter"
        const val KEY_VERSE_NUMBER = "verse_number"
        const val KEY_VERSE_LABEL = "verse_label"
        const val KEY_DISPLAY_LANGUAGE = "display_language"
        const val KEY_WIDGET_MODE = "widget_mode"
        const val KEY_THEME_MODE = "theme_mode"
        const val KEY_PENDING_WIDGET_ACTION = "pending_widget_action"

        const val MODE_FIXED = "fixed"
        const val MODE_RANDOM = "random"
        const val THEME_LIGHT = "light"
        const val THEME_DARK = "dark"

        const val EXTRA_WIDGET_ACTION = "extra_widget_action"
        const val ACTION_PICK_VERSE = "pick_verse"
    }
}
