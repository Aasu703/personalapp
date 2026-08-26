import 'package:flutter/material.dart';

String hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

void dump(String label, ColorScheme s) {
  print('--- $label ---');
  final entries = <String, Color>{
    'primary': s.primary,
    'onPrimary': s.onPrimary,
    'primaryContainer': s.primaryContainer,
    'onPrimaryContainer': s.onPrimaryContainer,
    'secondary': s.secondary,
    'onSecondary': s.onSecondary,
    'secondaryContainer': s.secondaryContainer,
    'onSecondaryContainer': s.onSecondaryContainer,
    'tertiary': s.tertiary,
    'onTertiary': s.onTertiary,
    'tertiaryContainer': s.tertiaryContainer,
    'onTertiaryContainer': s.onTertiaryContainer,
    'error': s.error,
    'onError': s.onError,
    'errorContainer': s.errorContainer,
    'onErrorContainer': s.onErrorContainer,
    'surface': s.surface,
    'onSurface': s.onSurface,
    'surfaceContainerHighest': s.surfaceContainerHighest,
    'surfaceContainerHigh': s.surfaceContainerHigh,
    'surfaceContainer': s.surfaceContainer,
    'surfaceContainerLow': s.surfaceContainerLow,
    'surfaceContainerLowest': s.surfaceContainerLowest,
    'onSurfaceVariant': s.onSurfaceVariant,
    'outline': s.outline,
    'outlineVariant': s.outlineVariant,
    'inverseSurface': s.inverseSurface,
    'onInverseSurface': s.onInverseSurface,
    'inversePrimary': s.inversePrimary,
    'shadow': s.shadow,
    'scrim': s.scrim,
  };
  entries.forEach((k, v) => print('$k: ${hex(v)}'));
}

void main() {
  const seed = Color(0xFF4F46E5);
  dump('LIGHT', ColorScheme.fromSeed(seedColor: seed));
  dump('DARK', ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark));
}
