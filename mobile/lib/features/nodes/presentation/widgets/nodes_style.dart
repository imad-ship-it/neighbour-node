import 'package:flutter/material.dart';

/// Node-gold: the brand accent for everything Node-related (map markers,
/// sheet accents) — warm against the teal app seed.
const Color kNodeGold = Color(0xFFD9A62E);

/// "850 m" under a kilometre, "1.2 km" above.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
