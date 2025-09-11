import 'package:flutter/material.dart';

ThemeData emapTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
  useMaterial3: true,
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
  ),
);
