import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'stark_tokens.dart';

/// shadcn_ui theme built from DESIGN.md tokens.
ShadThemeData starkTheme() {
  return ShadThemeData(
    brightness: Brightness.light,
    radius: BorderRadius.circular(StarkRadius.control),
    textTheme: ShadTextTheme(family: StarkFonts.body),
    colorScheme: const ShadColorScheme(
      background: StarkColors.tarmac,
      foreground: StarkColors.ink,
      card: StarkColors.paper,
      cardForeground: StarkColors.ink,
      popover: StarkColors.paper,
      popoverForeground: StarkColors.ink,
      primary: StarkColors.blue,
      primaryForeground: StarkColors.paper,
      secondary: StarkColors.paper,
      secondaryForeground: StarkColors.ink,
      muted: StarkColors.tarmac,
      mutedForeground: StarkColors.muted,
      accent: StarkColors.rowHover,
      accentForeground: StarkColors.ink,
      destructive: StarkColors.red,
      destructiveForeground: StarkColors.paper,
      border: StarkColors.line,
      input: StarkColors.input,
      ring: StarkColors.blue,
      selection: Color(0x331F5FD1),
    ),
  );
}
