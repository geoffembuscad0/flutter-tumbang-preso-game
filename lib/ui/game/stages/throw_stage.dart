import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/turn_step.dart';
import 'package:game_tumbang_preso/ui/game/summaries.dart';
import 'package:game_tumbang_preso/ui/game/widgets/scoreboard.dart';
import 'package:game_tumbang_preso/ui/game/widgets/throw_scene.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

/// The attacker's throw, from the "Throw" button to the revealed outcome
/// (spec section 8, steps 4 to 5). It covers two controller steps,
/// [TurnStep.throwing] and [TurnStep.throwResult], so the animation carries on
/// smoothly across the moment the engine resolves the throw.
///
/// The engine decides hit or miss the instant the button is pressed, but this
/// stage holds the outcome back until the animation ends: the headline, the
/// next button and even the scores stay as they were until then.
class ThrowStage extends StatefulWidget {
  const ThrowStage({super.key, required this.controller});

  final GameController controller;

  @override
  State<ThrowStage> createState() => _ThrowStageState();
}

class _ThrowStageState extends State<ThrowStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  /// True once this stage itself started the throw animation.
  bool _started = false;

  /// True once the animation has finished and the outcome may be shown.
  bool _revealed = false;

  /// The game as it was before the throw, shown until the reveal so the
  /// scoreboard does not give the outcome away.
  GameState? _before;

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(ThrowStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // After a miss with no capture attempts left, the same stage is reused
    // for the next throw, so forget the previous one.
    if (_c.step == TurnStep.throwing && _started) {
      _started = false;
      _revealed = false;
      _before = null;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _revealed = true);
    }
  }

  void _throw() {
    if (_c.step != TurnStep.throwing) return;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final before = _c.state;
    setState(() {
      _before = before;
      _started = true;
      _revealed = reduceMotion;
    });
    _c.throwSlipper();

    if (reduceMotion) {
      _anim.value = 1;
    } else {
      _anim.forward(from: 0);
    }
  }

  void _continue() {
    if (_c.step != TurnStep.throwResult) return;
    _c.continueFromThrow();
  }

  ThrowOutcome? _outcomeOf(List<GameEvent> events) {
    for (final event in events) {
      if (event is ThrowResolved) return event.outcome;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final step = _c.step;

    // This stage only covers the throw. If it is rebuilt while the next stage
    // is fading in (the switcher keeps this one on screen briefly), draw
    // nothing rather than describe a throw that is no longer current.
    if (step != TurnStep.throwing && step != TurnStep.throwResult) {
      return const SizedBox.shrink();
    }

    final inResult = step == TurnStep.throwResult;
    final animating = _started && !_revealed;
    final state = animating ? (_before ?? _c.state) : _c.state;
    final events = inResult ? _c.lastEvents : const <GameEvent>[];

    final Animation<double> progress;
    if (step == TurnStep.throwing) {
      progress = const AlwaysStoppedAnimation<double>(0);
    } else if (_started) {
      progress = _anim;
    } else {
      // The throw happened without this stage animating it; show the end.
      progress = const AlwaysStoppedAnimation<double>(1);
    }

    final Widget footer;
    if (step == TurnStep.throwing) {
      footer = _buildPrompt();
    } else if (animating) {
      footer = _buildThrowing();
    } else {
      footer = _buildOutcome(events);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scoreboard(state: state),
        const SizedBox(height: 16),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${state.nameOf(state.attacker!)}’s throw',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ThrowScene(progress: progress, outcome: _outcomeOf(events)),
              const SizedBox(height: 12),
              footer,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tap to throw the slipper at the can.',
          style: TextStyle(fontSize: 15, height: 1.3),
        ),
        const SizedBox(height: 14),
        ChunkyButton(
          key: const Key('throw-button'),
          label: 'Throw the slipper',
          icon: Icons.sports_baseball_rounded,
          onPressed: _throw,
        ),
      ],
    );
  }

  Widget _buildThrowing() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Throwing…',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildOutcome(List<GameEvent> events) {
    final state = _c.state;
    final summary = summarizeThrow(events, state.players);
    final needsResponse =
        state.phase == GamePhase.awaitingMissResponse ||
        state.phase == GamePhase.awaitingHitResponse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            summary.headline,
            key: const Key('throw-headline'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
        for (final detail in summary.details)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              detail,
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
          ),
        const SizedBox(height: 16),
        if (needsResponse)
          ChunkyButton(
            key: const Key('pass-device'),
            label: 'Pass the device to ${state.nameOf(state.taya!)}',
            icon: Icons.phone_android_rounded,
            onPressed: _continue,
          )
        else
          ChunkyButton(
            key: const Key('continue-throw'),
            label: 'Throw again',
            icon: Icons.replay_rounded,
            onPressed: _continue,
          ),
      ],
    );
  }
}