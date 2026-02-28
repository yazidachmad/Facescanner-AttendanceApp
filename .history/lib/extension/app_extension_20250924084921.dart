import 'package:flutter/material.dart';

extension AppColorScheme on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get secondary => Theme.of(this).colorScheme.secondary;
  Color get terary => Theme.of(this).colorScheme.tertiary;
} 