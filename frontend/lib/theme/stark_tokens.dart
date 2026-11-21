
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Design tokens from DESIGN.md. Every screen reads from here; never invent a value.
abstract final class StarkColors {
  static const navy = Color(0xFF0E2240);
  static const navy2 = Color(0xFF1A3560);
  static const blue = Color(0xFF1F5FD1);
  static const bluePress = Color(0xFF194FB0);
  static const tarmac = Color(0xFFEEF1F5);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF142036);
  static const muted = Color(0xFF5A6780);
  static const line = Color(0xFFD8DEE8);
  static const rowLine = Color(0xFFE8ECF2);
  static const rowHover = Color(0xFFF5F8FD);
  static const freshRow = Color(0xFFE3ECFC);
  static const green = Color(0xFF17834F);
  static const amber = Color(0xFFA8620E);
  static const red = Color(0xFFC2302A);
  static const inactiveDot = Color(0xFF9AA6BA);
  static const onNavyText = Color(0xFFEDF2FA);
  static const onNavyMuted = Color(0xFFB9C7DE);
  static const plateInk = Color(0xFF1B1B1B);
  static const input = Color(0xFFC5CEDC);
  static const navActiveBar = Color(0xFF6E9BEF);
  static const navDivider = Color(0xFF23406D);
  static const ghostBorderOnNavy = Color(0xFF3A5582);
  static const errorTint = Color(0xFFFDF1F0);
  static const errorBorder = Color(0xFFF0C9C6);
  static const registerHead = Color(0xFFF8F9FB); // DESIGN.md Components: Register header row
}

abstract final class StarkFonts {
  static const display = 'Archivo'; // variable: wght + wdth
  static const body = 'PublicSans'; // variable: wght
  static const plate = 'BarlowCondensed'; // plates only
}

abstract final class StarkRadius {
  static const control = 4.0;
  static const surface = 6.0;
  static const plate = 3.0;
  static const plateXl = 8.0;
  static const chip = 999.0;
}

abstract final class StarkMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const rowLeave = Duration(milliseconds: 260);
  static const freshFade = Duration(milliseconds: 1800);
  static const toast = Duration(milliseconds: 3200);
  static const heroCycle = Duration(milliseconds: 3200);
  static const ease = Cubic(0.2, 0.7, 0.2, 1);
}

/// Text styles. The bundled fonts are variable, so weight and width are set as font
/// variations as well as [FontWeight] (Flutter Web doesn't map one to the other).
abstract final class StarkText {
  static TextStyle display(double size, {FontWeight weight = FontWeight.w800, double width = 115, Color? color}) =>
      TextStyle(
        fontFamily: StarkFonts.display,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble()), FontVariation('wdth', width)],
        height: 1.08,
        letterSpacing: -0.01 * size,
        color: color,
      );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color, double height = 1.55}) =>
      TextStyle(
        fontFamily: StarkFonts.body,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        height: height,
        color: color,
      );
}
