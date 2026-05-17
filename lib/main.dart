import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/card_list_screen.dart';
import 'screens/set_list_screen.dart';
import 'screens/card_detail_screen.dart';
import 'models/vg_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: VgCardApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SetListScreen(),
    ),
    GoRoute(
      path: '/cards',
      builder: (context, state) {
        final setName = state.extra as String;
        return CardListScreen(setName: setName);
      },
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) {
        final card = state.extra as VgCard;
        return CardDetailScreen(card: card);
      },
    ),
  ],
);

class VgCardApp extends StatelessWidget {
  const VgCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vanguard DB',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B), // Slate 800
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.redAccent,
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
