import 'package:flutter/material.dart';

/// Lote 24 — Design tokens oficiais do Recorpo.
///
/// Fonte única de verdade. Não recriar cores/estilos inline nos widgets.
/// A escolha da paleta é fundamentada — cores por eixo baseadas em apps
/// que provaram converter (Samsung Health, Duolingo, Fitbit, Noom,
/// Headspace, MyFitnessPal), aterradas o suficiente para manter
/// credibilidade clínica.
class RecorpoColors {
  // ─── Identidade primária (mantida) ─────────────────────────────────
  /// Azul Clínico — CTAs, botões primários, logo.
  static const Color primary = Color(0xFF2B6CB0);
  static const Color primaryDark = Color(0xFF1E4E85);
  static const Color primaryLight = Color(0xFF4A90D9);

  // ─── Alerta e confirmação (semântico, não decorativo) ──────────────
  static const Color alertaClinico = Color(0xFFE53E3E);
  static const Color confirma = Color(0xFF48BB78);

  // ─── Cores por eixo do dashboard ───────────────────────────────────
  /// Refeição — laranja terra (Samsung Health / MyFitnessPal)
  static const Color eixoRefeicao = Color(0xFFE27D3F);
  static const Color eixoRefeicaoDark = Color(0xFFB35F28);

  /// Água — ciano hidratante (Fitbit)
  static const Color eixoAgua = Color(0xFF3DB5C6);
  static const Color eixoAguaDark = Color(0xFF287E8B);

  /// Peso / Corpo — verde-menta calmo (Noom)
  static const Color eixoPeso = Color(0xFF4FBFA8);
  static const Color eixoPesoDark = Color(0xFF2E8A78);

  /// Sintomas — coral acolhedor (não confunde com alerta clínico)
  static const Color eixoSintomas = Color(0xFFE76F51);
  static const Color eixoSintomasDark = Color(0xFFAB4E38);

  /// Streak / Consistência — âmbar (Duolingo)
  static const Color eixoStreak = Color(0xFFE9A03C);
  static const Color eixoStreakDark = Color(0xFFAF7625);

  /// Movimento — roxo suave (Headspace)
  static const Color eixoMovimento = Color(0xFF7C6BC7);
  static const Color eixoMovimentoDark = Color(0xFF554791);

  // ─── Backgrounds e superfícies ─────────────────────────────────────
  static const Color darkBg = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF131C2E);
  static const Color darkSurfaceElevated = Color(0xFF1A2540);

  static const Color lightBg = Color(0xFFF4F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF9FBFD);
}

/// Gradientes prontos por eixo — usados nos cards do dashboard.
class RecorpoGradients {
  static LinearGradient _grad(Color a, Color b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      );

  static final refeicao =
      _grad(RecorpoColors.eixoRefeicao, RecorpoColors.eixoRefeicaoDark);
  static final agua =
      _grad(RecorpoColors.eixoAgua, RecorpoColors.eixoAguaDark);
  static final peso =
      _grad(RecorpoColors.eixoPeso, RecorpoColors.eixoPesoDark);
  static final sintomas =
      _grad(RecorpoColors.eixoSintomas, RecorpoColors.eixoSintomasDark);
  static final streak =
      _grad(RecorpoColors.eixoStreak, RecorpoColors.eixoStreakDark);
  static final movimento =
      _grad(RecorpoColors.eixoMovimento, RecorpoColors.eixoMovimentoDark);
  static final primary =
      _grad(RecorpoColors.primaryLight, RecorpoColors.primary);
}

/// Tokens de espaçamento e raio — usar sempre em vez de literais.
class RecorpoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28; // cards de eixo estilo Samsung
}

/// Enum que mapeia eixo → cor/gradiente/emoji/ícone. Widgets consultam
/// isso; não hard-code por tela.
enum EixoRecorpo {
  refeicao,
  agua,
  peso,
  sintomas,
  streak,
  movimento,
  primary,
}

extension EixoRecorpoDados on EixoRecorpo {
  Color get cor {
    switch (this) {
      case EixoRecorpo.refeicao:
        return RecorpoColors.eixoRefeicao;
      case EixoRecorpo.agua:
        return RecorpoColors.eixoAgua;
      case EixoRecorpo.peso:
        return RecorpoColors.eixoPeso;
      case EixoRecorpo.sintomas:
        return RecorpoColors.eixoSintomas;
      case EixoRecorpo.streak:
        return RecorpoColors.eixoStreak;
      case EixoRecorpo.movimento:
        return RecorpoColors.eixoMovimento;
      case EixoRecorpo.primary:
        return RecorpoColors.primary;
    }
  }

  LinearGradient get gradiente {
    switch (this) {
      case EixoRecorpo.refeicao:
        return RecorpoGradients.refeicao;
      case EixoRecorpo.agua:
        return RecorpoGradients.agua;
      case EixoRecorpo.peso:
        return RecorpoGradients.peso;
      case EixoRecorpo.sintomas:
        return RecorpoGradients.sintomas;
      case EixoRecorpo.streak:
        return RecorpoGradients.streak;
      case EixoRecorpo.movimento:
        return RecorpoGradients.movimento;
      case EixoRecorpo.primary:
        return RecorpoGradients.primary;
    }
  }

  String get emoji {
    switch (this) {
      case EixoRecorpo.refeicao:
        return '🍊';
      case EixoRecorpo.agua:
        return '💧';
      case EixoRecorpo.peso:
        return '⚖️';
      case EixoRecorpo.sintomas:
        return '🩺';
      case EixoRecorpo.streak:
        return '🔥';
      case EixoRecorpo.movimento:
        return '🏃';
      case EixoRecorpo.primary:
        return '💊';
    }
  }

  IconData get icone {
    switch (this) {
      case EixoRecorpo.refeicao:
        return Icons.restaurant_outlined;
      case EixoRecorpo.agua:
        return Icons.water_drop_outlined;
      case EixoRecorpo.peso:
        return Icons.monitor_weight_outlined;
      case EixoRecorpo.sintomas:
        return Icons.medical_services_outlined;
      case EixoRecorpo.streak:
        return Icons.local_fire_department_outlined;
      case EixoRecorpo.movimento:
        return Icons.directions_run_outlined;
      case EixoRecorpo.primary:
        return Icons.vaccines_outlined;
    }
  }
}

/// Fábricas de ThemeData — chamadas em MyApp. Nunca instanciar direto.
class RecorpoTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: RecorpoColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: RecorpoColors.primary,
      surface: RecorpoColors.lightSurface,
    );
    return _construir(base, background: RecorpoColors.lightBg);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: RecorpoColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: RecorpoColors.primaryLight,
      surface: RecorpoColors.darkSurface,
    );
    return _construir(base, background: RecorpoColors.darkBg);
  }

  static ThemeData _construir(ColorScheme scheme, {required Color background}) {
    final ehDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ehDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ehDark
            ? RecorpoColors.darkSurface
            : RecorpoColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RecorpoColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: RecorpoSpacing.xl, vertical: RecorpoSpacing.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            ehDark ? RecorpoColors.darkSurfaceElevated : Colors.white,
        selectedColor: RecorpoColors.primary,
        labelStyle: TextStyle(
          color: ehDark ? Colors.white70 : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: ehDark ? Colors.white24 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
