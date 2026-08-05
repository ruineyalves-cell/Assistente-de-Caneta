package br.com.recorpo.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Widget "Recorpo Hoje" (Bloco 1) — resumo do dia na tela inicial:
 * anéis (Proteína + Água) com Score no centro + linhas de Proteína, Água
 * e Streak + atalhos rápidos +250/+500 ml.
 *
 * PRIVACIDADE (LGPD): só exibe dados NÃO sensíveis (proteína, água, score,
 * streak). Peso e sintomas NUNCA aparecem aqui — o app-lock continua sendo
 * a única porta para esses dados.
 *
 * Os anéis são renderizados pelo app como PNG (RemoteViews não roda
 * Flutter); o caminho fica em "hoje_rings_img". Se a imagem ainda não
 * existe, o widget segue útil com os textos. Os botões +250/+500 reusam o
 * MESMO BroadcastReceiver/isolate seguro do widget de Água (recorpo://agua/add).
 */
class HojeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs: SharedPreferences =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val score = prefs.getString("hoje_score", "Recorpo") ?: "Recorpo"
        val prot = prefs.getString("hoje_prot", "") ?: ""
        val agua = prefs.getString("hoje_agua", "") ?: ""
        val streak = prefs.getString("hoje_streak", "") ?: ""
        val ringsPath = prefs.getString("hoje_rings_img", null)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.hoje_widget)
            views.setTextViewText(R.id.hoje_score, score)
            views.setTextViewText(R.id.hoje_prot, prot)
            views.setTextViewText(R.id.hoje_agua, agua)
            views.setTextViewText(R.id.hoje_streak, streak)

            if (!ringsPath.isNullOrEmpty()) {
                try {
                    val bmp = BitmapFactory.decodeFile(ringsPath)
                    if (bmp != null) views.setImageViewBitmap(R.id.hoje_rings, bmp)
                } catch (_: Exception) {
                    // Imagem indisponível/corrompida — mantém só os textos.
                }
            }

            // Toque na área de resumo abre o app (deep link recorpo://home).
            views.setOnClickPendingIntent(
                R.id.hoje_info,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("recorpo://home")
                )
            )

            // Botões de água — mesmo fluxo seguro do widget de Água.
            views.setOnClickPendingIntent(
                R.id.hoje_btn_250,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("recorpo://agua/add?ml=250")
                )
            )
            views.setOnClickPendingIntent(
                R.id.hoje_btn_500,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("recorpo://agua/add?ml=500")
                )
            )

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
