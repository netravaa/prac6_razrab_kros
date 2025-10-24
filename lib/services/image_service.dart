import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageService {
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

  static const int _avatarSize = 256;
  String _avatarUrlFromDicebear(int seed) =>
      'https://api.dicebear.com/7.x/adventurer/png?seed=$seed&size=$_avatarSize';

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
    bool hadLegacy = _availableImages.any(_isLegacyUrl) || _usedImages.any(_isLegacyUrl);
    if (hadLegacy) {
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

  bool _isLegacyUrl(String u) =>
      u.contains('placehold.co') ||
          u.contains('picsum.photos') ||
          u.contains('loremflickr.com');

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
        print('Ошибка предзагрузки $url: $e');
      }
    }
  }

  Future<void> _generateImagePool() async {
    _availableImages.clear();
    final fromMealDb = await _fetchMealDbImages(_imagePoolSize);
    if (fromMealDb.length < _imagePoolSize) {
      final need = _imagePoolSize - fromMealDb.length;
      final fromFoodish = await _fetchFoodishImages(need);
      _availableImages
        ..addAll(fromMealDb)
        ..addAll(fromFoodish);
    } else {
      _availableImages.addAll(fromMealDb);
    }
    _availableImages.removeWhere((u) => _usedImages.contains(u));
    final seen = <String>{};
    _availableImages.retainWhere((u) => seen.add(u));
    await _saveState();
  }

  Future<void> _generateAvatarPool() async {
    _availableAvatars.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random(now);
    for (int i = 0; i < _avatarPoolSize; i++) {
      final seed = now + i * 73 + rnd.nextInt(1000000);
      _availableAvatars.add(_avatarUrlFromDicebear(seed));
    }
    _availableAvatars.removeWhere((u) => _usedAvatars.contains(u));
    await _saveState();
  }

  Future<List<String>> _fetchMealDbImages(int needed) async {
    final result = <String>[];
    final letters = 'abcdefghijklmnopqrstuvwxyz'.split('');
    for (final ch in letters) {
      if (result.length >= needed) break;
      final uri = Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?f=$ch');
      try {
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final meals = (data['meals'] as List?) ?? [];
          for (final m in meals) {
            if (result.length >= needed) break;
            final thumb = (m['strMealThumb'] as String?)?.trim();
            if (thumb != null && thumb.isNotEmpty) {
              result.add(thumb);
            }
          }
        }
      } catch (e) {
        print('MealDB fetch error for "$ch": $e');
      }
    }
    return result;
  }

  Future<List<String>> _fetchFoodishImages(int needed) async {
    final result = <String>[];
    for (int i = 0; i < needed; i++) {
      try {
        final resp = await http.get(Uri.parse('https://foodish-api.com/api/'));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final url = (data['image'] as String?)?.trim();
          if (url != null && url.isNotEmpty) {
            result.add(url);
          }
        }
      } catch (e) {
        print('Foodish fetch error: $e');
      }
    }
    final seen = <String>{};
    result.retainWhere((u) => seen.add(u));
    return result;
  }
}
