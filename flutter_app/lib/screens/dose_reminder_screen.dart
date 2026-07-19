import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';

/// Lote 30 — Tela de configuração do lembrete semanal da dose.
///
/// GLP-1 e análogos (semaglutida, tirzepatida) são semanais. Esquecer a
/// aplicação é o problema #1 de aderência. A tela deixa o usuário
/// escolher **um único dia da semana** e um horário; o
/// [NotificationService] então agenda dois alertas recorrentes: véspera
/// às 20h ("prepare a caneta") e no dia no horário escolhido.
class DoseReminderScreen extends StatefulWidget {
  final String? nomeMedicamento;

  const DoseReminderScreen({super.key, this.nomeMedicamento});

  @override
  State<DoseReminderScreen> createState() => _DoseReminderScreenState();
}

class _DoseReminderScreenState extends State<DoseReminderScreen> {
  bool _carregando = true;
  bool _salvando = false;

  bool _habilitado = false;
  int _weekday = DateTime.thursday; // padrão comum: quinta
  int _hora = 9;
  int _minuto = 0;

  static const _labels = <int, String>{
    DateTime.monday: 'Seg',
    DateTime.tuesday: 'Ter',
    DateTime.wednesday: 'Qua',
    DateTime.thursday: 'Qui',
    DateTime.friday: 'Sex',
    DateTime.saturday: 'Sáb',
    DateTime.sunday: 'Dom',
  };

  static const _labelsCompleto = <int, String>{
    DateTime.monday: 'segunda',
    DateTime.tuesday: 'terça',
    DateTime.wednesday: 'quarta',
    DateTime.thursday: 'quinta',
    DateTime.friday: 'sexta',
    DateTime.saturday: 'sábado',
    DateTime.sunday: 'domingo',
  };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _habilitado =
          prefs.getBool(ProfilePrefsKeys.doseReminderEnabled) ?? false;
      _weekday =
          prefs.getInt(ProfilePrefsKeys.doseReminderWeekday) ?? _weekday;
      _hora = prefs.getInt(ProfilePrefsKeys.doseReminderHour) ?? _hora;
      _minuto = prefs.getInt(ProfilePrefsKeys.doseReminderMinute) ?? _minuto;
      _carregando = false;
    });
  }

  Future<void> _escolherHorario() async {
    final escolhido = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hora, minute: _minuto),
      helpText: 'Que horas você costuma aplicar?',
    );
    if (escolhido != null) {
      setState(() {
        _hora = escolhido.hour;
        _minuto = escolhido.minute;
      });
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final auth = context.read<AuthService>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ProfilePrefsKeys.doseReminderEnabled, _habilitado);
    await prefs.setInt(ProfilePrefsKeys.doseReminderWeekday, _weekday);
    await prefs.setInt(ProfilePrefsKeys.doseReminderHour, _hora);
    await prefs.setInt(ProfilePrefsKeys.doseReminderMinute, _minuto);

    final notif = NotificationService();
    if (_habilitado) {
      await notif.pedirPermissao();
      await notif.agendarDoseSemanal(
        weekday: _weekday,
        hour: _hora,
        minute: _minuto,
        primeiroNome: (auth.nome ?? '').trim().split(' ').first,
        medicamento: widget.nomeMedicamento,
      );
    } else {
      await notif.cancelarDoseSemanal();
    }

    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_habilitado
            ? 'Lembrete ativado. Você receberá o alerta toda ${_labelsCompleto[_weekday]}.'
            : 'Lembrete desativado.'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final horaFormatada =
        '${_hora.toString().padLeft(2, '0')}:${_minuto.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Lembrete da dose')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RecorpoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(RecorpoSpacing.lg),
              decoration: BoxDecoration(
                gradient: RecorpoGradients.primary,
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusLg),
              ),
              child: const Row(
                children: [
                  Icon(Icons.vaccines, color: Colors.white, size: 32),
                  SizedBox(width: RecorpoSpacing.md),
                  Expanded(
                    child: Text(
                      'Nunca mais esqueça a aplicação semanal — o app te '
                      'avisa na véspera e no dia.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RecorpoSpacing.lg),

            // Toggle master.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _habilitado,
              onChanged: _salvando
                  ? null
                  : (v) => setState(() => _habilitado = v),
              title: const Text('Ativar lembrete semanal',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                _habilitado
                    ? 'Você receberá dois alertas: véspera às 20h e no dia no horário.'
                    : 'Nenhum alerta é enviado enquanto estiver desativado.',
                style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),

            if (_habilitado) ...[
              const Divider(height: RecorpoSpacing.xl),
              Text('Dia da semana',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.75))),
              const SizedBox(height: RecorpoSpacing.sm),
              Wrap(
                spacing: RecorpoSpacing.sm,
                runSpacing: RecorpoSpacing.sm,
                children: _labels.entries.map((e) {
                  final sel = _weekday == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: sel,
                    onSelected: _salvando
                        ? null
                        : (_) => setState(() => _weekday = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: RecorpoSpacing.lg),
              Text('Horário da aplicação',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.75))),
              const SizedBox(height: RecorpoSpacing.sm),
              InkWell(
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusSm),
                onTap: _salvando ? null : _escolherHorario,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: RecorpoSpacing.md,
                      vertical: RecorpoSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius:
                        BorderRadius.circular(RecorpoSpacing.radiusSm),
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: RecorpoSpacing.md),
                      Expanded(
                        child: Text(horaFormatada,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()])),
                      ),
                      TextButton(
                        onPressed: _salvando ? null : _escolherHorario,
                        child: const Text('Alterar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: RecorpoSpacing.lg),
              Container(
                padding: const EdgeInsets.all(RecorpoSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(RecorpoSpacing.radiusSm),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: RecorpoSpacing.sm),
                    Expanded(
                      child: Text(
                        'Você recebe dois alertas: às 20h da véspera (para '
                        'tirar a caneta da geladeira) e no dia da aplicação '
                        'no horário escolhido.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: scheme.onSurface.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: RecorpoSpacing.xl),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _habilitado ? 'Salvar lembrete' : 'Desativar lembrete',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
