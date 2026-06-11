import '../../game/fighter/fighter_data.dart';
import 'ash_viper.dart';
import 'grave_warden.dart';
import 'iron_ghost.dart';
import 'night_blade.dart';

/// The playable roster, in select-screen order. Adding a fighter here (plus
/// assets and a data file) is the complete integration.
final Map<String, FighterData Function()> rosterBuilders = {
  'ash_viper': ashViper,
  'iron_ghost': ironGhost,
  'night_blade': nightBlade,
  'grave_warden': graveWarden,
};

List<String> get rosterIds => rosterBuilders.keys.toList();

FighterData fighterDataById(String id) {
  final builder = rosterBuilders[id];
  if (builder == null) throw ArgumentError('Unknown fighter "$id"');
  return builder();
}
