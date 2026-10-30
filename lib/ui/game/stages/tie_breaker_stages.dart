import 'package:flutter/material.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/state/tie_breaker_step.dart';
import 'package:game_tumbang_preso/ui/game/widgets/scoreboard.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';

/// Pass-the-device screen for the Jack-en-Poy tie-breaker.
///
/// Player 1 and Player 2 must confirm that they are holding the device
/// before making their private hand selection.
class TieBreakerHandoffStage extends StatelessWidget {
  const TieBreakerHandoffStage({
    super.key,
    required this.controller,
  });

  final GameController controller;

  void _confirm() {
    switch (controller.tieBreakerStep) {
      case TieBreakerStep.handoffFirst:
        controller.confirmFirstHandoff();
      case TieBreakerStep.handoffSecond:
        controller.confirmSecondHandoff();
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = controller.tieBreakerStep;

    final playerId = switch (step) {
      TieBreakerStep.handoffFirst => PlayerId.one,
      TieBreakerStep.handoffSecond => PlayerId.two,
      _ => null,
    };

    if (playerId == null) {
      return const SizedBox.shrink();
    }

    final playerName = controller.state.nameOf(playerId);

    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(
              Icons.phone_android_rounded,
              size: 72,
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            liveRegion: true,
            child: Text(
              'Pass the device to $playerName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure the other player is not looking. '
            '$playerName will make a private Jack-en-Poy selection.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 22),
          ChunkyButton(
            key: const Key('confirm-tie-breaker-handoff'),
            label: 'I’m $playerName',
            icon: Icons.lock_open_rounded,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}

/// Private hand selection screen.
///
/// Only the current player can interact with the selection buttons.
/// The opponent's selection is never displayed here.
class HandPickStage extends StatelessWidget {
  const HandPickStage({
    super.key,
    required this.controller,
  });

  final GameController controller;

  void _pick(Hand hand) {
    if (controller.tieBreakerStep != TieBreakerStep.firstPick &&
        controller.tieBreakerStep != TieBreakerStep.secondPick) {
      return;
    }

    controller.lockHand(hand);
  }

  @override
  Widget build(BuildContext context) {
    final step = controller.tieBreakerStep;

    final playerId = switch (step) {
      TieBreakerStep.firstPick => PlayerId.one,
      TieBreakerStep.secondPick => PlayerId.two,
      _ => null,
    };

    if (playerId == null) {
      return const SizedBox.shrink();
    }

    final playerName = controller.state.nameOf(playerId);

    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.sports_martial_arts_rounded,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            '$playerName, make your pick!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your hand. Your selection will remain private '
            'until the other player has also chosen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 22),
          ChunkyButton(
            key: const Key('pick-rock'),
            label: 'Rock',
            icon: Icons.circle_outlined,
            onPressed: () => _pick(Hand.rock),
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            key: const Key('pick-paper'),
            label: 'Paper',
            icon: Icons.description_outlined,
            onPressed: () => _pick(Hand.paper),
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            key: const Key('pick-scissors'),
            label: 'Scissors',
            icon: Icons.content_cut_rounded,
            onPressed: () => _pick(Hand.scissors),
          ),
        ],
      ),
    );
  }
}

/// Displays the completed Jack-en-Poy round.
///
/// Both hands are revealed only after Player 2 has submitted their selection.
class RoundResultStage extends StatelessWidget {
  const RoundResultStage({
    super.key,
    required this.controller,
  });

  final GameController controller;

  void _continue() {
    if (controller.tieBreakerStep != TieBreakerStep.roundResult) {
      return;
    }

    controller.continueFromRound();
  }

  String _handName(Hand hand) {
    return switch (hand) {
      Hand.rock => 'Rock',
      Hand.paper => 'Paper',
      Hand.scissors => 'Scissors',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    TieBreakerRoundResolved? roundResult;

    for (final event in controller.lastEvents) {
      if (event is TieBreakerRoundResolved) {
        roundResult = event;
      }
    }

    if (roundResult == null) {
      return const ChunkyCard(
        child: Text(
          'Unable to load the Jack-en-Poy round result.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final result = roundResult;
    final isDraw = result.winner == null;
    final isFinished = state.phase == GamePhase.finished;

    final headline = isDraw
        ? 'It’s a draw!'
        : '${state.nameOf(result.winner!)} wins this round!';

    final nextLabel = isFinished
        ? 'See the winner'
        : 'Next round';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scoreboard(state: state),
        const SizedBox(height: 16),
        ChunkyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  'Round ${result.round}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                headline,
                key: const Key('tie-breaker-result-headline'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              _PlayerHandResult(
                playerName: state.nameOf(PlayerId.one),
                hand: _handName(result.player1Hand),
              ),
              const SizedBox(height: 12),
              _PlayerHandResult(
                playerName: state.nameOf(PlayerId.two),
                hand: _handName(result.player2Hand),
              ),
              const SizedBox(height: 22),
              if (isDraw)
                const Text(
                  'Both players selected hands of equal strength. '
                  'Another round is needed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                  ),
                )
              else
                Text(
                  '${state.nameOf(result.winner!)} takes the round!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 20),
              ChunkyButton(
                key: const Key('continue-tie-breaker-round'),
                label: nextLabel,
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays one player's revealed hand after the round resolves.
class _PlayerHandResult extends StatelessWidget {
  const _PlayerHandResult({
    required this.playerName,
    required this.hand,
  });

  final String playerName;
  final String hand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            playerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            hand,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}