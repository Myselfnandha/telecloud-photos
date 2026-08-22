import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GridDensity { single, standard, compact }

extension GridDensityExtension on GridDensity {
  int get crossAxisCount {
    switch (this) {
      case GridDensity.single:
        return 1;
      case GridDensity.standard:
        return 3;
      case GridDensity.compact:
        return 5;
    }
  }

  double get childAspectRatio {
    switch (this) {
      case GridDensity.single:
        return 0.95;
      case GridDensity.standard:
        return 1.0;
      case GridDensity.compact:
        return 1.0;
    }
  }

  String get label {
    switch (this) {
      case GridDensity.single:
        return '1 Column';
      case GridDensity.standard:
        return '3 Columns';
      case GridDensity.compact:
        return '5 Columns';
    }
  }

  IconData get icon {
    switch (this) {
      case GridDensity.single:
        return Icons.crop_square_rounded;
      case GridDensity.standard:
        return Icons.grid_view_rounded;
      case GridDensity.compact:
        return Icons.apps_rounded;
    }
  }

  static GridDensity fromString(String? val) {
    switch (val) {
      case 'single':
        return GridDensity.single;
      case 'compact':
        return GridDensity.compact;
      case 'standard':
      default:
        return GridDensity.standard;
    }
  }
}

final gridDensityProvider =
    StateNotifierProvider<GridDensityNotifier, GridDensity>((ref) {
      return GridDensityNotifier();
    });

class GridDensityNotifier extends StateNotifier<GridDensity> {
  static const _key = 'telecloud_grid_density';

  GridDensityNotifier() : super(GridDensity.standard) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    state = GridDensityExtension.fromString(val);
  }

  Future<void> setDensity(GridDensity density) async {
    state = density;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, density.name);
  }

  void zoomIn() {
    if (state == GridDensity.compact) {
      setDensity(GridDensity.standard);
    } else if (state == GridDensity.standard) {
      setDensity(GridDensity.single);
    }
  }

  void zoomOut() {
    if (state == GridDensity.single) {
      setDensity(GridDensity.standard);
    } else if (state == GridDensity.standard) {
      setDensity(GridDensity.compact);
    }
  }
}
