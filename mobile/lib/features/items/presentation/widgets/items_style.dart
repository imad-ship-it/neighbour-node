import 'package:flutter/material.dart';

/// Item-blue: marker + accent colour for rentable items, distinct from the
/// gold Node identity.
const Color kItemBlue = Color(0xFF2F6ED4);

/// Category values (§4.3) with display labels, shared by the add-item form
/// and the map filter bar.
const List<(String, String)> kItemCategories = [
  ('TOOLS', 'Tools'),
  ('BOOKS', 'Books'),
  ('ELECTRONICS', 'Electronics'),
  ('SPORTS', 'Sports'),
  ('OTHER', 'Other'),
];
