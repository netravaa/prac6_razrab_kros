import 'package:flutter/foundation.dart';

class Recipe {
  final String id;
  final String title;
  final String author;        // кто добавил / шеф
  final String category;      // категория
  final String? description;
  final int? cookTime;        // время приготовления (мин)
  bool isCooked;              // приготовлено
  int? rating;                // 1..5
  final DateTime dateAdded;
  DateTime? dateCooked;

  /// Новое поле: ссылка на картинку рецепта
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    this.description,
    this.cookTime,
    this.isCooked = false,
    this.rating,
    DateTime? dateAdded,
    this.dateCooked,
    this.imageUrl,
  }) : dateAdded = dateAdded ?? DateTime.now();

  Recipe copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? description,
    int? cookTime,
    bool? isCooked,
    int? rating,
    DateTime? dateAdded,
    DateTime? dateCooked,
    String? imageUrl,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      description: description ?? this.description,
      cookTime: cookTime ?? this.cookTime,
      isCooked: isCooked ?? this.isCooked,
      rating: rating ?? this.rating,
      dateAdded: dateAdded ?? this.dateAdded,
      dateCooked: dateCooked ?? this.dateCooked,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
