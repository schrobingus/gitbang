import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

//                      Color(0xff212121)
// Format for colors is           ^^^^^^ here (hex code)

class Config {
  static var brightness = SchedulerBinding.instance.window.platformBrightness;
  static bool isDark = brightness == Brightness.dark;

  static Color foregroundColor =
      isDark ? const Color(0xfff5f5f5) : const Color(0xff212121);
  static Color grayedForegroundColor =
      isDark ? const Color(0xff9e9e9e) : const Color(0xff757575);

  static List<Color> stateColors = [
    isDark ? const Color(0xffe57373) : const Color(0xffe53935),
    // Unstaged Item
    isDark ? const Color(0xff81c784) : const Color(0xff43a047),
    // Staged Item
    isDark ? const Color(0xff9575cd) : const Color(0xff5e35b1),
    // Partially Staged Item

    isDark ? const Color(0xff64b5f6) : const Color(0xff1e88e5),
    // Selected Branch
    isDark ? const Color(0xffe57373) : const Color(0xffe53935),
    // Selected Detached Branch
  ];

  static ThemeData theme = ThemeData(
    primaryColor: isDark ? const Color(0xff424242) : const Color(0xffeeeeee),
    backgroundColor: isDark ? const Color(0xff212121) : const Color(0xffe0e0e0),
    textTheme: TextTheme(
      bodyText1: TextStyle(
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:
          isDark ? const Color(0xff424242) : const Color(0xffeeeeee),
      foregroundColor:
          isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
    ),
  );
}
