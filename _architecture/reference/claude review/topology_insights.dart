// File: client_flutter/lib/features/code_visualizer/models/topology_insights.dart
//
// Computed "diagnostic" flags layered on top of the raw exported metrics.
// This is the piece that makes the visualizer more than a plain Graphify
// port: instead of just showing complexity/loc/fan-in/fan-out numbers,
// it names the *pattern* those numbers add up to.

import 'topology_models.dart';

extension TopologyNodeInsights on TopologyNodeModel {
  /// A "God Function": does too much, is too big, and touches too many
  /// other symbols. Any one of these alone is fine — the combination is
  /// the smell.
  bool get isGodFunction =>
      (exceedsComplexityThreshold && exceedsLocThreshold) ||
      (complexity >= 15 && loc >= 80) ||
      (fanOut >= 8 && params.length >= 5);

  /// A structural hub: lots of things call it, or it calls lots of things.
  /// Not necessarily bad — but worth knowing before you touch it.
  bool get isHub => (fanIn + fanOut) >= 6;

  /// Never called, not public, not a test: almost certainly dead weight.
  bool get isDeadCode => isOrphan && !isPublic && !isTest;

  bool get isHighRisk => riskScore >= 7.0;

  /// A single top-line label for compact UI (legend swatches, chips, etc).
  /// Priority order matters: a God Function that also happens to be a hub
  /// should read as a God Function first.
  String get primaryBadgeLabel {
    if (isGodFunction) return 'God Function';
    if (isDeadCode) return 'Dead Code';
    if (isHighRisk) return 'High Risk';
    if (isHub) return 'Hub';
    return '';
  }

  String get primaryBadgeEmoji {
    if (isGodFunction) return '👑';
    if (isDeadCode) return '💀';
    if (isHighRisk) return '⚠️';
    if (isHub) return '🔥';
    return '';
  }
}
