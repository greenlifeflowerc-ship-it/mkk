import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/iron_omen_game.dart';
import '../../game/match/match_config.dart';
import '../../game/match/round_state.dart';
import '../controls/touch_controls_overlay.dart';
import '../hud/fight_hud.dart';
import '../theme/ui_theme.dart';
import 'pause_overlay.dart';
import 'victory_screen.dart';

/// Hosts the Flame game with the Flutter HUD layered above it. On portrait
/// phones a rotate-device overlay covers the screen instead.
class FightScreen extends StatefulWidget {
  const FightScreen({super.key, required this.config});

  final MatchConfig config;

  @override
  State<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends State<FightScreen> {
  late final IronOmenGame _game = IronOmenGame(config: widget.config);

  bool get _isTouchPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _backToMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiTheme.background,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (_isTouchPlatform && orientation == Orientation.portrait) {
            return const _RotateDeviceOverlay();
          }
          return Stack(
            children: [
              GameWidget(game: _game),
              // HUD layers attach once the game (and its MatchManager) is
              // fully loaded.
              FutureBuilder<void>(
                future: _game.loaded,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    children: [
                      FightHud(match: _game.match),
                      if (_isTouchPlatform)
                        TouchControlsOverlay(state: _game.touchState),
                      if (_isTouchPlatform)
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.pause,
                                  color: UiTheme.boneWhite, size: 30),
                              onPressed: _game.togglePause,
                            ),
                          ),
                        ),
                      ListenableBuilder(
                        listenable: _game.match,
                        builder: (context, _) {
                          if (_game.match.phase != RoundPhase.matchEnd) {
                            return const SizedBox.shrink();
                          }
                          final winner = _game.match.matchWinnerId == 'P1'
                              ? _game.p1
                              : _game.p2;
                          return VictoryScreen(
                            winnerLabel:
                                '${winner.playerId} ${winner.data.displayName}'
                                '\nWINS',
                            onRematch: _game.quitToRematch,
                            onMainMenu: _backToMenu,
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _game.pauseNotifier,
                        builder: (context, paused, _) {
                          if (!paused) return const SizedBox.shrink();
                          return PauseOverlay(
                            onResume: _game.togglePause,
                            onQuitMatch: () {
                              _game.togglePause();
                              _backToMenu();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RotateDeviceOverlay extends StatelessWidget {
  const _RotateDeviceOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: UiTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_rotation, size: 72, color: UiTheme.emberOrange),
            SizedBox(height: 24),
            Text(
              'ROTATE DEVICE',
              style: TextStyle(
                color: UiTheme.boneWhite,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
