import 'package:flutter/material.dart';
import 'package:prac5/features/recipes/models/recipe.dart';
import 'package:prac5/features/recipes/screens/home_screen.dart';
import 'package:prac5/services/image_service.dart';

class RecipesContainer extends StatefulWidget {
  const RecipesContainer({super.key});

  @override
  State<RecipesContainer> createState() => _RecipesContainerState();
}

class _RecipesContainerState extends State<RecipesContainer> {
  final _imageService = ImageService();
  final List<Recipe> _recipes = [];

  @override
  void initState() {
    super.initState();
  }

  // Добавление рецепта с присвоением локального URL картинки
  Future<void> _add(Recipe r) async {
    final url = await _imageService.getNextRecipeImage();
    final withImage = r.copyWith(imageUrl: url, dateAdded: DateTime.now());
    setState(() => _recipes.add(withImage));
  }

  // Удаление
  void _delete(String id) {
    setState(() => _recipes.removeWhere((e) => e.id == id));
  }

  // Пометка «приготовлено»
  void _toggleCooked(String id, bool cooked) {
    final i = _recipes.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final current = _recipes[i];
    setState(() {
      _recipes[i] = current.copyWith(isCooked: cooked);
    });
  }

  // Оценка
  void _rate(String id, int rating) {
    final i = _recipes.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final current = _recipes[i];
    setState(() {
      _recipes[i] = current.copyWith(rating: rating);
    });
  }

  // Обновление (редактирование)
  void _update(Recipe updated) {
    final i = _recipes.indexWhere((e) => e.id == updated.id);
    if (i == -1) return;
    setState(() {
      _recipes[i] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      recipes: _recipes,
      onAdd: _add,
      onDelete: _delete,
      onToggleCooked: _toggleCooked,
      onRate: _rate,
      onUpdate: _update,
    );
  }
}
