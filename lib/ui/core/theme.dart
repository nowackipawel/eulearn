import 'package:flutter/material.dart';

/// Design tokens: "school wall map" (docs/02). One light theme, flat colour,
/// no shadows or gradients. Widgets never use raw hex.
abstract final class Tok {
  static const sea = Color(0xFF8CC6EC);
  static const seaInk = Color(0xFF2D6E9E);
  static const ink = Color(0xFF17324D);
  static const paper = Color(0xFFFFFFFF);
  static const signal = Color(0xFFD7263D);
  static const voice = Color(0xFFF7D860);
  static const good = Color(0xFF2E8B3D);
  static const miss = Color(0xFFD46A10);

  /// Land that is not part of the game (outside the continent).
  static const land = Color(0xFFCBDDE8);

  /// Political tints and their darker border ribbons, by tint index.
  static const tints = [Color(0xFFF7D860), Color(0xFFA6D48A), Color(0xFFF5A65B), Color(0xFFB8A2DC), Color(0xFFE8D2B0)];
  static const ribbons = [Color(0xFFD9A90F), Color(0xFF4E9A2E), Color(0xFFD46A10), Color(0xFF7650B8), Color(0xFFB08A4A)];

  /// Reserved for "my country".
  static const homeTint = Color(0xFFF4A3B5);
  static const homeRibbon = signal;

  static const stroke = 3.0;
  static const radius = 14.0;
  static const panelRadius = 6.0;
  static const touch = 64.0;
  static const gap = 16.0;

  static const press = Duration(milliseconds: 80);
  static const quick = Duration(milliseconds: 180);
  static const camera = Duration(milliseconds: 350);
  static const draw = Duration(milliseconds: 500);

  static const _display = 'SofiaSansSemiCondensed';
  static const _text = 'Andika';

  static TextStyle display(double size, {Color color = ink}) => TextStyle(
        fontFamily: _display,
        fontSize: size,
        height: 1.05,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 800)],
        color: color,
      );

  /// Country names on the map and in legends: spaced capitals.
  static TextStyle mapLabel(double size, {Color color = ink}) =>
      display(size, color: color).copyWith(letterSpacing: size * 0.18);

  static TextStyle text(double size, {Color color = ink, bool bold = false, bool italic = false}) => TextStyle(
        fontFamily: _text,
        fontSize: size,
        height: 1.3,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
      );

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        fontFamily: _text,
        scaffoldBackgroundColor: sea,
        colorScheme: ColorScheme.fromSeed(seedColor: ink, primary: ink, surface: paper),
        splashFactory: NoSplash.splashFactory,
      );
}
