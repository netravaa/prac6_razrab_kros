import 'package:flutter/material.dart';
import 'package:prac5/app.dart';
import 'package:prac5/services/image_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final imageService = ImageService();
  await imageService.initialize();

  imageService.preloadImagePool().catchError((e) {
    print('Предзагрузка изображений не удалась (возможно, нет интернета): $e');
  });

  runApp(const MyApp());
}
