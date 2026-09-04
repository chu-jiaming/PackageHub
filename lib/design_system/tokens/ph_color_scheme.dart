import 'package:flutter/material.dart';

/// Semantic colors for PackageHub's Light and Dark modes.
///
/// Components should read this extension from the current theme instead of
/// depending on a static light-only color constant.
@immutable
class PHColorScheme extends ThemeExtension<PHColorScheme> {
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceSecondary;
  final Color bgElevated;
  final Color bgAccent;
  final Color bgAccentSubtle;
  final Color bgDisabled;
  final Color bgSuccessSubtle;
  final Color bgWarningSubtle;
  final Color bgDangerSubtle;
  final Color bgDanger;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color textAccent;
  final Color textSuccess;
  final Color textWarning;
  final Color textDanger;
  final Color textDisabled;

  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconAccent;
  final Color iconSuccess;
  final Color iconWarning;
  final Color iconDanger;
  final Color iconDisabled;
  final Color iconInverse;

  final Color borderDefault;
  final Color borderStrong;
  final Color borderAccent;
  final Color borderFocus;
  final Color separatorDefault;

  final Color courierCainiao;
  final Color courierJd;
  final Color courierSf;
  final Color courierZto;
  final Color courierYto;
  final Color courierYunda;
  final Color courierJt;

  const PHColorScheme({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceSecondary,
    required this.bgElevated,
    required this.bgAccent,
    required this.bgAccentSubtle,
    required this.bgDisabled,
    required this.bgSuccessSubtle,
    required this.bgWarningSubtle,
    required this.bgDangerSubtle,
    required this.bgDanger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.textAccent,
    required this.textSuccess,
    required this.textWarning,
    required this.textDanger,
    required this.textDisabled,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconAccent,
    required this.iconSuccess,
    required this.iconWarning,
    required this.iconDanger,
    required this.iconDisabled,
    required this.iconInverse,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderAccent,
    required this.borderFocus,
    required this.separatorDefault,
    required this.courierCainiao,
    required this.courierJd,
    required this.courierSf,
    required this.courierZto,
    required this.courierYto,
    required this.courierYunda,
    required this.courierJt,
  });

