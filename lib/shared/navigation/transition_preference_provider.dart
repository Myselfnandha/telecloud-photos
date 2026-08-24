import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/providers.dart';

enum PageTransitionStyle {
  fadeSlideUp,
  sharedAxis,
  cupertinoSlide;

  static PageTransitionStyle fromString(String? val) {
    switch (val) {
      case 'sharedAxis':
        return PageTransitionStyle.sharedAxis;
      case 'cupertinoSlide':
        return PageTransitionStyle.cupertinoSlide;
      case 'fadeSlideUp':
      default:
        return PageTransitionStyle.fadeSlideUp;
    }
  }

  String toPrefString() {
    switch (this) {
      case PageTransitionStyle.sharedAxis:
        return 'sharedAxis';
      case PageTransitionStyle.cupertinoSlide:
        return 'cupertinoSlide';
      case PageTransitionStyle.fadeSlideUp:
        return 'fadeSlideUp';
    }
  }

  String get displayName {
    switch (this) {
      case PageTransitionStyle.fadeSlideUp:
        return 'Smooth Fade & Slide (Apple Style)';
      case PageTransitionStyle.sharedAxis:
        return 'Material Shared Axis';
      case PageTransitionStyle.cupertinoSlide:
        return 'iOS Cupertino Push';
    }
  }

  String get description {
    switch (this) {
      case PageTransitionStyle.fadeSlideUp:
        return 'Subtle 30px slide-up with opacity fade and staggered entrance';
      case PageTransitionStyle.sharedAxis:
        return 'Horizontal shared-axis transition between pages';
      case PageTransitionStyle.cupertinoSlide:
        return 'Native iOS page push with 30% background parallax shift';
    }
  }
}

class PageTransitionNotifier extends StateNotifier<PageTransitionStyle> {
  final SharedPreferences _prefs;
  static const String _prefKey = 'telecloud_transition_style';

  PageTransitionNotifier(this._prefs)
      : super(PageTransitionStyle.fromString(_prefs.getString(_prefKey)));

  Future<void> setTransitionStyle(PageTransitionStyle style) async {
    state = style;
    await _prefs.setString(_prefKey, style.toPrefString());
  }
}

final pageTransitionProvider =
    StateNotifierProvider<PageTransitionNotifier, PageTransitionStyle>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PageTransitionNotifier(prefs);
});
