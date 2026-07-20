package br.com.recorpo.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Widget "Água" (Lote 18) — 3 áreas:
 *  · Área central: quantidade acumulada hoje (lida de shared_preferences
 *    escrito pelo Dart quando app sincroniza).
 *  · Botão +250ml e +500ml: incrementam via HomeWidgetBackgroundIntent
 *    → o package roda um isolate Dart em background que atualiza os
 *    contadores no shared_preferences e chama updateWidget() para
 *    forçar re-render.
 *  · Toque no valor central: abre o app (fallback caso o usuário queira
 *    ver o dashboard).
 */
class AguaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // shared_preferences do home_widget é acessível em modo MODE_PRIVATE
        // com nome "HomeWidgetPreferences" (padrão do package).
        val prefs: SharedPreferences =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val acumulado = prefs.getInt("agua_hoje_ml", 0)
        val meta = prefs.getInt("agua_meta_ml", 0)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.agua_widget)
            views.setTextViewText(
                R.id.agua_valor,
                if (meta > 0) "$acumulado / $meta ml" else "$acumulado ml"
            )

            // Toque na área central abre o app.
            views.setOnClickPendingIntent(
                R.id.agua_valor_wrapper,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("recorpo://home")
                )
            )

            // Botões +250 e +500: broadcast pro isolate Dart em background.
            views.setOnClickPendingIntent(
                R.id.btn_agua_250,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("recorpo://agua/add?ml=250")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_agua_500,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("recorpo://agua/add?ml=500")
                )
            )

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
