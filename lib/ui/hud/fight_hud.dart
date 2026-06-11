import 'package:flutter/material.dart';

import '../../game/match/match_manager.dart';
import 'announcer_text.dart';
import 'combo_popup.dart';
import 'health_bar.dart';
import 'meter_bar.dart';
import 'round_pips.dart';
import 'round_timer.dart';

/// Full fight HUD, rebuilt every logic tick from [MatchManager] state:
/// mirrored health bars with ghost drain, round pips, center timer and the
/// announcer callout.
class FightHud extends StatelessWidget {
  const FightHud({super.key, required this.match});

  final MatchManager match;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: match,
      builder: (context, _) {
        final pulsePhase = (match.totalTicks % 30) / 30;
        return SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HealthBar(
                            fraction: match.p1.health.fraction,
                            ghost: match.ghostP1,
                            mirrored: false,
                            flash: match.totalTicks - match.lastHitTickP1 < 5,
                            pulsePhase: pulsePhase,
                            name: match.p1.data.displayName,
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: RoundPips(wins: match.p1Wins, mirrored: false),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Center(
                        child: RoundTimer(
                          seconds: match.timerSeconds,
                          pulsePhase: pulsePhase,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          HealthBar(
                            fraction: match.p2.health.fraction,
                            ghost: match.ghostP2,
                            mirrored: true,
                            flash: match.totalTicks - match.lastHitTickP2 < 5,
                            pulsePhase: pulsePhase,
                            name: match.p2.data.displayName,
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: RoundPips(wins: match.p2Wins, mirrored: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.25),
                child: AnnouncerText(text: match.announcerText),
              ),
              // Combo popups float beside the comboed fighter's side.
              Align(
                alignment: const Alignment(-0.55, -0.3),
                child: ComboPopup(
                  hits: match.comboPopupOnP1,
                  ticksSinceChange:
                      match.totalTicks - match.comboPopupTickOnP1,
                ),
              ),
              Align(
                alignment: const Alignment(0.55, -0.3),
                child: ComboPopup(
                  hits: match.comboPopupOnP2,
                  ticksSinceChange:
                      match.totalTicks - match.comboPopupTickOnP2,
                ),
              ),
              // Super meters, bottom corners.
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 12),
                  child: MeterBar(
                    meter: match.p1.meter,
                    mirrored: false,
                    pulsePhase: pulsePhase,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18, bottom: 12),
                  child: MeterBar(
                    meter: match.p2.meter,
                    mirrored: true,
                    pulsePhase: pulsePhase,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
