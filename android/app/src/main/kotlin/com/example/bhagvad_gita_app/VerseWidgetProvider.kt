package com.example.bhagvad_gita_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class VerseWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, VerseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            appWidgetIds.forEach { appWidgetId ->
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val views = RemoteViews(context.packageName, R.layout.verse_widget)
            val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val hasData = prefs.getBoolean(MainActivity.KEY_HAS_DATA, false)
            val displayLanguage = prefs.getString(MainActivity.KEY_DISPLAY_LANGUAGE, "english") ?: "english"

            views.setTextViewText(
                R.id.widget_title,
                "Bhagvad Gita",
            )
            views.setTextViewText(
                R.id.widget_language,
                when (displayLanguage) {
                    "sanskrit" -> "Sanskrit"
                    else -> "English"
                },
            )

            if (hasData) {
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
                        "Chapter $chapter, Verse $verseNumber"
                    } else {
                        "Pinned Verse"
                    }

                views.setTextViewText(
                    R.id.widget_verse,
                    verseText,
                )
                views.setTextViewText(
                    R.id.widget_reference,
                    referenceText,
                )
            } else {
                views.setTextViewText(
                    R.id.widget_verse,
                    "Open Settings in the app and choose a verse for this widget.",
                )
                views.setTextViewText(
                    R.id.widget_reference,
                    "No verse selected",
                )
            }

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntentFlags =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                pendingIntentFlags,
            )

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
