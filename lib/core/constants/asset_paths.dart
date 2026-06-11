/// Asset path conventions. Flame's `images.load` is rooted at
/// `assets/images/`, so these helpers return paths relative to that root.
class AssetPaths {
  AssetPaths._();

  static String fighterAnimation(String fighterId, String animationKey) =>
      'fighters/$fighterId/$animationKey.png';

  static String stageLayer(String stageId, String layerFile) =>
      'stages/$stageId/$layerFile';
}
