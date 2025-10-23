import 'package:flutter/material.dart';
import 'package:prac5/features/profile/models/user_profile.dart';
import 'package:prac5/features/profile/services/profile_service.dart';
import 'package:prac5/services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _imageService = ImageService();

  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = const UserProfile(id: 'u1', nickname: 'Chef');
    _imageService.initialize();
  }

  Future<void> _changeAvatar() async {
    final newAvatarUrl = await _imageService.getNextAvatar();

    if (newAvatarUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Нет доступных аватарок. Требуется интернет для загрузки новых.',
            ),
          ),
        );
      }
      return;
    }

    await _profileService.updateAvatar(newAvatarUrl);

    if (!mounted) return;
    setState(() {
      _profile = _profile.copyWith(avatarUrl: newAvatarUrl);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Аватар обновлён')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _profile.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundImage:
                (avatar != null) ? NetworkImage(avatar) : null,
                child:
                (avatar == null) ? const Icon(Icons.person, size: 56) : null,
              ),
              const SizedBox(height: 16),
              Text(_profile.nickname, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _changeAvatar,
                icon: const Icon(Icons.refresh),
                label: const Text('Сменить аватар'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
