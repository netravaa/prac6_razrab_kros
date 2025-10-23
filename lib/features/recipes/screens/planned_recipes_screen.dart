import 'package:flutter/material.dart';
import 'package:prac5/shared/widgets/empty_state.dart';
import 'package:prac5/features/recipes/models/recipe.dart';
import 'package:prac5/features/recipes/widgets/recipe_tile.dart';


class PlannedRecipesScreen extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(String) onDelete;
  final Function(String, bool) onToggleCooked;
  final Function(String, int) onRate;
  final Function(Recipe) onUpdate;

  const PlannedRecipesScreen({
    super.key,
    required this.recipes,
    required this.onDelete,
    required this.onToggleCooked,
    required this.onRate,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = recipes.toList()..sort((a,b)=> b.dateAdded.compareTo(a.dateAdded));

    return recipes.isEmpty
      ? const EmptyState(icon: Icons.schedule_outlined, title: 'Планов пока нет', subtitle: 'Добавьте рецепты для приготовления')
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
