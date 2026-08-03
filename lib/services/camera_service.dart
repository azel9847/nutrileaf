import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for capturing images from camera or gallery.
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Capture an image from the device camera.
  Future<File?> captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return null;
      return _saveToAppDirectory(File(photo.path));
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from the device gallery.
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;
      return _saveToAppDirectory(File(image.path));
    } catch (e) {
      return null;
    }
  }

  /// Save image to app's documents directory for persistence.
  Future<File> _saveToAppDirectory(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scanDir = Directory('${appDir.path}/nutrileaf_scans');
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = _getExtension(sourceFile.path);
    final newPath = '${scanDir.path}/scan_$timestamp$ext';

    return sourceFile.copy(newPath);
  }

  /// Extract file extension from a path string.
  String _getExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '.jpg';
    return filePath.substring(lastDot);
  }
}
