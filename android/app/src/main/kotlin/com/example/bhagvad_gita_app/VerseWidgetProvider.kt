package com.example.bhagvad_gita_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.TypedValue
import android.widget.RemoteViews
import org.json.JSONArray
import kotlin.random.Random

class VerseWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_RANDOMIZE_WIDGET) {
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            )
            val appWidgetManager = AppWidgetManager.getInstance(context)

            if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
                updateAll(context, forceRandom = true)
            } else {
                updateWidget(
                    context = context,
                    appWidgetManager = appWidgetManager,
                    appWidgetId = appWidgetId,
                    forceRandom = true,
                )
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        appWidgetIds.forEach { appWidgetId ->
            editor
                .remove(randomOriginalScriptKey(appWidgetId))
                .remove(randomEnglishTranslationKey(appWidgetId))
                .remove(randomChapterKey(appWidgetId))
                .remove(randomVerseNumberKey(appWidgetId))
        }
        editor.apply()
    }

    companion object {
        fun updateAll(context: Context, forceRandom: Boolean = false) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, VerseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            appWidgetIds.forEach { appWidgetId ->
                updateWidget(context, appWidgetManager, appWidgetId, forceRandom = forceRandom)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            forceRandom: Boolean = false,
        ) {
            val views = RemoteViews(context.packageName, R.layout.verse_widget)
            val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val hasData = prefs.getBoolean(MainActivity.KEY_HAS_DATA, false)
            val displayLanguage = prefs.getString(MainActivity.KEY_DISPLAY_LANGUAGE, "english") ?: "english"
            val widgetMode = prefs.getString(MainActivity.KEY_WIDGET_MODE, MainActivity.MODE_FIXED)
                ?: MainActivity.MODE_FIXED
            val isRandomMode = widgetMode == MainActivity.MODE_RANDOM

            if (isRandomMode) {
                val randomVerse = if (forceRandom) {
                    getRandomVerse(context)
                } else {
                    loadRandomVerseFromPrefs(prefs, appWidgetId) ?: getRandomVerse(context)
                }

                if (randomVerse != null) {
                    saveRandomVerseToPrefs(prefs, appWidgetId, randomVerse)
                    val verseText =
                        when (displayLanguage) {
                            "sanskrit" -> randomVerse.originalScript.ifBlank {
                                randomVerse.translationEnglish
                            }

                            else -> randomVerse.translationEnglish.ifBlank { randomVerse.originalScript }
                        }
                    views.setTextViewText(R.id.widget_verse, verseText)
                    views.setTextViewText(
                        R.id.widget_reference,
                        "Chapter ${randomVerse.chapter} - Verse ${randomVerse.verseNumber}",
                    )
                    views.setTextViewText(
                        R.id.widget_footer,
                        "Open app",
                    )
                    views.setTextViewTextSize(
                        R.id.widget_verse,
                        TypedValue.COMPLEX_UNIT_SP,
                        if (displayLanguage == "sanskrit") 16.5f else 14.5f,
                    )
                } else {
                    views.setTextViewText(
                        R.id.widget_verse,
                        "Unable to load verses for random mode.",
                    )
                    views.setTextViewText(
                        R.id.widget_reference,
                        "Random mode unavailable",
                    )
                    views.setTextViewText(
                        R.id.widget_footer,
                        "Open app to retry",
                    )
                    views.setTextViewTextSize(
                        R.id.widget_verse,
                        TypedValue.COMPLEX_UNIT_SP,
                        14f,
                    )
                }
            } else if (hasData) {
                val englishText = prefs.getString(MainActivity.KEY_TRANSLATION_ENGLISH, "") ?: ""
                val sanskritText = prefs.getString(MainActivity.KEY_ORIGINAL_SCRIPT, "") ?: ""
                val chapter = prefs.getInt(MainActivity.KEY_CHAPTER, 0)
                val verseNumber = prefs.getInt(MainActivity.KEY_VERSE_NUMBER, 0)
                val verseText =
                    when (displayLanguage) {
                        "sanskrit" -> sanskritText.ifBlank { englishText }
                        else -> englishText
                    }
                val referenceText =
                    if (chapter > 0 && verseNumber > 0) {
                        "Chapter $chapter - Verse $verseNumber"
                    } else {
                        "Pinned Verse"
                    }

                views.setTextViewText(R.id.widget_verse, verseText)
                views.setTextViewTextSize(
                    R.id.widget_verse,
                    TypedValue.COMPLEX_UNIT_SP,
                    if (displayLanguage == "sanskrit") 16.5f else 14.5f,
                )
                views.setTextViewText(R.id.widget_reference, referenceText)
                views.setTextViewText(R.id.widget_footer, "Open app")
            } else {
                views.setTextViewText(
                    R.id.widget_verse,
                    "Add widget first, then tap this card to choose a fixed verse.",
                )
                views.setTextViewText(
                    R.id.widget_reference,
                    "No verse selected",
                )
                views.setTextViewText(
                    R.id.widget_footer,
                    "Open app",
                )
                views.setTextViewTextSize(
                    R.id.widget_verse,
                    TypedValue.COMPLEX_UNIT_SP,
                    14f,
                )
            }

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntentFlags =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId + REQUEST_CODE_OPEN_APP_BASE,
                openAppIntent,
                pendingIntentFlags,
            )

            val rootPendingIntent =
                if (isRandomMode) {
                    val randomizeIntent = Intent(context, VerseWidgetProvider::class.java).apply {
                        action = ACTION_RANDOMIZE_WIDGET
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    PendingIntent.getBroadcast(
                        context,
                        appWidgetId + REQUEST_CODE_RANDOMIZE_BASE,
                        randomizeIntent,
                        pendingIntentFlags,
                    )
                } else {
                    val chooseIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra(MainActivity.EXTRA_WIDGET_ACTION, MainActivity.ACTION_PICK_VERSE)
                    }
                    PendingIntent.getActivity(
                        context,
                        appWidgetId + REQUEST_CODE_PICK_VERSE_BASE,
                        chooseIntent,
                        pendingIntentFlags,
                    )
                }

            views.setOnClickPendingIntent(R.id.widget_root, rootPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_footer, openAppPendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadRandomVerseFromPrefs(
            prefs: android.content.SharedPreferences,
            appWidgetId: Int,
        ): WidgetVerse? {
            val englishText = prefs.getString(randomEnglishTranslationKey(appWidgetId), null)
            val sanskritText = prefs.getString(randomOriginalScriptKey(appWidgetId), null)
            val chapter = prefs.getInt(randomChapterKey(appWidgetId), 0)
            val verseNumber = prefs.getInt(randomVerseNumberKey(appWidgetId), 0)

            if (englishText.isNullOrBlank() && sanskritText.isNullOrBlank()) {
                return null
            }

            return WidgetVerse(
                chapter = chapter,
                verseNumber = verseNumber,
                originalScript = sanskritText.orEmpty(),
                translationEnglish = englishText.orEmpty(),
            )
        }

        private fun saveRandomVerseToPrefs(
            prefs: android.content.SharedPreferences,
            appWidgetId: Int,
            verse: WidgetVerse,
        ) {
            prefs.edit()
                .putString(randomOriginalScriptKey(appWidgetId), verse.originalScript)
                .putString(randomEnglishTranslationKey(appWidgetId), verse.translationEnglish)
                .putInt(randomChapterKey(appWidgetId), verse.chapter)
                .putInt(randomVerseNumberKey(appWidgetId), verse.verseNumber)
                .apply()
        }

        private fun getRandomVerse(context: Context): WidgetVerse? {
            val verses = loadVerses(context)
            if (verses.isEmpty()) {
                return null
            }
            return verses[Random(System.currentTimeMillis()).nextInt(verses.size)]
        }

        private fun loadVerses(context: Context): List<WidgetVerse> {
            cachedVerses?.let { return it }
            return try {
                val jsonText = context.assets.open(VERSES_ASSET_PATH).bufferedReader().use { it.readText() }
                val jsonArray = JSONArray(jsonText)
                val verses = buildList {
                    for (index in 0 until jsonArray.length()) {
                        val item = jsonArray.optJSONObject(index) ?: continue
                        val chapter = item.optInt("chapter", 0)
                        val verseNumber = parseVerseNumber(item.opt("verse_number"))
                        val originalScript = item.optString("original_script", "")
                        val translationEnglish = item.optString("translation_english", "")

                        if (chapter <= 0 || verseNumber <= 0) {
                            continue
                        }
                        if (originalScript.isBlank() && translationEnglish.isBlank()) {
                            continue
                        }

                        add(
                            WidgetVerse(
                                chapter = chapter,
                                verseNumber = verseNumber,
                                originalScript = originalScript,
                                translationEnglish = translationEnglish,
                            ),
                        )
                    }
                }
                cachedVerses = verses
                verses
            } catch (_: Exception) {
                emptyList()
            }
        }

        private fun parseVerseNumber(rawValue: Any?): Int {
            return when (rawValue) {
                is Number -> rawValue.toInt()
                is String -> {
                    val firstNumber = rawValue
                        .split('-')
                        .firstOrNull()
                        ?.trim()
                        ?.toIntOrNull()
                    firstNumber ?: 0
                }

                else -> 0
            }
        }

        private fun randomOriginalScriptKey(appWidgetId: Int): String =
            "random_original_script_$appWidgetId"

        private fun randomEnglishTranslationKey(appWidgetId: Int): String =
            "random_translation_english_$appWidgetId"

        private fun randomChapterKey(appWidgetId: Int): String =
            "random_chapter_$appWidgetId"

        private fun randomVerseNumberKey(appWidgetId: Int): String =
            "random_verse_number_$appWidgetId"

        private data class WidgetVerse(
            val chapter: Int,
            val verseNumber: Int,
            val originalScript: String,
            val translationEnglish: String,
        )

        private const val VERSES_ASSET_PATH = "flutter_assets/assets/data/verses.json"
        private const val ACTION_RANDOMIZE_WIDGET =
            "com.example.bhagvad_gita_app.action.RANDOMIZE_WIDGET"
        private const val REQUEST_CODE_RANDOMIZE_BASE = 11000
        private const val REQUEST_CODE_PICK_VERSE_BASE = 12000
        private const val REQUEST_CODE_OPEN_APP_BASE = 13000

        private var cachedVerses: List<WidgetVerse>? = null
    }
}
