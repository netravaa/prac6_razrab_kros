import 'package:flutter/material.dart';
import '../../../shared/constants.dart';
import '../models/recipe.dart';
import '../../../services/image_service.dart';

class RecipeFormScreen extends StatefulWidget {
  final Function(Recipe) onSave;
  final Recipe? recipe;

  const RecipeFormScreen({super.key, required this.onSave, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _description = TextEditingController();
  final _time = TextEditingController();
  final _imageUrl = TextEditingController();

  final _imageService = ImageService();

  String _category = AppConstants.categories.first;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    if (r != null) {
      _title.text = r.title;
      _author.text = r.author;
      _category = r.category;
      _description.text = r.description ?? '';
      _time.text = r.cookTime?.toString() ?? '';
      _imageUrl.text = r.imageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _description.dispose();
    _time.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _generateImageUrl() async {
    final url = await _imageService.getNextRecipeImage();
    if (!mounted) return;
    setState(() => _imageUrl.text = url ?? '');
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить изображение. Нужен интернет.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка на изображение сгенерирована')),
      );
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updated = widget.recipe?.copyWith(
        title: _title.text.trim(),
        author: _author.text.trim(),
        category: _category,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        cookTime: _time.text.trim().isEmpty ? null : int.tryParse(_time.text.trim()),
        imageUrl: _imageUrl.text.trim().isEmpty ? widget.recipe?.imageUrl : _imageUrl.text.trim(),
      ) ??
          Recipe(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _title.text.trim(),
            author: _author.text.trim(),
            category: _category,
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            cookTime: _time.text.trim().isEmpty ? null : int.tryParse(_time.text.trim()),
            imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
          );
      widget.onSave(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать рецепт' : 'Добавить рецепт'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _author,
                decoration: const InputDecoration(
                  labelText: 'Автор *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите автора' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _time,
                decoration: const InputDecoration(
                  labelText: 'Время (мин)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null) {
                    return 'Введите число';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Новое поле: ссылка на изображение рецепта (необязательно)
              TextFormField(
                controller: _imageUrl,
                decoration: InputDecoration(
                  labelText: 'Ссылка на изображение (необязательно)',
                  hintText: 'https://…',
                  prefixIcon: const Icon(Icons.image_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Сгенерировать из пула',
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: _generateImageUrl,
                  ),
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return null;
                  final uri = Uri.tryParse(val);
                  final ok = uri != null && uri.hasScheme && uri.hasAuthority;
                  return ok ? null : 'Некорректный URL';
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(isEditing ? Icons.save : Icons.add),
                label: Text(isEditing ? 'Сохранить изменения' : 'Добавить рецепт'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
