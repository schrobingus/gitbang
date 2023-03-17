import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/*                      Color(0xff212121)
 Format for colors is             ^^^^^^ here (hex code) */

class Config {
  static var brightness = SchedulerBinding.instance.window.platformBrightness;
  static bool isDark = brightness == Brightness.dark;

  static Color foregroundColor =
      isDark ? const Color(0xfff5f5f5) : const Color(0xff212121);
  static Color grayedForegroundColor =
      isDark ? const Color(0xff9e9e9e) : const Color(0xff757575);
  static Color buttonForegroundColor =
      isDark ? const Color(0xff64b5f6) : const Color(0xff1e88e5);

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
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? const Color(0xff424242) : const Color(0xffeeeeee),
      onPrimary: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
      onSecondary: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
      secondary: isDark ? const Color(0xff616161) : const Color(0xffbdbdbd),
      background: isDark ? const Color(0xff212121) : const Color(0xffe0e0e0),
      onBackground: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
      surface: isDark ? const Color(0xff616161) : const Color(0xffbdbdbd),
      onSurface: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
      error: Colors.red, onError: Colors.white, // Error colors stay constant.
    ),
    disabledColor: isDark ? const Color(0xff9e9e9e) : const Color(0xff757575),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:
          isDark ? const Color(0xff424242) : const Color(0xffeeeeee),
      foregroundColor:
          isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
    ),
    textButtonTheme: textButton,
    dividerTheme: themeDivider,
    popupMenuTheme: themeMenu,
    dialogTheme: themeDialog,
  );

  static TextButtonThemeData textButton = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: isDark ? const Color(0xff64b5f6) : const Color(0xff1e88e5),
    ),
  );

  static InputDecoration inputDecoration = InputDecoration(
    hintStyle: TextStyle(
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121)),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        style: BorderStyle.solid,
        color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121),
      ),
    ),
  );

  static DividerThemeData themeDivider = DividerThemeData(
    color: isDark ? const Color(0xff9e9e9e) : const Color(0xff757575),
  );

  static PopupMenuThemeData themeMenu = PopupMenuThemeData(
    color: isDark ? const Color(0xff616161) : const Color(0xffbdbdbd),
    textStyle: TextStyle(
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static DialogTheme themeDialog = DialogTheme(
    backgroundColor: isDark ? const Color(0xff424242) : const Color(0xffeeeeee),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentTextStyle: TextStyle(
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121)),
    titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xfff5f5f5) : const Color(0xff212121)),
  );
}
