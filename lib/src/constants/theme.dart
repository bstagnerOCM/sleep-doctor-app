import './colors.dart';
import './fonts.dart';
import 'package:flutter/material.dart';

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: primaryColor,
  onPrimary: lightColor,
  primaryContainer: backgroundColor,
  onPrimaryContainer: darkColor,
  secondary: secondaryColor,
  onSecondary: lightColor,
  secondaryContainer: secondaryColor,
  onSecondaryContainer: darkColor,
  tertiary: tertiaryColor,
  onTertiary: darkColor,
  background: backgroundColor,
  onBackground: darkColor,
  surface: backgroundColor,
  onSurface: darkColor,
  error: errorColor,
  onError: lightColor,
  errorContainer: backgroundColor,
  onErrorContainer: errorColor,
  outline: greyColor,
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFFFFFFF),
  onPrimary: Color(0xFF091B46),
  primaryContainer: Color(0xFF677DD2),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFFFFFFFF),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF086399),
  onSecondaryContainer: Color(0xFFFFFFFF),
  tertiary: Color(0xFF65DEB1),
  onTertiary: Color(0xFF000000),
  background: Color(0xFF2E3038),
  onBackground: Color(0xFFFFFFFF),
  surface: Color(0xFF2E3038),
  onSurface: Color(0xFFFFFFFF),
  error: Color(0xFFB00020),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF2DEDE),
  onErrorContainer: Color(0xFF000000),
  outline: Color(0xFF949EB0),
);

TextTheme buildTextTheme(ColorScheme colorScheme) {
  return TextTheme(
    titleLarge: TextStyle(
        color: colorScheme.secondary,
        fontSize: 32,
        fontFamily: headerFont,
        fontWeight: FontWeight.bold),
    titleMedium: TextStyle(
        color: colorScheme.primary,
        fontSize: 28,
        fontFamily: headerFont,
        fontWeight: FontWeight.bold),
    titleSmall: TextStyle(
        color: colorScheme.primary,
        fontSize: 22,
        fontFamily: headerFont,
        fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(
        color: colorScheme.primary,
        fontSize: 22,
        fontFamily: bodyFont,
        fontWeight: FontWeight.w700),
    bodyMedium: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontSize: 16,
        fontFamily: bodyFont,
        fontWeight: FontWeight.w500),
    bodySmall: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontSize: 14,
        fontFamily: bodyFont,
        fontWeight: FontWeight.w500),
    displaySmall: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontSize: 12,
        fontFamily: bodyFont,
        fontWeight: FontWeight.w500),
  );
}
