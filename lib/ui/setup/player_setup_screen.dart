import 'package:flutter/material.dart';

/// Placeholder until the player setup screen is built.
class PlayerSetupScreen extends StatelessWidget {
  const PlayerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player setup')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Player names and the coin toss are coming next.'),
        ),
      ),
    );
  }
}
