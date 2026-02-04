import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Toggle between light and dark theme
void toggleTheme(WidgetRef ref) {
  final current = ref.read(themeModeProvider);
  ref.read(themeModeProvider.notifier).state =
      current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

/// Light theme definition
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[200],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 2,
    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.grey[50],
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black87,
    textColor: Colors.black87,
  ),
  iconTheme: const IconThemeData(
    color: Colors.black87,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      color: Colors.black87,
    ),
    bodySmall: TextStyle(
      color: Colors.black54,
    ),
  ),
);

/// Dark theme definition
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: const Color(0xFF0A0A0A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF252525),
    elevation: 4,
    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color(0xFF1E1E1E),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.white70,
    textColor: Colors.white,
  ),
  iconTheme: const IconThemeData(
    color: Colors.white70,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      color: Colors.white70,
    ),
  ),
);
