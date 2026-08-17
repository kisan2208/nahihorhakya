import 'package:flutter/material.dart';

/// Categories of eco-actions synchronized with UI screen.
enum ActionCategoryType {
  treePlanted,
  beachClean,
  recycleEwaste,
  compostWaste,
  segregateWaste,
}

class ActionCategory {
  final ActionCategoryType type;
  final String id;
  final String title;
  final String description;
  final String reward;
  final String badgeText;
  final IconData icon;
  final Color color;
  
  /// Whether 30m duplicate proximity check applies (Tree Planting & Beach Clean ONLY).
  final bool requiresProximityCheck;
  
  /// Radius in meters for proximity warning (default 30.0m).
  final double proximityRadiusMeters;

  /// Whether 2 photos are required (Product BEFORE & AFTER recycling).
  final bool requiresDualPhoto;

  const ActionCategory({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.badgeText,
    required this.icon,
    required this.color,
    this.requiresProximityCheck = false,
    this.proximityRadiusMeters = 30.0,
    this.requiresDualPhoto = false,
  });

  static const List<ActionCategory> allCategories = [
    ActionCategory(
      type: ActionCategoryType.treePlanted,
      id: 'tree_planted',
      title: 'Plant a Tree',
      description: 'Planting sapling or tree to restore greenery in your ward',
      reward: 'up to 100 credits',
      badgeText: 'Geo-photo + 30m Check',
      icon: Icons.park_rounded,
      color: Color(0xFF2E7D32), // Emerald Green
      requiresProximityCheck: true, // 30m Proximity Active
      proximityRadiusMeters: 30.0,
      requiresDualPhoto: false,
    ),
    ActionCategory(
      type: ActionCategoryType.beachClean,
      id: 'beach_clean',
      title: 'Join a cleanliness drive',
      description: 'Cleaning ocean shores, riverbanks, or public parks',
      reward: '75 credits',
      badgeText: 'Cleanliness Drive + 30m Check',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF0288D1), // Ocean Blue
      requiresProximityCheck: true, // 30m Proximity Active
      proximityRadiusMeters: 30.0,
      requiresDualPhoto: false,
    ),
    ActionCategory(
      type: ActionCategoryType.recycleEwaste,
      id: 'recycle_ewaste',
      title: 'Recycle e-waste',
      description: 'Sorting plastic, electronics, metal or e-waste items',
      reward: '150 credits',
      badgeText: '2 Photos: Before & After',
      icon: Icons.recycling_rounded,
      color: Color(0xFF388E3C), // Leaf Green
      requiresProximityCheck: false, // Proximity Disabled for Recycle
      requiresDualPhoto: true, // 2-Photo Proof Active (Before & After)
    ),
    ActionCategory(
      type: ActionCategoryType.compostWaste,
      id: 'compost_waste',
      title: 'Compost kitchen waste',
      description: 'Composting kitchen waste & organic food scraps',
      reward: '80 / month',
      badgeText: 'Photo + Peer Proof',
      icon: Icons.compost_rounded,
      color: Color(0xFF795548), // Soil Brown
      requiresProximityCheck: false,
      requiresDualPhoto: false,
    ),
    ActionCategory(
      type: ActionCategoryType.segregateWaste,
      id: 'segregate_waste',
      title: 'Segregate household waste',
      description: 'Separating dry and wet waste for municipal drive',
      reward: '10 / week',
      badgeText: 'QR at drive',
      icon: Icons.delete_sweep_rounded,
      color: Color(0xFFF57C00), // Amber Orange
      requiresProximityCheck: false,
      requiresDualPhoto: false,
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
