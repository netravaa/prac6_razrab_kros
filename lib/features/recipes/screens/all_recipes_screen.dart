import 'package:flutter/material.dart';
import 'package:prac5/shared/widgets/empty_state.dart';
import 'package:prac5/features/recipes/models/recipe.dart';
import 'package:prac5/features/recipes/widgets/recipe_tile.dart';


class AllRecipesScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final Function(String) onDelete;
  final Function(String, bool) onToggleCooked;
  final Function(String, int) onRate;
  final Function(Recipe) onUpdate;

  const AllRecipesScreen({
    super.key,
    required this.recipes,
    required this.onDelete,
    required this.onToggleCooked,
    required this.onRate,
    required this.onUpdate,
  });

  @override
  State<AllRecipesScreen> createState() => _AllRecipesScreenState();
}

class _AllRecipesScreenState extends State<AllRecipesScreen> {
  String _query = '';
  String _category = 'Все';
  String _sortBy = 'dateAdded';

  List<Recipe> get _filtered {
    var list = widget.recipes.where((r) {
      final q = _query.toLowerCase();
      final okQuery = r.title.toLowerCase().contains(q) || r.author.toLowerCase().contains(q);
      final okCat = _category == 'Все' || r.category == _category;
      return okQuery && okCat;
    }).toList();

    switch (_sortBy) {
      case 'title': list.sort((a,b)=>a.title.compareTo(b.title)); break;
      case 'author': list.sort((a,b)=>a.author.compareTo(b.author)); break;
      case 'rating': list.sort((a,b)=>(b.rating??0).compareTo(a.rating??0)); break;
      case 'dateAdded':
      default: list.sort((a,b)=>b.dateAdded.compareTo(a.dateAdded));
    }
    return list;
  }

  List<String> get _categories {
    final set = widget.recipes.map((e) => e.category).toSet().toList()..sort();
    return ['Все', ...set];
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Поиск по названию или автору',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(()=>_query=v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: _categories.map((c)=>DropdownMenuItem(value:c, child: Text(c))).toList(),
                onChanged: (v)=>setState(()=>_category=v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(labelText: 'Сортировка', border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'dateAdded', child: Text('По дате')),
                  DropdownMenuItem(value: 'title', child: Text('По названию')),
                  DropdownMenuItem(value: 'author', child: Text('По автору')),
                  DropdownMenuItem(value: 'rating', child: Text('По оценке')),
                ],
                onChanged: (v)=>setState(()=>_sortBy=v!),
              ),
            ),
          ]),
        ]),
      ),
      Expanded(
        child: items.isEmpty
          ? const EmptyState(icon: Icons.search_off, title: 'Рецепты не найдены', subtitle: 'Измените фильтры')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final r = items[i];
                return RecipeTile(
                  key: ValueKey(r.id),
                  recipe: r,
                  onDelete: () => widget.onDelete(r.id),
                  onToggleCooked: (cooked) => widget.onToggleCooked(r.id, cooked),
                  onRate: (rating) => widget.onRate(r.id, rating),
                  onUpdate: widget.onUpdate,
                );
              },
            ),
      ),
    ]);
  }
}