  /// Figma Color collection, Light mode.
  static const light = PHColorScheme(
    bgCanvas: Color(0xFFF2F2F7),
    bgSurface: Color(0xFFFFFFFF),
    bgSurfaceSecondary: Color(0xFFF9F9FB),
    bgElevated: Color(0xFFFFFFFF),
    bgAccent: Color(0xFF0066CC),
    bgAccentSubtle: Color(0xFFEFF6FF),
    bgDisabled: Color(0xFFE5E5EA),
    bgSuccessSubtle: Color(0xFFEAF8EE),
    bgWarningSubtle: Color(0xFFFFF4E5),
    bgDangerSubtle: Color(0xFFFFF0EF),
    bgDanger: Color(0xFFFF3B30),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF636366),
    textTertiary: Color(0xFF8E8E93),
    textInverse: Color(0xFFFFFFFF),
    textAccent: Color(0xFF0066CC),
    textSuccess: Color(0xFF1B7F37),
    textWarning: Color(0xFFA05A00),
    textDanger: Color(0xFFC9342C),
    textDisabled: Color(0xFFC7C7CC),
    iconPrimary: Color(0xFF000000),
    iconSecondary: Color(0xFF636366),
    iconAccent: Color(0xFF007AFF),
    iconSuccess: Color(0xFF34C759),
    iconWarning: Color(0xFFFF9500),
    iconDanger: Color(0xFFFF3B30),
    iconDisabled: Color(0xFFC7C7CC),
    iconInverse: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFE5E5EA),
    borderStrong: Color(0xFFC7C7CC),
    borderAccent: Color(0xFF007AFF),
    borderFocus: Color(0xFF007AFF),
    separatorDefault: Color(0xFFE5E5EA),
    courierCainiao: Color(0xFFFF6A00),
    courierJd: Color(0xFFE2231A),
    courierSf: Color(0xFF111111),
    courierZto: Color(0xFF168AD8),
    courierYto: Color(0xFF0066B3),
    courierYunda: Color(0xFFE60012),
    courierJt: Color(0xFFD71920),
  );

  /// Figma Color collection, Dark mode.
  static const dark = PHColorScheme(
    bgCanvas: Color(0xFF000000),
    bgSurface: Color(0xFF1C1C1E),
    bgSurfaceSecondary: Color(0xFF2C2C2E),
    bgElevated: Color(0xFF2C2C2E),
    bgAccent: Color(0xFF0066CC),
    bgAccentSubtle: Color(0xFF092C4C),
    bgDisabled: Color(0xFF2C2C2E),
    bgSuccessSubtle: Color(0xFF103D1F),
    bgWarningSubtle: Color(0xFF4A2A00),
    bgDangerSubtle: Color(0xFF3A0F0D),
    bgDanger: Color(0xFFFF453A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC7C7CC),
    textTertiary: Color(0xFF8E8E93),
    textInverse: Color(0xFFFFFFFF),
    textAccent: Color(0xFF64B5F6),
    textSuccess: Color(0xFF30D158),
    textWarning: Color(0xFFFF9F0A),
    textDanger: Color(0xFFFF453A),
    textDisabled: Color(0xFF636366),
    iconPrimary: Color(0xFFFFFFFF),
    iconSecondary: Color(0xFFC7C7CC),
    iconAccent: Color(0xFF0A84FF),
    iconSuccess: Color(0xFF30D158),
    iconWarning: Color(0xFFFF9F0A),
    iconDanger: Color(0xFFFF453A),
    iconDisabled: Color(0xFF636366),
    iconInverse: Color(0xFFFFFFFF),
    borderDefault: Color(0xFF48484A),
    borderStrong: Color(0xFF636366),
    borderAccent: Color(0xFF0A84FF),
    borderFocus: Color(0xFF0A84FF),
    separatorDefault: Color(0xFF2C2C2E),
    courierCainiao: Color(0xFFFF6A00),
    courierJd: Color(0xFFE2231A),
    courierSf: Color(0xFFFFFFFF),
    courierZto: Color(0xFF168AD8),
    courierYto: Color(0xFF0066B3),
    courierYunda: Color(0xFFE60012),
    courierJt: Color(0xFFD71920),
  );

  static PHColorScheme of(BuildContext context) {
    return Theme.of(context).extension<PHColorScheme>() ?? light;
  }

  @override
  PHColorScheme copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceSecondary,
    Color? bgElevated,
    Color? bgAccent,
    Color? bgAccentSubtle,
    Color? bgDisabled,
    Color? bgSuccessSubtle,
    Color? bgWarningSubtle,
    Color? bgDangerSubtle,
    Color? bgDanger,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? textAccent,
    Color? textSuccess,
    Color? textWarning,
    Color? textDanger,
    Color? textDisabled,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? iconAccent,
    Color? iconSuccess,
    Color? iconWarning,
    Color? iconDanger,
    Color? iconDisabled,
    Color? iconInverse,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderAccent,
    Color? borderFocus,
    Color? separatorDefault,
    Color? courierCainiao,
    Color? courierJd,
    Color? courierSf,
    Color? courierZto,
    Color? courierYto,
    Color? courierYunda,
    Color? courierJt,
  }) {
    return PHColorScheme(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceSecondary: bgSurfaceSecondary ?? this.bgSurfaceSecondary,
      bgElevated: bgElevated ?? this.bgElevated,
      bgAccent: bgAccent ?? this.bgAccent,
      bgAccentSubtle: bgAccentSubtle ?? this.bgAccentSubtle,
      bgDisabled: bgDisabled ?? this.bgDisabled,
      bgSuccessSubtle: bgSuccessSubtle ?? this.bgSuccessSubtle,
      bgWarningSubtle: bgWarningSubtle ?? this.bgWarningSubtle,
      bgDangerSubtle: bgDangerSubtle ?? this.bgDangerSubtle,
      bgDanger: bgDanger ?? this.bgDanger,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      textAccent: textAccent ?? this.textAccent,
      textSuccess: textSuccess ?? this.textSuccess,
      textWarning: textWarning ?? this.textWarning,
      textDanger: textDanger ?? this.textDanger,
      textDisabled: textDisabled ?? this.textDisabled,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconAccent: iconAccent ?? this.iconAccent,
      iconSuccess: iconSuccess ?? this.iconSuccess,
      iconWarning: iconWarning ?? this.iconWarning,
      iconDanger: iconDanger ?? this.iconDanger,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      iconInverse: iconInverse ?? this.iconInverse,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderAccent: borderAccent ?? this.borderAccent,
      borderFocus: borderFocus ?? this.borderFocus,
      separatorDefault: separatorDefault ?? this.separatorDefault,
      courierCainiao: courierCainiao ?? this.courierCainiao,
      courierJd: courierJd ?? this.courierJd,
      courierSf: courierSf ?? this.courierSf,
      courierZto: courierZto ?? this.courierZto,
      courierYto: courierYto ?? this.courierYto,
      courierYunda: courierYunda ?? this.courierYunda,
      courierJt: courierJt ?? this.courierJt,
    );
  }

  @override
  PHColorScheme lerp(covariant PHColorScheme? other, double t) {
    if (other == null) return this;
    return PHColorScheme(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceSecondary: Color.lerp(
        bgSurfaceSecondary,
        other.bgSurfaceSecondary,
        t,
      )!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgAccent: Color.lerp(bgAccent, other.bgAccent, t)!,
      bgAccentSubtle: Color.lerp(bgAccentSubtle, other.bgAccentSubtle, t)!,
      bgDisabled: Color.lerp(bgDisabled, other.bgDisabled, t)!,
      bgSuccessSubtle: Color.lerp(bgSuccessSubtle, other.bgSuccessSubtle, t)!,
      bgWarningSubtle: Color.lerp(bgWarningSubtle, other.bgWarningSubtle, t)!,
      bgDangerSubtle: Color.lerp(bgDangerSubtle, other.bgDangerSubtle, t)!,
      bgDanger: Color.lerp(bgDanger, other.bgDanger, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      textSuccess: Color.lerp(textSuccess, other.textSuccess, t)!,
      textWarning: Color.lerp(textWarning, other.textWarning, t)!,
      textDanger: Color.lerp(textDanger, other.textDanger, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      iconAccent: Color.lerp(iconAccent, other.iconAccent, t)!,
      iconSuccess: Color.lerp(iconSuccess, other.iconSuccess, t)!,
      iconWarning: Color.lerp(iconWarning, other.iconWarning, t)!,
      iconDanger: Color.lerp(iconDanger, other.iconDanger, t)!,
      iconDisabled: Color.lerp(iconDisabled, other.iconDisabled, t)!,
      iconInverse: Color.lerp(iconInverse, other.iconInverse, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderAccent: Color.lerp(borderAccent, other.borderAccent, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      separatorDefault: Color.lerp(
        separatorDefault,
        other.separatorDefault,
        t,
      )!,
      courierCainiao: Color.lerp(courierCainiao, other.courierCainiao, t)!,
      courierJd: Color.lerp(courierJd, other.courierJd, t)!,
      courierSf: Color.lerp(courierSf, other.courierSf, t)!,
      courierZto: Color.lerp(courierZto, other.courierZto, t)!,
      courierYto: Color.lerp(courierYto, other.courierYto, t)!,
      courierYunda: Color.lerp(courierYunda, other.courierYunda, t)!,
      courierJt: Color.lerp(courierJt, other.courierJt, t)!,
    );
  }
}
