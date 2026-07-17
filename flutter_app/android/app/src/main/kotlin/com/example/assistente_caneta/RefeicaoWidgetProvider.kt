package com.example.assistente_caneta

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * App Widget do Recorpo — pílula com ícone de câmera + rótulo "Refeição".
 * Ao ser tocado abre a MainActivity com URI `recorpo://scanner-refeicao`,
 * que o Dart intercepta em [HomeWidget.initiallyLaunchedFromHomeWidget]
 * e usa para navegar direto à CameraScannerScreen (Lote 9).
 */
class RefeicaoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.refeicao_widget)

            // Intent que abre a MainActivity carregando a URI de câmera.
            // Usamos HomeWidgetLaunchIntent (do package home_widget) para
            // o Dart poder ler a URI no bootstrap.
            val pendingIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("recorpo://scanner-refeicao")
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
