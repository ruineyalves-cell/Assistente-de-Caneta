import 'package:flutter/material.dart';

import '../services/health_connect_service.dart';
import '../utils/constants.dart';

/// Hub do Health Connect (Lote 11). Solicita autorização de leitura de
/// frequência cardíaca e calorias ativas do dia, e mostra os KPIs
/// agregados. Alvo primário: Galaxy Watch pareado com o S25.
class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({super.key});

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen> {
  final _hc = HealthConnectService();

  bool _carregando = true;
  bool _autorizado = false;
  HealthResumoDia _resumo = HealthResumoDia.vazio;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!_hc.suportado) {
      setState(() {
        _erro = 'Health Connect só é suportado no Android. Abra o app '
            'no seu S25 para conectar.';
        _carregando = false;
      });
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      _autorizado = await _hc.temAutorizacao();
      if (_autorizado) {
        _resumo = await _hc.resumoDeHoje();
      }
    } catch (e) {
      _erro = e.toString();
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _autorizar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final ok = await _hc.pedirAutorizacao();
      _autorizado = ok;
      if (ok) _resumo = await _hc.resumoDeHoje();
    } catch (e) {
      _erro = e.toString();
    }
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smartwatch (Health Connect)'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _bootstrap,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Explicacao(),
            const SizedBox(height: 16),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              _CaixaErro(mensagem: _erro!, onTentar: _bootstrap)
            else if (!_autorizado)
              _PedidoAutorizacao(onAutorizar: _autorizar)
            else
              _Kpis(resumo: _resumo),
          ],
        ),
      ),
    );
  }
}

class _Explicacao extends StatelessWidget {
  const _Explicacao();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.azulClinico.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.azulClinico.withValues(alpha: 0.3)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.watch_outlined,
                color: AppColors.azulClinico, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'A Recorpo lê a sua frequência cardíaca e as calorias '
                'ativas do dia direto do Health Connect. As permissões '
                'são concedidas na tela do próprio Health Connect e você '
                'pode revogá-las a qualquer momento por lá.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PedidoAutorizacao extends StatelessWidget {
  final VoidCallback onAutorizar;
  const _PedidoAutorizacao({required this.onAutorizar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_outline,
                size: 40, color: AppColors.azulClinico),
            const SizedBox(height: 10),
            const Text('Autorização necessária',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Para ler seus dados, precisamos que você libere o acesso a '
              'frequência cardíaca e calorias ativas no Health Connect.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAutorizar,
              icon: const Icon(Icons.link),
              label: const Text('Conectar Health Connect'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azulClinico,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  final HealthResumoDia resumo;
  const _Kpis({required this.resumo});

  @override
  Widget build(BuildContext context) {
    if (!resumo.temDados) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.grey),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sem amostras registradas hoje ainda. Use o relógio '
                  'durante o dia e volte aqui.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.favorite,
                        color: AppColors.vermelhoAlerta, size: 20),
                    SizedBox(width: 8),
                    Text('Frequência cardíaca (hoje)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                          valor:
                              resumo.bpmMedio == null ? '—' : '${resumo.bpmMedio}',
                          rotulo: 'BPM médio'),
                    ),
                    Expanded(
                      child: _Kpi(
                          valor:
                              resumo.bpmMax == null ? '—' : '${resumo.bpmMax}',
                          rotulo: 'BPM máximo'),
                    ),
                    Expanded(
                      child: _Kpi(
                          valor: '${resumo.amostrasBpm}',
                          rotulo: 'Amostras'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.local_fire_department,
                        color: AppColors.azulClinico, size: 20),
                    SizedBox(width: 8),
                    Text('Gasto ativo (hoje)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        valor: resumo.kcalAtivas == null
                            ? '—'
                            : resumo.kcalAtivas!.toStringAsFixed(0),
                        rotulo: 'kcal ativas',
                      ),
                    ),
                    Expanded(
                      child: _Kpi(
                          valor: '${resumo.amostrasKcal}',
                          rotulo: 'Amostras'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Lote 22 — Passos + peso do Health Connect (leitura real).
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.directions_walk,
                        color: AppColors.azulClinico, size: 20),
                    SizedBox(width: 8),
                    Text('Movimento e peso',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        valor: resumo.passos == null ? '—' : '${resumo.passos}',
                        rotulo: 'passos hoje',
                      ),
                    ),
                    Expanded(
                      child: _Kpi(
                        valor: resumo.pesoUltimoKg == null
                            ? '—'
                            : '${resumo.pesoUltimoKg!.toStringAsFixed(1)} kg',
                        rotulo: resumo.pesoUltimoEm == null
                            ? 'peso'
                            : 'peso (${_diasAtras(resumo.pesoUltimoEm!)})',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _diasAtras(DateTime d) {
    final dias = DateTime.now().difference(d).inDays;
    if (dias == 0) return 'hoje';
    if (dias == 1) return 'ontem';
    return '${dias}d atrás';
  }
}

class _Kpi extends StatelessWidget {
  final String valor;
  final String rotulo;
  const _Kpi({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(rotulo,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _CaixaErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentar;
  const _CaixaErro({required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off,
                size: 40, color: AppColors.vermelhoAlerta),
            const SizedBox(height: 10),
            Text('Não foi possível ler o Health Connect.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
