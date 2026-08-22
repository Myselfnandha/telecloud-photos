import 'package:flutter/material.dart';

enum TimelineTier {
  singlePhoto(
    columns: 1,
    label: 'Single Photo',
    icon: Icons.crop_portrait_rounded,
  ),
  dailyGrid(columns: 3, label: 'Days', icon: Icons.grid_view_rounded),
  monthlyGrid(columns: 5, label: 'Months', icon: Icons.view_module_rounded),
  yearlyMosaic(columns: 7, label: 'Years', icon: Icons.view_comfy_alt_rounded),
  allPhotos(columns: 10, label: 'All Photos', icon: Icons.grid_on_rounded);

  final int columns;
  final String label;
  final IconData icon;

  const TimelineTier({
    required this.columns,
    required this.label,
    required this.icon,
  });

  TimelineTier get nextZoomIn {
    switch (this) {
      case TimelineTier.allPhotos:
        return TimelineTier.yearlyMosaic;
      case TimelineTier.yearlyMosaic:
        return TimelineTier.monthlyGrid;
      case TimelineTier.monthlyGrid:
        return TimelineTier.dailyGrid;
      case TimelineTier.dailyGrid:
        return TimelineTier.singlePhoto;
      case TimelineTier.singlePhoto:
        return TimelineTier.singlePhoto;
    }
  }

  TimelineTier get nextZoomOut {
    switch (this) {
      case TimelineTier.singlePhoto:
        return TimelineTier.dailyGrid;
      case TimelineTier.dailyGrid:
        return TimelineTier.monthlyGrid;
      case TimelineTier.monthlyGrid:
        return TimelineTier.yearlyMosaic;
      case TimelineTier.yearlyMosaic:
        return TimelineTier.allPhotos;
      case TimelineTier.allPhotos:
        return TimelineTier.allPhotos;
    }
  }
}
