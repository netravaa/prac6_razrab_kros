import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Надёжный сервис предзагрузки/кэширования изображений.
/// - Обложки рецептов: placehold.co (всегда 200, без ограничений).
/// - Аватары: Dicebear (стабильно, без авторизации).
class ImageService {
  // Singleton
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final BaseCacheManager _cacheManager = DefaultCacheManager();

  static const int _imagePoolSize = 20;
  static const int _avatarPoolSize = 20;

  static const String _keyUsedImages = 'img_used_images';
  static const String _keyAvailableImages = 'img_available_images';
  static const String _keyUsedAvatars = 'img_used_avatars';
  static const String _keyAvailableAvatars = 'img_available_avatars';

  bool _isInitialized = false;

  final List<String> _availableImages = <String>[];
  final List<String> _availableAvatars = <String>[];
  final Set<String> _usedImages = <String>{};
  final Set<String> _usedAvatars = <String>{};

  // Параметры
  static const int _recipeWidth = 400;
  static const int _recipeHeight = 600;
  static const int _avatarSize = 256;

  // ---------- URL-генераторы ----------

  // placehold.co — отдаёт PNG/JPG без ограничений и 403/500
  String _recipePlaceholderUrl(int n) =>
      'https://placehold.co/${_recipeWidth}x$_recipeHeight/png?text=Recipe+$n';

  // Dicebear — детерминированные аватарки по seed
  String _avatarUrlFromDicebear(int seed) =>
      'https://api.dicebear.com/7.x/adventurer/png?seed=$seed&size=$_avatarSize';

  // ---------- Публичные методы ----------

  /// Полный сброс пулов (если надо «обнулить» и сгенерировать заново).
  Future<void> resetPools() async {
    _availableImages.clear();
    _availableAvatars.clear();
    _usedImages.clear();
    _usedAvatars.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsedImages);
    await prefs.remove(_keyAvailableImages);
    await prefs.remove(_keyUsedAvatars);
    await prefs.remove(_keyAvailableAvatars);
    _isInitialized = false;
    await initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    final usedImagesJson = prefs.getString(_keyUsedImages);
    final availableImagesJson = prefs.getString(_keyAvailableImages);
    final usedAvatarsJson = prefs.getString(_keyUsedAvatars);
    final availableAvatarsJson = prefs.getString(_keyAvailableAvatars);

    if (usedImagesJson != null) {
      _usedImages.addAll(Set<String>.from(jsonDecode(usedImagesJson)));
    }
    if (availableImagesJson != null) {
      _availableImages.addAll(List<String>.from(jsonDecode(availableImagesJson)));
    }
    if (usedAvatarsJson != null) {
      _usedAvatars.addAll(Set<String>.from(jsonDecode(usedAvatarsJson)));
    }
    if (availableAvatarsJson != null) {
      _availableAvatars.addAll(List<String>.from(jsonDecode(availableAvatarsJson)));
    }

    // Миграция: выбросить старые нестабильные ссылки (picsum/loremflickr)
    bool hadBad =
        _availableImages.any((u) => u.contains('picsum.photos') || u.contains('loremflickr.com')) ||
            _usedImages.any((u) => u.contains('picsum.photos') || u.contains('loremflickr.com'));
    if (hadBad) {
      _availableImages.clear();
      _usedImages.clear();
      await _saveState();
    }

    if (_availableImages.isEmpty) {
      await _generateImagePool();
    }
    if (_availableAvatars.isEmpty) {
      await _generateAvatarPool();
    }

    _isInitialized = true;
  }

  /// Мягкая предзагрузка (ошибки не критичны).
  Future<void> preloadImagePool() async {
    await initialize();
    await _preloadImages(_availableImages);
    await _preloadImages(_availableAvatars);
  }

  Future<String?> getNextRecipeImage() async {
    await initialize();

    if (_availableImages.isEmpty) {
      await _generateImagePool();
      await _preloadImages(_availableImages).catchError(
            (e) => print('Не удалось предзагрузить новые изображения: $e'),
      );
    }
    if (_availableImages.isEmpty) return null;

    final imageUrl = _availableImages.removeAt(0);
    _usedImages.add(imageUrl);
    await _saveState();
    return imageUrl;
  }

  Future<String?> getNextAvatar() async {
    await initialize();

    if (_availableAvatars.isEmpty) {
      await _generateAvatarPool();
      await _preloadImages(_availableAvatars).catchError(
            (e) => print('Не удалось предзагрузить новые аватарки: $e'),
      );
    }
    if (_availableAvatars.isEmpty) return null;

    final avatarUrl = _availableAvatars.removeAt(0);
    _usedAvatars.add(avatarUrl);
    await _saveState();
    return avatarUrl;
  }

  // ---------- Внутренняя кухня ----------

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsedImages, jsonEncode(_usedImages.toList()));
    await prefs.setString(_keyAvailableImages, jsonEncode(_availableImages));
    await prefs.setString(_keyUsedAvatars, jsonEncode(_usedAvatars.toList()));
    await prefs.setString(_keyAvailableAvatars, jsonEncode(_availableAvatars));
  }

  Future<void> _preloadImages(List<String> urls) async {
    for (final url in urls) {
      try {
        await _cacheManager.downloadFile(url);
      } catch (e) {
        // Не валим поток, просто лог.
        print('Ошибка предзагрузки $url: $e');
      }
    }
  }

  Future<void> _generateImagePool() async {
    _availableImages.clear();
    // Детеминированный набор плейсхолдеров "Recipe #"
    for (int i = 1; i <= _imagePoolSize; i++) {
      _availableImages.add(_recipePlaceholderUrl(i));
    }
    await _saveState();
  }

  Future<void> _generateAvatarPool() async {
    _availableAvatars.clear();

    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < _avatarPoolSize; i++) {
      final seed = now + i * 73;
      _availableAvatars.add(_avatarUrlFromDicebear(seed));
    }
    await _saveState();
  }
}
