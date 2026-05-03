import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePhotoState {
  final String? userId;
  final String? photoPath;
  final bool isLoading;
  final String? error;

  const ProfilePhotoState({
    this.userId,
    this.photoPath,
    this.isLoading = false,
    this.error,
  });

  ProfilePhotoState copyWith({
    String? userId,
    String? photoPath,
    bool? isLoading,
    String? error,
    bool clearPhoto = false,
  }) {
    return ProfilePhotoState(
      userId: userId ?? this.userId,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfilePhotoNotifier extends StateNotifier<ProfilePhotoState> {
  static const _storagePrefix = 'profile_photo_path_';

  final FlutterSecureStorage _storage;
  final ImagePicker _picker;

  ProfilePhotoNotifier()
      : _storage = const FlutterSecureStorage(),
        _picker = ImagePicker(),
        super(const ProfilePhotoState());

  Future<void> loadPhoto(String userId) async {
    if (state.userId == userId && state.photoPath != null) return;
    state = state.copyWith(userId: userId, isLoading: true, error: null);
    try {
      final path = await _storage.read(key: _key(userId));
      if (path == null || path.isEmpty) {
        state = state.copyWith(isLoading: false, clearPhoto: true);
        return;
      }
      final file = File(path);
      if (!await file.exists()) {
        await _storage.delete(key: _key(userId));
        state = state.copyWith(isLoading: false, clearPhoto: true);
        return;
      }
      state = state.copyWith(photoPath: path, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load profile photo',
      );
    }
  }

  Future<bool> pickPhoto(String userId) async {
    state = state.copyWith(userId: userId, error: null);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return false;

      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(
        '${directory.path}${Platform.pathSeparator}profile_photos',
      );
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final oldPath = await _storage.read(key: _key(userId));
      final extension = _extensionFromPath(picked.path);
      final safeUser = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName =
          'profile_${safeUser}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = '${folder.path}${Platform.pathSeparator}$fileName';
      await File(picked.path).copy(savedPath);
      await _storage.write(key: _key(userId), value: savedPath);

      if (oldPath != null && oldPath != savedPath) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      state = state.copyWith(photoPath: savedPath, isLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not update profile photo',
      );
      return false;
    }
  }

  Future<bool> removePhoto(String userId) async {
    try {
      final path = await _storage.read(key: _key(userId));
      await _storage.delete(key: _key(userId));
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      state = state.copyWith(userId: userId, clearPhoto: true, error: null);
      return true;
    } catch (_) {
      state = state.copyWith(error: 'Could not remove profile photo');
      return false;
    }
  }

  String _key(String userId) => '$_storagePrefix$userId';

  String _extensionFromPath(String path) {
    final index = path.lastIndexOf('.');
    if (index == -1 || index == path.length - 1) return '.jpg';
    final extension = path.substring(index).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp'};
    return allowed.contains(extension) ? extension : '.jpg';
  }
}

final profilePhotoProvider =
    StateNotifierProvider<ProfilePhotoNotifier, ProfilePhotoState>((ref) {
  return ProfilePhotoNotifier();
});
