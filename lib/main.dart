import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_source/in_memory_data_source.dart';
import 'providers/data_source_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dataSource = InMemoryDataSource(prefs);
  await dataSource.initialize();

  runApp(
    ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Status Card List',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
