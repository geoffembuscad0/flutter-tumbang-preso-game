import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/ui/welcome/welcome_screen.dart';

void main() {
  runApp(const TumbangPresoApp());
}

class TumbangPresoApp extends StatelessWidget {
  const TumbangPresoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tumbang Preso',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const WelcomeScreen(),
    );
  }
}