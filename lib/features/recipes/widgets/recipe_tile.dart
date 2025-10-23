import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../screens/recipe_detail_screen.dart';

class RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onDelete;
  final Function(bool) onToggleCooked;
  final Function(int) onRate;
  final Function(Recipe) onUpdate;

  const RecipeTile({
    super.key,
    required this.recipe,
    required this.onDelete,
    required this.onToggleCooked,
    required this.onRate,
    required this.onUpdate,
  });

  void _openDetails(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(
      recipe: recipe,
      onDelete: onDelete,
      onToggleCooked: onToggleCooked,
      onRate: onRate,
      onUpdate: onUpdate,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // обложка
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60, height: 85,
                  child: (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => _fallbackCover(),
                  )
                      : _fallbackCover(),
                ),
              ),
              const SizedBox(width: 12),

              // текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: recipe.isCooked ? TextDecoration.lineThrough : null,
                        )),
                    const SizedBox(height: 4),
                    Text(recipe.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(recipe.category,
                              style: TextStyle(fontSize: 12, color: Colors.indigo.shade700)),
                        ),
                        if (recipe.rating != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${recipe.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  recipe.isCooked ? Icons.undo : Icons.check_circle_outline,
                  color: recipe.isCooked ? Colors.grey : Colors.green,
                ),
                onPressed: () => onToggleCooked(!recipe.isCooked),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            recipe.isCooked ? Colors.green.shade400 : Colors.deepOrange.shade400,
            recipe.isCooked ? Colors.green.shade700 : Colors.deepOrange.shade700,
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: Colors.white70, size: 28),
      ),
    );
  }
}
