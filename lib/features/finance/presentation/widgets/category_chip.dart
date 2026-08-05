import 'package:flutter/material.dart';

/// Small chip for a transaction category.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onSelected,
  });

  final String category;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(category),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
