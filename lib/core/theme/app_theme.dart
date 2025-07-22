import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Advanced theme engine with futuristic designs and accessibility
class AppTheme {
  // Theme identifiers
  static const String neonNight = 'neon_night';
  static const String solarFlare = 'solar_flare';
  static const String cyberpunkSky = 'cyberpunk_sky';
  static const String synthwaveBlack = 'synthwave_black';
  static const String glassMorphic = 'glass_morphic';
  static const String neuMorphic = 'neu_morphic';
  static const String clayMorphic = 'clay_morphic';

  // Accessibility modes
  static const String highContrast = 'high_contrast';
  static const String dyslexiaFriendly = 'dyslexia_friendly';
  static const String colorBlindFriendly = 'color_blind_friendly';

  /// Get theme data by identifier
  static ThemeData getTheme(String themeId, {bool isDark = true, String? accessibilityMode}) {
    switch (themeId) {
      case neonNight:
        return _createNeonNightTheme(accessibilityMode);
      case solarFlare:
        return _createSolarFlareTheme(accessibilityMode);
      case cyberpunkSky:
        return _createCyberpunkSkyTheme(accessibilityMode);
      case synthwaveBlack:
        return _createSynthwaveBlackTheme(accessibilityMode);
      case glassMorphic:
        return _createGlassMorphicTheme(accessibilityMode);
      case neuMorphic:
        return _createNeuMorphicTheme(accessibilityMode);
      case clayMorphic:
        return _createClayMorphicTheme(accessibilityMode);
      default:
        return _createNeonNightTheme(accessibilityMode);
    }
  }

