import 'package:flutter/material.dart';
import 'package:prac5/features/recipes/models/recipe.dart';
import 'package:prac5/features/recipes/widgets/statistics_card.dart';
import 'package:prac5/features/recipes/widgets/recipe_tile.dart';
import 'package:prac5/features/recipes/screens/recipe_form_screen.dart';
import 'package:prac5/features/recipes/screens/all_recipes_screen.dart';
import 'package:prac5/features/recipes/screens/cooked_recipes_screen.dart';
import 'package:prac5/features/recipes/screens/planned_recipes_screen.dart';
import 'package:prac5/features/profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onAdd;
  final Function(String) onDelete;
  final Function(String, bool) onToggleCooked;
  final Function(String, int) onRate;
  final Function(Recipe) onUpdate;

  const HomeScreen({
    super.key,
    required this.recipes,
    required this.onAdd,
    required this.onDelete,
    required this.onToggleCooked,
    required this.onRate,
    required this.onUpdate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  void _openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeFormScreen(
          onSave: (r) {
            widget.onAdd(r);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _tabBody() {
    switch (_tab) {
      case 0:
        return _dashboard();
      case 1:
        return AllRecipesScreen(
          recipes: widget.recipes,
          onDelete: widget.onDelete,
          onToggleCooked: widget.onToggleCooked,
          onRate: widget.onRate,
          onUpdate: widget.onUpdate,
        );
      case 2:
        return CookedRecipesScreen(
          recipes: widget.recipes.where((e) => e.isCooked).toList(),
          onDelete: widget.onDelete,
          onToggleCooked: widget.onToggleCooked,
          onRate: widget.onRate,
          onUpdate: widget.onUpdate,
        );
      case 3:
        return PlannedRecipesScreen(
          recipes: widget.recipes.where((e) => !e.isCooked).toList(),
          onDelete: widget.onDelete,
          onToggleCooked: widget.onToggleCooked,
          onRate: widget.onRate,
          onUpdate: widget.onUpdate,
        );
      default:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    final total = widget.recipes.length;
    final cooked = widget.recipes.where((e) => e.isCooked).length;
    final planned = total - cooked;
    final rated = widget.recipes.where((e) => e.rating != null);
    final avg = rated.isEmpty
        ? 0.0
        : rated.map((e) => e.rating!).reduce((a, b) => a + b) / rated.length;

    final recent = widget.recipes.isEmpty
        ? <Recipe>[]
        : (widget.recipes.toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)))
        .take(5)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Статистика',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatisticsCard(
                title: 'Всего рецептов',
                value: total.toString(),
                icon: Icons.set_meal,
                color: Colors.deepOrange,
              ),
              StatisticsCard(
                title: 'Приготовлено',
                value: cooked.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              StatisticsCard(
                title: 'В планах',
                value: planned.toString(),
                icon: Icons.schedule,
                color: Colors.blueGrey,
              ),
              StatisticsCard(
                title: 'Средняя оценка',
                value: avg.toStringAsFixed(1),
                icon: Icons.star,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Недавно добавленные',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (widget.recipes.length > 5)
                TextButton(
                  onPressed: () => setState(() => _tab = 1),
                  child: const Text('Все рецепты'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Пока нет рецептов\nДобавьте первый',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              itemBuilder: (_, i) {
                final r = recent[i];
                return RecipeTile(
                  key: ValueKey(r.id),
                  recipe: r,
                  onDelete: () => widget.onDelete(r.id),
                  onToggleCooked: (c) => widget.onToggleCooked(r.id, c),
                  onRate: (rating) => widget.onRate(r.id, rating),
                  onUpdate: widget.onUpdate,
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Manager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Профиль',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _tabBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Главная'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Все'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Готово'),
          NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'В планах'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        tooltip: 'Добавить рецепт',
        child: const Icon(Icons.add),
      ),
    );
  }
}
