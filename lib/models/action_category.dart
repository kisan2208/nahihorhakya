import 'package:flutter/material.dart';

/// Categories of eco-actions user can log.
enum ActionCategoryType {
  treePlanted,
  beachClean,
  recycle,
  compost,
  solarRenewable,
}

class ActionCategory {
  final ActionCategoryType type;
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  /// Whether 30m duplicate proximity check applies to this category.
  final bool requiresProximityCheck;
  
  /// Radius in meters for proximity warning (default 30.0m).
  final double proximityRadiusMeters;

  const ActionCategory({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.requiresProximityCheck = false,
    this.proximityRadiusMeters = 30.0,
  });

  static const List<ActionCategory> allCategories = [
    ActionCategory(
      type: ActionCategoryType.treePlanted,
      id: 'tree_planted',
      title: 'Tree Planted',
      description: 'Planting sapling or tree to restore greenery',
      icon: Icons.park_rounded,
      color: Color(0xFF2E7D32), // Emerald Green
      requiresProximityCheck: true,
      proximityRadiusMeters: 30.0,
    ),
    ActionCategory(
      type: ActionCategoryType.beachClean,
      id: 'beach_clean',
      title: 'Beach Clean',
      description: 'Cleaning ocean shores, riverbanks or parks',
      icon: Icons.beach_access_rounded,
      color: Color(0xFF0288D1), // Ocean Blue
      requiresProximityCheck: false,
    ),
    ActionCategory(
      type: ActionCategoryType.recycle,
      id: 'recycle',
      title: 'Recycle Waste',
      description: 'Sorting plastic, paper, e-waste or metal',
      icon: Icons.recycling_rounded,
      color: Color(0xFF388E3C), // Leaf Green
      requiresProximityCheck: false,
    ),
    ActionCategory(
      type: ActionCategoryType.compost,
      id: 'compost',
      title: 'Compost Organic',
      description: 'Composting kitchen waste & organic matter',
      icon: Icons.compost_rounded,
      color: Color(0xFF795548), // Soil Brown
      requiresProximityCheck: false,
    ),
    ActionCategory(
      type: ActionCategoryType.solarRenewable,
      id: 'solar_renewable',
      title: 'Renewable Energy',
      description: 'Installing solar panel or clean energy usage',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF57C00), // Solar Orange
      requiresProximityCheck: false,
    ),
  ];

  static ActionCategory get defaultCategory => allCategories.first;

  static ActionCategory findById(String id) {
    return allCategories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => defaultCategory,
    );
  }
}