  /// Neon Night Theme - Electric blues and purples with neon accents
  static ThemeData _createNeonNightTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFF00D4FF);
    const secondaryColor = Color(0xFFFF0080);
    const backgroundColor = Color(0xFF0A0A0F);
    const surfaceColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF39FF14);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Solar Flare Theme - Warm oranges and yellows with energy
  static ThemeData _createSolarFlareTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFFFF6B35);
    const secondaryColor = Color(0xFFF7931E);
    const backgroundColor = Color(0xFF1A0F0A);
    const surfaceColor = Color(0xFF2E1A1A);
    const accentColor = Color(0xFFFFD700);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Cyberpunk Sky Theme - Electric teals and magentas
  static ThemeData _createCyberpunkSkyTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFF00FFFF);
    const secondaryColor = Color(0xFFFF00FF);
    const backgroundColor = Color(0xFF0F0A1A);
    const surfaceColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFFFFFF00);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Synthwave Black Theme - Deep purples with neon highlights
  static ThemeData _createSynthwaveBlackTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFF8A2BE2);
    const secondaryColor = Color(0xFFDA70D6);
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A0A1A);
    const accentColor = Color(0xFF00FFFF);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Glass Morphic Theme - Translucent surfaces with blur effects
  static ThemeData _createGlassMorphicTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFF4A90E2);
    const secondaryColor = Color(0xFF7ED321);
    const backgroundColor = Color(0xFF0F1419);
    const surfaceColor = Color(0x40FFFFFF);
    const accentColor = Color(0xFFBD10E0);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Neu Morphic Theme - Soft shadows and highlights
  static ThemeData _createNeuMorphicTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFF6C7CE0);
    const secondaryColor = Color(0xFF36CFC9);
    const backgroundColor = Color(0xFF1F1F1F);
    const surfaceColor = Color(0xFF2A2A2A);
    const accentColor = Color(0xFFFFAD1B);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Clay Morphic Theme - Soft, clay-like surfaces
  static ThemeData _createClayMorphicTheme(String? accessibilityMode) {
    const primaryColor = Color(0xFFE17055);
    const secondaryColor = Color(0xFF00B894);
    const backgroundColor = Color(0xFF2D3436);
    const surfaceColor = Color(0xFF636E72);
    const accentColor = Color(0xFFFDCB6E);

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFFF073A),
      tertiary: accentColor,
    );

    return _buildThemeData(colorScheme, accessibilityMode);
  }

  /// Build complete theme data with accessibility considerations
  static ThemeData _buildThemeData(ColorScheme colorScheme, String? accessibilityMode) {
    // Select appropriate font family based on accessibility mode
    TextTheme textTheme;
    switch (accessibilityMode) {
      case dyslexiaFriendly:
        textTheme = const TextTheme();
        break;
      case highContrast:
        textTheme = const TextTheme().apply(
          fontFamily: 'monospace',
        );
        break;
      default:
        textTheme = const TextTheme();
    }

    // Adjust colors for accessibility
    ColorScheme adjustedColorScheme = colorScheme;
    if (accessibilityMode == highContrast) {
      adjustedColorScheme = colorScheme.copyWith(
        primary: Colors.white,
        secondary: Colors.yellow,
        surface: Colors.black,
        background: Colors.black,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
      );
    } else if (accessibilityMode == colorBlindFriendly) {
      adjustedColorScheme = colorScheme.copyWith(
        primary: const Color(0xFF0173B2), // Blue
        secondary: const Color(0xFFDE8F05), // Orange
        tertiary: const Color(0xFF029E73), // Green
        error: const Color(0xFFCC78BC), // Pink
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: adjustedColorScheme,
      textTheme: textTheme.apply(
        bodyColor: adjustedColorScheme.onBackground,
        displayColor: adjustedColorScheme.onBackground,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: adjustedColorScheme.surface,
        foregroundColor: adjustedColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: adjustedColorScheme.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: adjustedColorScheme.surface,
        elevation: AppConstants.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        margin: const EdgeInsets.all(AppConstants.defaultMargin),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: adjustedColorScheme.primary,
          foregroundColor: adjustedColorScheme.onPrimary,
          elevation: AppConstants.defaultElevation,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: adjustedColorScheme.primary,
          side: BorderSide(color: adjustedColorScheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: adjustedColorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: adjustedColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: adjustedColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: adjustedColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: adjustedColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: adjustedColorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: adjustedColorScheme.onSurface.withOpacity(0.7),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: adjustedColorScheme.onSurface.withOpacity(0.5),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: adjustedColorScheme.surface,
        selectedItemColor: adjustedColorScheme.primary,
        unselectedItemColor: adjustedColorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: AppConstants.defaultElevation,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: adjustedColorScheme.primary,
        foregroundColor: adjustedColorScheme.onPrimary,
        elevation: AppConstants.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: adjustedColorScheme.surface,
        elevation: AppConstants.defaultElevation * 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: adjustedColorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: adjustedColorScheme.onSurface,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: adjustedColorScheme.surface,
        selectedColor: adjustedColorScheme.primary,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: adjustedColorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius / 2),
        ),
        elevation: AppConstants.defaultElevation / 2,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return adjustedColorScheme.primary;
          }
          return adjustedColorScheme.onSurface.withOpacity(0.5);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return adjustedColorScheme.primary.withOpacity(0.5);
          }
          return adjustedColorScheme.onSurface.withOpacity(0.2);
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: adjustedColorScheme.primary,
        inactiveTrackColor: adjustedColorScheme.primary.withOpacity(0.3),
        thumbColor: adjustedColorScheme.primary,
        overlayColor: adjustedColorScheme.primary.withOpacity(0.2),
        valueIndicatorColor: adjustedColorScheme.primary,
        valueIndicatorTextStyle: textTheme.bodySmall?.copyWith(
          color: adjustedColorScheme.onPrimary,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: adjustedColorScheme.primary,
        linearTrackColor: adjustedColorScheme.primary.withOpacity(0.3),
        circularTrackColor: adjustedColorScheme.primary.withOpacity(0.3),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: adjustedColorScheme.onSurface.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: adjustedColorScheme.surface,
        selectedTileColor: adjustedColorScheme.primary.withOpacity(0.1),
        iconColor: adjustedColorScheme.onSurface,
        textColor: adjustedColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.defaultPadding / 2,
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: adjustedColorScheme.primary,
        unselectedLabelColor: adjustedColorScheme.onSurface.withOpacity(0.6),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: adjustedColorScheme.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: adjustedColorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: adjustedColorScheme.onSurface,
        ),
        padding: const EdgeInsets.all(AppConstants.defaultPadding / 2),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: adjustedColorScheme.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: adjustedColorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppConstants.defaultElevation,
      ),
    );
  }

  /// Get available theme list
  static List<ThemeInfo> getAvailableThemes() {
    return [
      ThemeInfo(
        id: neonNight,
        name: 'Neon Night',
        description: 'Electric blues and purples with neon accents',
        primaryColor: const Color(0xFF00D4FF),
        secondaryColor: const Color(0xFFFF0080),
        preview: 'assets/themes/neon_night_preview.png',
      ),
      ThemeInfo(
        id: solarFlare,
        name: 'Solar Flare',
        description: 'Warm oranges and yellows with energy',
        primaryColor: const Color(0xFFFF6B35),
        secondaryColor: const Color(0xFFF7931E),
        preview: 'assets/themes/solar_flare_preview.png',
      ),
      ThemeInfo(
        id: cyberpunkSky,
        name: 'Cyberpunk Sky',
        description: 'Electric teals and magentas',
        primaryColor: const Color(0xFF00FFFF),
        secondaryColor: const Color(0xFFFF00FF),
        preview: 'assets/themes/cyberpunk_sky_preview.png',
      ),
      ThemeInfo(
        id: synthwaveBlack,
        name: 'Synthwave Black',
        description: 'Deep purples with neon highlights',
        primaryColor: const Color(0xFF8A2BE2),
        secondaryColor: const Color(0xFFDA70D6),
        preview: 'assets/themes/synthwave_black_preview.png',
      ),
      ThemeInfo(
        id: glassMorphic,
        name: 'Glass Morphic',
        description: 'Translucent surfaces with blur effects',
        primaryColor: const Color(0xFF4A90E2),
        secondaryColor: const Color(0xFF7ED321),
        preview: 'assets/themes/glass_morphic_preview.png',
      ),
      ThemeInfo(
        id: neuMorphic,
        name: 'Neu Morphic',
        description: 'Soft shadows and highlights',
        primaryColor: const Color(0xFF6C7CE0),
        secondaryColor: const Color(0xFF36CFC9),
        preview: 'assets/themes/neu_morphic_preview.png',
      ),
      ThemeInfo(
        id: clayMorphic,
        name: 'Clay Morphic',
        description: 'Soft, clay-like surfaces',
        primaryColor: const Color(0xFFE17055),
        secondaryColor: const Color(0xFF00B894),
        preview: 'assets/themes/clay_morphic_preview.png',
      ),
    ];
  }

  /// Get accessibility options
  static List<AccessibilityOption> getAccessibilityOptions() {
    return [
      AccessibilityOption(
        id: highContrast,
        name: 'High Contrast',
        description: 'Enhanced contrast for better visibility',
        icon: Icons.contrast,
      ),
      AccessibilityOption(
        id: dyslexiaFriendly,
        name: 'Dyslexia Friendly',
        description: 'OpenDyslexic font for easier reading',
        icon: Icons.text_fields,
      ),
      AccessibilityOption(
        id: colorBlindFriendly,
        name: 'Color Blind Friendly',
        description: 'Optimized colors for color vision deficiency',
        icon: Icons.palette,
      ),
    ];
  }
}

/// Theme information class
class ThemeInfo {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final String preview;

  const ThemeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.preview,
  });
}

/// Accessibility option class
class AccessibilityOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const AccessibilityOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
