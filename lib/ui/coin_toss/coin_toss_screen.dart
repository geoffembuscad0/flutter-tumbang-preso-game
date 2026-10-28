import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/ui/coin_toss/widgets/coin_face.dart';
import 'package:game_tumbang_preso/ui/game/game_screen.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';
import 'package:game_tumbang_preso/ui/widgets/coin_side_label.dart';
import 'package:game_tumbang_preso/ui/widgets/player_id_label.dart';
import 'package:game_tumbang_preso/ui/widgets/sky_background.dart';
/*
 Initial coin toss (spec section 4): Player 1 calls Heads or Tails, the
 coin flips, and the result and starting roles are shown before the game
 begins.

 The engine decides the outcome the moment the call is made. This screen
 holds the result back until the flip animation ends, so it reads from the
 toss event rather than from the controller's state while flipping. */
class CoinTossScreen extends StatefulWidget {
  const CoinTossScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<CoinTossScreen> createState() => _CoinTossScreenState();
}

class _CoinTossScreenState extends State<CoinTossScreen>
    with SingleTickerProviderStateMixin {
  //Three full flips land on heads; one extra half turn lands on tails.
  static const _halfTurnsToHeads = 6;

  late final AnimationController _flip;

  CoinTossed? _toss;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener(_onFlipStatus);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _onFlipStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _revealed = true);
    }
  }

  void _call(CoinSide call) {
    if (_toss != null) return; // the toss happens only once

    final events = widget.controller.callCoinToss(call);
    setState(() => _toss = events.whereType<CoinTossed>().single);

    if (MediaQuery.disableAnimationsOf(context)) {
      _flip.value = 1; // jump straight to the result
    } else {
      _flip.forward();
    }
  }

  void _startGame() {
    // Replace this screen so Back cannot return to a toss that already
    // happened.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.controller.players;
    final toss = _toss;

    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: toss == null
                    ? const BackButton(color: AppColors.ink)
                    : const SizedBox(height: kMinInteractiveDimension),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Coin toss',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${PlayerId.one.label}: ${players.one.name}',
                            textAlign: TextAlign.center,
                            style: _rosterStyle,
                          ),
                          Text(
                            '${PlayerId.two.label}: ${players.two.name}',
                            textAlign: TextAlign.center,
                            style: _rosterStyle,
                          ),
                          const SizedBox(height: 16),
                          _buildCoin(),
                          const SizedBox(height: 20),
                          ChunkyCard(
                            child: toss == null
                                ? _buildCallPanel(players)
                                : !_revealed
                                ? _buildFlippingPanel()
                                : _buildResultPanel(players, toss),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _rosterStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  Widget _buildCoin() {
    final toss = _toss;

    return ExcludeSemantics(
      child: SizedBox(
        height: 220,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: toss == null
              ? const CoinFace()
              : AnimatedBuilder(
                  animation: _flip,
                  builder: (context, _) {
                    final halfTurns =
                        _halfTurnsToHeads +
                        (toss.result == CoinSide.tails ? 1 : 0);
                    final progress = Curves.easeOutCubic.transform(_flip.value);
                    return CoinFlip(
                      angle: progress * halfTurns * math.pi,
                      lift: math.sin(progress * math.pi) * 70,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCallPanel(Players players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${players.one.name}, call it!',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${PlayerId.one.label} picks Heads or Tails. The coin decides who '
          'throws first.',
          style: const TextStyle(fontSize: 15, height: 1.3),
        ),
        const SizedBox(height: 18),
        ChunkyButton(
          key: const Key('call-heads'),
          label: CoinSide.heads.label,
          onPressed: () => _call(CoinSide.heads),
        ),
        const SizedBox(height: 16),
        ChunkyButton(
          key: const Key('call-tails'),
          label: CoinSide.tails.label,
          filled: false,
          onPressed: () => _call(CoinSide.tails),
        ),
      ],
    );
  }

  Widget _buildFlippingPanel() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Flipping the coin…',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildResultPanel(Players players, CoinTossed toss) {
    final caller = players.one.name;
    final attacker = players.of(toss.attacker);
    final taya = players.of(toss.taya);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'It’s ${toss.result.label}!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$caller called ${toss.call.label}. The coin landed '
          '${toss.result.label}, so ${attacker.name} throws first.',
          style: const TextStyle(fontSize: 15, height: 1.3),
        ),
        const SizedBox(height: 16),
        _RoleRow(
          key: const Key('attacker-row'),
          role: 'Attacker',
          color: AppColors.canRed,
          player: attacker,
        ),
        const SizedBox(height: 10),
        _RoleRow(
          key: const Key('taya-row'),
          role: 'Taya',
          color: AppColors.ink,
          player: taya,
        ),
        const SizedBox(height: 10),
        const Text(
          'The attacker throws the slipper. The taya guards the can.',
          style: TextStyle(fontSize: 14, height: 1.3),
        ),
        const SizedBox(height: 18),
        ChunkyButton(
          key: const Key('start-game'),
          label: 'Start game',
          icon: Icons.play_arrow_rounded,
          onPressed: _startGame,
        ),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    super.key,
    required this.role,
    required this.color,
    required this.player,
  });

  final String role;
  final Color color;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Text(
            role,
            style: const TextStyle(
              color: AppColors.paper,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${player.name} (${player.id.label})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}