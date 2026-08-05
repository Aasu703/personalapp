import 'package:flutter/material.dart';

/// Small chip for a transaction category.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.selected = false});

  final String category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(category),
      selected: selected,
      backgroundColor: selected ? scheme.secondaryContainer : null,
      side: selected ? BorderSide(color: scheme.secondary) : null,
    );
  }
}
