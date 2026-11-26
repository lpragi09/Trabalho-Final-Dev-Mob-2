import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum PhotoStatus { saved, cancelled, denied, permanentlyDenied, unavailable }

class PhotoOutcome {
  const PhotoOutcome(this.status, [this.path]);
  final PhotoStatus status;
  final String? path;
}

/// Recurso nativo: câmera. A foto do prato fica só no armazenamento privado
/// do app (não vai para o Firestore nem para logs) e é apagada junto com a
/// receita salva.
abstract interface class DishPhotoService {
  Future<PhotoOutcome> takePhoto(String savedRecipeId);
  Future<PhotoOutcome> pickFromGallery(String savedRecipeId);
  Future<String?> photoPathFor(String savedRecipeId);
  Future<void> deletePhoto(String savedRecipeId);
  Future<bool> openSettings();
}

class DeviceDishPhotoService implements DishPhotoService {
  DeviceDishPhotoService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<File> _fileFor(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final photos = Directory('${dir.path}/dish_photos');
    if (!photos.existsSync()) photos.createSync(recursive: true);
    return File('${photos.path}/$id.jpg');
  }

  @override
  Future<PhotoOutcome> takePhoto(String savedRecipeId) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();
    if (status.isPermanentlyDenied || status.isRestricted) {
      return const PhotoOutcome(PhotoStatus.permanentlyDenied);
    }
    if (!status.isGranted) return const PhotoOutcome(PhotoStatus.denied);
    return _capture(ImageSource.camera, savedRecipeId);
  }

  /// Alternativa sem permissão: o seletor de fotos do sistema só entrega a
  /// imagem escolhida, sem dar acesso à galeria inteira.
  @override
  Future<PhotoOutcome> pickFromGallery(String savedRecipeId) =>
      _capture(ImageSource.gallery, savedRecipeId);

  Future<PhotoOutcome> _capture(ImageSource source, String id) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (picked == null) return const PhotoOutcome(PhotoStatus.cancelled);
      final target = await _fileFor(id);
      await File(picked.path).copy(target.path);
      // Remove a cópia temporária gerada pelo picker.
      try {
        await File(picked.path).delete();
      } on FileSystemException {
        // arquivo temporário já removido pelo sistema
      }
      return PhotoOutcome(PhotoStatus.saved, target.path);
    } on Exception {
      return const PhotoOutcome(PhotoStatus.unavailable);
    }
  }

  @override
  Future<String?> photoPathFor(String savedRecipeId) async {
    final f = await _fileFor(savedRecipeId);
    return f.existsSync() ? f.path : null;
  }

  @override
  Future<void> deletePhoto(String savedRecipeId) async {
    final f = await _fileFor(savedRecipeId);
    if (f.existsSync()) await f.delete();
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
