import 'package:flutter/material.dart';

enum PackageViewMode {
  create(Icons.add_box_outlined),
  building(Icons.apartment_outlined),
  residency(Icons.home_outlined);

  const PackageViewMode(this.icon);

  final IconData icon;

  /// Localization key prefix, e.g. `packages.views.create`.
  String get key => 'packages.views.$name';
}

class PackageViewOption {
  const PackageViewOption(this.mode);

  final PackageViewMode mode;
}
