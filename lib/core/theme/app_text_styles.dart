import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    double letterSpacing = 0,
    double height = 1.4,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle display = _base(
    size: 30,
    weight: FontWeight.w600,
    letterSpacing: -0.02 * 30,
    height: 1.2,
  );

  static TextStyle titleLarge = _base(
    size: 26,
    weight: FontWeight.w600,
    letterSpacing: -0.02 * 26,
    height: 1.25,
  );

  static TextStyle titleMedium = _base(
    size: 22,
    weight: FontWeight.w600,
    letterSpacing: -0.02 * 22,
    height: 1.3,
  );

  static TextStyle taskTitle = _base(
    size: 15,
    weight: FontWeight.w500,
    letterSpacing: -0.01 * 15,
    height: 1.35,
  );

  static TextStyle body = _base(size: 15, weight: FontWeight.w400, height: 1.5);

  static TextStyle label = _base(
    size: 13,
    weight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle meta = _base(size: 12, weight: FontWeight.w400, height: 1.4);

  static TextStyle overline = _base(
    size: 11,
    weight: FontWeight.w500,
    letterSpacing: 0.09 * 11,
    height: 1.2,
  );

  static TextStyle button = _base(
    size: 15,
    weight: FontWeight.w600,
    letterSpacing: -0.01 * 15,
    height: 1.0,
  );
}
