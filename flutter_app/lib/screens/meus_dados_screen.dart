import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';

/// Lote 32.6 — "Meus dados" (LGPD).
///
/// Consolida os 3 direitos que o app precisa expor em UI:
///  1. Portabilidade (art. 18, V) — botão exportar JSON.
///  2. Transparência (art. 18, VII) — lista dos acessos aos dados.
///  3. Eliminação (art. 18, VI) — excluir conta com double-confirm.
///
/// Nenhuma delas é síncrona no backend — apenas o pedido dispara.
/// O painel é claro sobre isso para reduzir ansiedade do usuário.
class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  bool _carregandoAcessos = false;
  List<Map<String, dynamic>>? _acessos;
  bool _exportando = false;
  bool _excluindo = false;
  String? _erroAcessos;

  @override
  void initState() {
    super.initState();
    _carregarAcessos();
  }

  Future<void> _carregarAcessos() async {
    setState(() {
      _carregandoAcessos = true;
      _erroAcessos = null;
    });
    try {
      final auth = context.read<AuthService>();
      final lista = await auth.apiService.listarAcessosLgpd();
      if (!mounted) return;
      setState(() {
        _acessos = lista;
        _carregandoAcessos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroAcessos = e.toString();
        _carregandoAcessos = false;
      });
    }
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final auth = context.read<AuthService>();
      final dados = await auth.apiService.exportarDadosLgpd();
      final texto = const JsonEncoder.withIndent('  ').convert(dados);
      await Clipboard.setData(ClipboardData(text: texto));
      if (!mounted) return;
      final kb = (texto.length / 1024).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Seus dados ($kb KB) foram copiados. Cole em um bloco de notas ou email para salvar.'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _abrirFluxoExclusao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogoExclusaoConta(),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _excluindo = true);
    try {
      final auth = context.read<AuthService>();
      final resp = await auth.apiService.excluirContaLgpd();
      final efeito = resp['efeito'] as String? ?? 'Conta desativada.';
      await auth.logout();
      if (!mounted) return;
      // Navega até a raiz — o gate do MyApp vai levar pra Login.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(efeito),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _excluindo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao excluir: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus dados')),
      body: RefreshIndicator(
        onRefresh: _carregarAcessos,
        child: ListView(
          padding: const EdgeInsets.all(RecorpoSpacing.lg),
          children: [
            _Cabecalho(),
            const SizedBox(height: RecorpoSpacing.xl),
            _SecaoPortabilidade(
              exportando: _exportando,
              onExportar: _exportar,
            ),
            const SizedBox(height: RecorpoSpacing.xl),
            _SecaoAcessos(
              carregando: _carregandoAcessos,
              erro: _erroAcessos,
              acessos: _acessos,
              onTentarDeNovo: _carregarAcessos,
            ),
            const SizedBox(height: RecorpoSpacing.xl),
            _SecaoExcluir(
              excluindo: _excluindo,
              onExcluir: _abrirFluxoExclusao,
            ),
            const SizedBox(height: RecorpoSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: RecorpoColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        border: Border.all(
          color: RecorpoColors.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined,
              color: RecorpoColors.primary, size: 22),
          const SizedBox(width: RecorpoSpacing.md),
          Expanded(
            child: Text(
              'Seus dados são seus. Aqui você exporta, revê quem acessou e pode excluir tudo, conforme a LGPD.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoPortabilidade extends StatelessWidget {
  final bool exportando;
  final Future<void> Function() onExportar;
  const _SecaoPortabilidade({
    required this.exportando,
    required this.onExportar,
  });

  @override
  Widget build(BuildContext context) {
    return _CartaoBase(
      titulo: 'Portabilidade',
      subtitulo: 'LGPD art. 18, inciso V.',
      icone: Icons.download_outlined,
      corAcento: RecorpoColors.primary,
      corpo: const Text(
        'Exporta todos os dados que temos sobre você em formato JSON: '
        'seu cadastro, perfil clínico, registros diários, scores e '
        'consentimentos. O arquivo é copiado para a área de transferência — '
        'cole no email para si mesmo ou salve num bloco de notas.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
      acao: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: exportando ? null : onExportar,
          icon: exportando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.copy_all_outlined),
          label: Text(exportando ? 'Preparando…' : 'Exportar meus dados'),
        ),
      ),
    );
  }
}

class _SecaoAcessos extends StatelessWidget {
  final bool carregando;
  final String? erro;
  final List<Map<String, dynamic>>? acessos;
  final VoidCallback onTentarDeNovo;
  const _SecaoAcessos({
    required this.carregando,
    required this.erro,
    required this.acessos,
    required this.onTentarDeNovo,
  });

  static String _rotuloAcao(String? action) {
    switch (action) {
      case 'read':
        return 'Leitura';
      case 'update':
        return 'Atualização';
      case 'create':
        return 'Criação';
      case 'delete':
        return 'Exclusão';
      case 'export':
        return 'Exportação';
      default:
        return action ?? 'Ação';
    }
  }

  static String _rotuloRecurso(String? r) {
    if (r == null) return '';
    return r.replaceAll('_', ' ');
  }

  Widget _corpo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (erro != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Não conseguimos carregar o histórico agora.',
              style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onTentarDeNovo,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
      );
    }
    final lista = acessos ?? const [];
    if (lista.isEmpty) {
      return Text(
        'Nenhum acesso registrado ainda.',
        style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
      );
    }
    // Mostra até 20 primeiros; o backend pode devolver 500.
    final formatador = DateFormat("dd/MM/yyyy 'às' HH:mm");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in lista.take(20))
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: scheme.onSurface.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a['action'] == 'delete'
                        ? RecorpoColors.alertaClinico
                        : RecorpoColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_rotuloAcao(a['action'] as String?)} — ${_rotuloRecurso(a['resource'] as String?)}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatarLinha(a, formatador),
                        style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface
                                .withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (lista.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${lista.length - 20} acessos anteriores.',
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
      ],
    );
  }

  static String _formatarLinha(
      Map<String, dynamic> a, DateFormat formatador) {
    final quando = a['created_at'] as String?;
    String dataFmt = quando ?? '';
    try {
      if (quando != null) {
        dataFmt = formatador.format(DateTime.parse(quando).toLocal());
      }
    } catch (_) {}
    final ator = a['acessado_por'] as String?;
    final role = a['actor_role'] as String?;
    if (ator != null) return '$dataFmt · $ator (${role ?? 'usuário'})';
    if (role != null) return '$dataFmt · $role';
    return dataFmt;
  }

  @override
  Widget build(BuildContext context) {
    return _CartaoBase(
      titulo: 'Quem acessou seus dados',
      subtitulo: 'LGPD art. 18, inciso VII.',
      icone: Icons.history,
      corAcento: RecorpoColors.eixoStreak,
      corpo: _corpo(context),
    );
  }
}

