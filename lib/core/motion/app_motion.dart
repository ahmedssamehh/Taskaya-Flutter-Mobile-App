import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration screen = Duration(milliseconds: 280);
  static const Duration exit = Duration(milliseconds: 180);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve leave = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration d(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
