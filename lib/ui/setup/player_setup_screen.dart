import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_tumbang_preso/core/app_theme.dart';
import 'package:game_tumbang_preso/domain/domain.dart';
import 'package:game_tumbang_preso/state/game_controller.dart';
import 'package:game_tumbang_preso/ui/coin_toss/coin_toss_screen.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_button.dart';
import 'package:game_tumbang_preso/ui/widgets/chunky_card.dart';
import 'package:game_tumbang_preso/ui/widgets/player_id_label.dart';
import 'package:game_tumbang_preso/ui/widgets/sky_background.dart';

// Longest name the text fields accept. A UI limit only, so names fit on the
// scoreboard; the domain layer has no maximum.
const int _maxNameLength = 20;

const String _blankMessage = 'Please enter a name.';
const String _duplicateMessage = 'Use a different name from the first player.';

// Player setup (spec section 3): the first participant enters a name and
// picks Player 1 or Player 2, the second participant enters a name and gets
// the other number, then the game moves on to the coin toss.
class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  final _firstFocus = FocusNode();
  final _secondFocus = FocusNode();

  PlayerId _firstChoice = PlayerId.one;

  // Blank-name errors stay hidden until the person tries to continue, so
  // the form does not scold them before they have typed anything.
  bool _attempted = false;

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    _firstFocus.dispose();
    _secondFocus.dispose();
    super.dispose();
  }

  NameProblem? get _problem =>
      checkPlayerNames(_firstController.text, _secondController.text);

  bool get _firstBlank => normalizeName(_firstController.text).isEmpty;
  bool get _secondBlank => normalizeName(_secondController.text).isEmpty;

  String? get _firstError => _attempted && _firstBlank ? _blankMessage : null;

  // A duplicate is reported as soon as both names are typed, because it is
  // unambiguous; a blank is only reported after the first attempt.
  String? get _secondError {
    if (_attempted && _secondBlank) return _blankMessage;
    if (_problem == NameProblem.duplicate) return _duplicateMessage;
    return null;
  }

  void _submit() {
    setState(() => _attempted = true);

    final problem = _problem;
    if (problem != null) {
      final target = problem == NameProblem.firstEmpty
          ? _firstFocus
          : _secondFocus;
      target.requestFocus();
      return;
    }

    final players = Players.fromSetup(
      firstName: _firstController.text,
      firstChoice: _firstChoice,
      secondName: _secondController.text,
    );
    final controller = GameController.newGame(players: players);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoinTossScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BackButton(color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: _Heading(),
                    ),
                    const SizedBox(height: 20),
                    ChunkyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            step: '1',
                            title: 'First participant',
                          ),
                          const SizedBox(height: 14),
                          _NameField(
                            key: const Key('first-name-field'),
                            controller: _firstController,
                            focusNode: _firstFocus,
                            errorText: _firstError,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _secondFocus.requestFocus(),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Choose your player number',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _IdentityTile(
                                  key: const Key('identity-one'),
                                  label: PlayerId.one.label,
                                  selected: _firstChoice == PlayerId.one,
                                  onTap: () => setState(
                                    () => _firstChoice = PlayerId.one,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _IdentityTile(
                                  key: const Key('identity-two'),
                                  label: PlayerId.two.label,
                                  selected: _firstChoice == PlayerId.two,
                                  onTap: () => setState(
                                    () => _firstChoice = PlayerId.two,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ChunkyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            step: '2',
                            title: 'Second participant',
                          ),
                          const SizedBox(height: 14),
                          _NameField(
                            key: const Key('second-name-field'),
                            controller: _secondController,
                            focusNode: _secondFocus,
                            errorText: _secondError,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              const Text(
                                'Assigned automatically:',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              _AssignedBadge(
                                key: const Key('second-identity-badge'),
                                label: _firstChoice.other.label,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    ChunkyButton(
                      label: 'Continue to coin toss',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Player setup',
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Two players, one device. Player numbers stay fixed for the whole '
          'game.',
          style: TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: AppColors.paper,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Name',
        errorText: errorText,
        border: _border(AppColors.ink, 2),
        enabledBorder: _border(AppColors.ink, 2),
        focusedBorder: _border(AppColors.ink, 3),
        errorBorder: _border(AppColors.canRed, 2),
        focusedErrorBorder: _border(AppColors.canRed, 3),
      ),
    );
  }
}

// One selectable choice in the Player 1 / Player 2 picker.
class _IdentityTile extends StatelessWidget {
  const _IdentityTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.ink : AppColors.paper;
    final foreground = selected ? AppColors.paper : AppColors.ink;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.ink, width: 3),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: foreground,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Read-only chip showing the identity the second participant was given.
class _AssignedBadge extends StatelessWidget {
  const _AssignedBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sun,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}