class _SecaoExcluir extends StatelessWidget {
  final bool excluindo;
  final Future<void> Function() onExcluir;
  const _SecaoExcluir({required this.excluindo, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return _CartaoBase(
      titulo: 'Excluir minha conta',
      subtitulo: 'LGPD art. 18, inciso VI.',
      icone: Icons.delete_forever_outlined,
      corAcento: RecorpoColors.alertaClinico,
      corpo: const Text(
        'Sua conta é desativada imediatamente. Os dados sensíveis são '
        'eliminados definitivamente em até 30 dias e os backups expiram '
        'em ciclo de até 35 dias. Essa ação não pode ser desfeita.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
      acao: SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: excluindo ? null : onExcluir,
          icon: excluindo
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.warning_amber_rounded,
                  color: RecorpoColors.alertaClinico),
          label: Text(excluindo ? 'Enviando…' : 'Solicitar exclusão',
              style: TextStyle(color: RecorpoColors.alertaClinico)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: RecorpoColors.alertaClinico.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }
}

class _CartaoBase extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color corAcento;
  final Widget corpo;
  final Widget? acao;
  const _CartaoBase({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.corAcento,
    required this.corpo,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: corAcento.withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(RecorpoSpacing.radiusSm),
                ),
                child: Icon(icone, color: corAcento, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitulo,
                        style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          corpo,
          if (acao != null) ...[
            const SizedBox(height: 12),
            acao!,
          ],
        ],
      ),
    );
  }
}

/// Diálogo de duplo-confirm: aviso + campo pra digitar "EXCLUIR".
class _DialogoExclusaoConta extends StatefulWidget {
  const _DialogoExclusaoConta();

  @override
  State<_DialogoExclusaoConta> createState() => _DialogoExclusaoContaState();
}

class _DialogoExclusaoContaState extends State<_DialogoExclusaoConta> {
  final _controller = TextEditingController();
  bool _leuAviso = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digitouCorreto = _controller.text.trim().toUpperCase() == 'EXCLUIR';
    return AlertDialog(
      title: const Text('Excluir conta'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Você está prestes a desativar sua conta e agendar a '
              'exclusão definitiva de todos os seus dados em até 30 dias.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _leuAviso,
              onChanged: (v) => setState(() => _leuAviso = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Entendo que essa ação não pode ser desfeita.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Digite EXCLUIR para confirmar:',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'EXCLUIR',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_leuAviso && digitouCorreto)
              ? () => Navigator.of(context).pop(true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: RecorpoColors.alertaClinico,
          ),
          child: const Text('Excluir conta'),
        ),
      ],
    );
  }
}
