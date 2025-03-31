import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeNotifier with ChangeNotifier {
  bool _isDarkTheme = false;
 String themeColor = 'blue';
bool get isDarkTheme => _isDarkTheme;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _saveToPrefs();
    notifyListeners();
  }

   void setThemeColor(String color) {
    themeColor = color;
    _saveToPrefs();
    notifyListeners();
  }

  _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
    themeColor = prefs.getString('theme_color') ?? 'slate';
    notifyListeners();
  }

  _saveToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', _isDarkTheme);
    prefs.setString('theme_color', themeColor);
  }
  ShadThemeData get currentTheme {
    switch (themeColor) {
      case 'gray':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadGrayColorScheme.dark() : ShadGrayColorScheme.light(), brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'green':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadGreenColorScheme.dark() : ShadGreenColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'neutral':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadNeutralColorScheme.dark() : ShadNeutralColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'orange':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadOrangeColorScheme.dark() : ShadOrangeColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'red':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadRedColorScheme.dark() : ShadRedColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'rose':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadRoseColorScheme.dark() : ShadRoseColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'slate':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadSlateColorScheme.dark() : ShadSlateColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'stone':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadStoneColorScheme.dark() : ShadStoneColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'violet':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadVioletColorScheme.dark() : ShadVioletColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'yellow':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadYellowColorScheme.dark() : ShadYellowColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'zinc':
        return ShadThemeData(colorScheme: isDarkTheme ? ShadZincColorScheme.dark() : ShadZincColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
      case 'blue':
      default:
        return ShadThemeData(colorScheme: isDarkTheme ? ShadBlueColorScheme.dark() : ShadBlueColorScheme.light(),brightness: isDarkTheme ? Brightness.dark : Brightness.light);
    }
  }
}
