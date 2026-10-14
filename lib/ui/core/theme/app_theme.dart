import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spot_for_fun/ui/core/router/page_transitions.dart';

import 'app_colors.dart';

/// Single dark "urban" theme. Display / headline / titleLarge use Anton
/// (one weight, meant for UPPERCASE copy); everything else is Archivo.
class AppTheme {
  AppTheme._();

  static const _radius = 4.0;

  /// Anton for big titles. Anton ships a single weight, so never bold it.
  static TextStyle display(double size, {Color color = AppColors.bone}) =>
      GoogleFonts.anton(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0.4,
        color: color,
      );

  /// Archivo 800 in small caps-style tracking, for labels and buttons.
  static TextStyle label(double size, {Color color = AppColors.bone}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: color,
      );

  static ThemeData urban() {
    const scheme = ColorScheme.dark(
      primary: AppColors.tape,
      onPrimary: AppColors.asphalt,
      primaryContainer: Color(0xFF3A3220),
      onPrimaryContainer: AppColors.tape,
      secondary: AppColors.moss,
      onSecondary: AppColors.asphalt,
      secondaryContainer: Color(0xFF24301F),
      onSecondaryContainer: AppColors.moss,
      tertiary: AppColors.tape,
      onTertiary: AppColors.asphalt,
      surface: AppColors.asphalt,
      onSurface: AppColors.bone,
      onSurfaceVariant: AppColors.boneMuted,
      surfaceContainerLowest: AppColors.navBar,
      surfaceContainerLow: Color(0xFF161616),
      surfaceContainer: AppColors.concrete,
      surfaceContainerHigh: Color(0xFF222222),
      surfaceContainerHighest: AppColors.concreteHigh,
      outline: AppColors.lineStrong,
      outlineVariant: AppColors.line,
      error: AppColors.danger,
      onError: AppColors.asphalt,
      errorContainer: Color(0xFF3A1E18),
      onErrorContainer: Color(0xFFF4B4A6),
      inverseSurface: AppColors.bone,
      onInverseSurface: AppColors.asphalt,
    );

    final base = ThemeData(brightness: Brightness.dark).textTheme;
    final body = GoogleFonts.archivoTextTheme(
      base,
    ).apply(bodyColor: AppColors.bone, displayColor: AppColors.bone);
    final textTheme = body.copyWith(
      displayLarge: display(56),
      displayMedium: display(46),
      displaySmall: display(38),
      headlineLarge: display(34),
      headlineMedium: display(30),
      headlineSmall: display(26),
      titleLarge: display(22),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: label(14),
      labelMedium: label(12),
      labelSmall: label(11),
    );

    final square = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.asphalt,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
        },
      ),
      canvasColor: AppColors.asphalt,
      textTheme: textTheme,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.tape,
        selectionColor: Color(0x66F2C14E),
        selectionHandleColor: AppColors.tape,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.asphalt,
        foregroundColor: AppColors.bone,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: display(24),
      ),
      cardTheme: CardThemeData(
        color: AppColors.concrete,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.tape,
          foregroundColor: AppColors.asphalt,
          disabledBackgroundColor: AppColors.concreteHigh,
          disabledForegroundColor: AppColors.boneMuted,
          shape: square,
          textStyle: label(15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.bone,
          side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
          shape: square,
          textStyle: label(15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tape,
          shape: square,
          textStyle: GoogleFonts.archivo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.bone,
          shape: square,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.tape,
        foregroundColor: AppColors.asphalt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.concrete,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.archivo(
          color: AppColors.boneMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.archivo(
          color: AppColors.boneMuted,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.archivo(
          color: AppColors.tape,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.boneMuted,
        suffixIconColor: AppColors.boneMuted,
        border: inputBorder(AppColors.lineStrong),
        enabledBorder: inputBorder(AppColors.lineStrong),
        focusedBorder: inputBorder(AppColors.tape, 2),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 2),
        errorStyle: GoogleFonts.archivo(
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.tape,
        disabledColor: AppColors.concrete,
        side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
        checkmarkColor: AppColors.asphalt,
        labelStyle: label(12),
        secondaryLabelStyle: label(12, color: AppColors.asphalt),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.tape
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.asphalt
                : AppColors.bone,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.lineStrong, width: 1.5),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          textStyle: WidgetStatePropertyAll(label(12)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.tape, width: 4),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.bone,
        unselectedLabelColor: AppColors.boneMuted,
        labelStyle: label(13),
        unselectedLabelStyle: label(13),
        dividerColor: AppColors.line,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
        color: AppColors.line,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.bone,
        textColor: AppColors.bone,
        titleTextStyle: GoogleFonts.archivo(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.bone,
        ),
        subtitleTextStyle: GoogleFonts.archivo(
          fontSize: 13,
          color: AppColors.boneMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bone,
        contentTextStyle: GoogleFonts.archivo(
          color: AppColors.asphalt,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        actionTextColor: AppColors.asphalt,
        behavior: SnackBarBehavior.floating,
        shape: square,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.concrete,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.concrete,
        dragHandleColor: AppColors.lineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.concrete,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.line),
        ),
        titleTextStyle: display(24),
        contentTextStyle: GoogleFonts.archivo(
          fontSize: 15,
          color: AppColors.bone,
          height: 1.45,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.tape,
        linearTrackColor: AppColors.concreteHigh,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.asphalt
              : AppColors.boneMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.tape
              : AppColors.concreteHigh,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.lineStrong),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.tape
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.asphalt),
        side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
      ),
      radioTheme: const RadioThemeData(
        fillColor: WidgetStatePropertyAll(AppColors.tape),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.tape,
        inactiveTrackColor: AppColors.concreteHigh,
        thumbColor: AppColors.tape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => label(
            10,
            color: s.contains(WidgetState.selected)
                ? AppColors.tape
                : AppColors.boneMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.tape
                : AppColors.boneMuted,
          ),
        ),
      ),
    );
  }
}
