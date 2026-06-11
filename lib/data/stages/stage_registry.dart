import '../../game/stage/stage_data.dart';
import 'dusk_peaks.dart';
import 'forsaken_foundry.dart';
import 'haunted_cemetery.dart';

/// All selectable stages, in select-screen order.
final Map<String, StageData Function()> stageBuilders = {
  'forsaken_foundry': forsakenFoundry,
  'haunted_cemetery': hauntedCemetery,
  'dusk_peaks': duskPeaks,
};

List<String> get stageIds => stageBuilders.keys.toList();

StageData stageDataById(String id) {
  final builder = stageBuilders[id];
  if (builder == null) throw ArgumentError('Unknown stage "$id"');
  return builder();
}
