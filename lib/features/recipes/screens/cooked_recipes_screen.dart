import 'package:flutter/material.dart';
import 'package:prac5/shared/widgets/empty_state.dart';
import 'package:prac5/features/recipes/models/recipe.dart';
import 'package:prac5/features/recipes/widgets/recipe_tile.dart';


class CookedRecipesScreen extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(String) onDelete;
  final Function(String, bool) onToggleCooked;
  final Function(String, int) onRate;
  final Function(Recipe) onUpdate;

  const CookedRecipesScreen({
    super.key,
    required this.recipes,
    required this.onDelete,
    required this.onToggleCooked,
    required this.onRate,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = recipes.toList()..sort((a,b) {
      if (a.dateCooked == null && b.dateCooked == null) return 0;
      if (a.dateCooked == null) return 1;
      if (b.dateCooked == null) return -1;
      return b.dateCooked!.compareTo(a.dateCooked!);
    });

    return recipes.isEmpty
      ? const EmptyState(icon: Icons.check_circle_outline, title: 'Нет приготовленных рецептов', subtitle: 'Отметьте рецепты как приготовленные')
      : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final r = sorted[i];
            return RecipeTile(
              key: ValueKey(r.id),
              recipe: r,
              onDelete: () => onDelete(r.id),
              onToggleCooked: (c) => onToggleCooked(r.id, c),
              onRate: (rating) => onRate(r.id, rating),
              onUpdate: onUpdate,
            );
          },
        );
  }
}
