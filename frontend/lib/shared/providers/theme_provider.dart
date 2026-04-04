import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ThemeType { healthcare, finance, standard }

class ThemeNotifier extends StateNotifier<ThemeType> {
  ThemeNotifier() : super(ThemeType.standard);

  void setHealthcare() => state = ThemeType.healthcare;
  void setFinance() => state = ThemeType.finance;
  void setStandard() => state = ThemeType.standard;
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeType>((ref) {
  return ThemeNotifier();
});
