import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:prac5/features/recipes/models/recipe.dart';
import 'package:prac5/features/recipes/screens/recipe_form_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onDelete;
  final Function(bool) onToggleCooked;
  final Function(int) onRate;
  final Function(Recipe) onUpdate;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.onDelete,
    required this.onToggleCooked,
    required this.onRate,
    required this.onUpdate,
  });

  void _rateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Оценить рецепт'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final r = i + 1;
            return IconButton(
              icon: Icon(r <= (recipe.rating ?? 0) ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
              onPressed: () { onRate(r); Navigator.pop(context); },
            );
          }),
        ),
        actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')) ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить рецепт?'),
        content: Text('Удалить «${recipe.title}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); onDelete(); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeFormScreen(
      recipe: recipe,
      onSave: (updated) { onUpdate(updated); Navigator.pop(context); },
    )));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали рецепта'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(context)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row(Icons.category, 'Категория', recipe.category),
              if (recipe.cookTime != null) _row(Icons.timer_outlined, 'Время', '${recipe.cookTime} мин'),
              _row(Icons.calendar_today, 'Добавлено', df.format(recipe.dateAdded)),
              if (recipe.dateCooked != null) _row(Icons.check, 'Приготовлено', df.format(recipe.dateCooked!)),
              if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(recipe.description!, style: const TextStyle(fontSize: 16)),
              ],
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onToggleCooked(!recipe.isCooked),
                    icon: Icon(recipe.isCooked ? Icons.undo : Icons.check),
                    label: Text(recipe.isCooked ? 'Вернуть в план' : 'Отметить приготовленным'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _rateDialog(context),
                  icon: const Icon(Icons.star),
                  label: const Text('Оценить'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _header() {
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    final bgTop = recipe.isCooked ? Colors.green : Colors.deepOrange;
    final bgBottom = recipe.isCooked ? Colors.green.shade300 : Colors.deepOrange.shade300;

    if (!hasImage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bgTop, bgBottom], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: _headerContent(color: Colors.white),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: recipe.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.black12),
            errorWidget: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [bgTop, bgBottom], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _headerContent(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _headerContent({required Color color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(recipe.isCooked ? Icons.check_circle : Icons.schedule, size: 64, color: color),
        const SizedBox(height: 16),
        Text(
          recipe.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          recipe.author,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: color.withOpacity(0.95), fontStyle: FontStyle.italic),
        ),
        if (recipe.rating != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (i) => Icon(i < recipe.rating! ? Icons.star : Icons.star_border, color: color, size: 24),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text('$label: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600])),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ]),
    );
  }
}
