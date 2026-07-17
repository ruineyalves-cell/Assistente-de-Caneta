import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Item da navegação flutuante (Lote 14).
class FloatingNavItem {
  final IconData icone;
  final String rotulo;

  const FloatingNavItem({required this.icone, required this.rotulo});
}

/// Barra de navegação inferior estilo "pílula flutuante" — substitui o
/// BottomNavigationBar Material padrão.
///
/// Fica acima do conteúdo (o Scaffold usa `extendBody: true`), com
/// forma totalmente arredondada, sombra suave e destaque de pílula
/// azul clínico atrás do item selecionado.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ehEscuro = tema.brightness == Brightness.dark;
    final corSurface = ehEscuro
        ? tema.colorScheme.surfaceContainerHigh
        : Colors.white;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: corSurface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: ehEscuro ? 0.45 : 0.10),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _Item(
                    dados: items[i],
                    selecionado: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final FloatingNavItem dados;
  final bool selecionado;
  final VoidCallback onTap;

  const _Item({
    required this.dados,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corSelecionada = AppColors.azulClinico;
    final tema = Theme.of(context);
    final corInativa = tema.brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey.shade600;

    return Semantics(
      button: true,
      selected: selecionado,
      label: dados.rotulo,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selecionado
                  ? corSelecionada.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  dados.icone,
                  size: 20,
                  color: selecionado ? corSelecionada : corInativa,
                ),
                // Rótulo só aparece no item ativo — economiza espaço e
                // dá acento visual à pílula ativa.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: selecionado
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            dados.rotulo,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: corSelecionada,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
