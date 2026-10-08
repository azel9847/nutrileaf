import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// dart:io is only used for Directory.create on mobile — import is safe
// because this file is never tree-shaken on web, but the import itself
// compiles fine on all platforms. We only CALL dart:io APIs behind !kIsWeb.
import 'dart:io' show Directory;

/// Service for capturing images from camera or gallery.
///
/// Never instantiates `dart:io` [File] — uses only [XFile] from image_picker,
/// which works identically on mobile and web.
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Capture an image from the device camera.
  ///
  /// Returns `null` when the user cancels.
  /// Throws [CameraServiceException] on permission or platform errors.
  Future<PickedImage?> captureFromCamera() async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      throw CameraServiceException('Camera unavailable: $e');
    }
    if (photo == null) return null;
    return _wrapXFile(photo);
  }

  /// Pick an image from the device gallery.
  ///
  /// Returns `null` when the user cancels.
  /// Throws [CameraServiceException] on permission or platform errors.
  Future<PickedImage?> pickFromGallery() async {
    XFile? image;
    try {
      image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      throw CameraServiceException('Gallery unavailable: $e');
    }
    if (image == null) return null;
    return _wrapXFile(image);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<PickedImage> _wrapXFile(XFile xfile) async {
    if (kIsWeb) {
      // Web: dart:io is unavailable, use the XFile (blob URL) directly.
      return PickedImage(xFile: xfile);
    }

    // Mobile: copy to app documents directory for persistence.
    // XFile.saveTo() handles the copy; dart:io Directory handles mkdir.
    try {
      final savedPath = await _saveToAppDirectory(xfile);
      return PickedImage(xFile: XFile(savedPath));
    } catch (_) {
      // If saving fails, fall back to the picker's temp path.
      return PickedImage(xFile: xfile);
    }
  }

  Future<String> _saveToAppDirectory(XFile source) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scanDirPath = '${appDir.path}/nutrileaf_scans';

    // dart:io Directory.create — safe because we're behind !kIsWeb.
    await Directory(scanDirPath).create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = _getExtension(source.path);
    final newPath = '$scanDirPath/scan_$timestamp$ext';

    await source.saveTo(newPath); // XFile.saveTo — cross-platform
    return newPath;
  }

  String _getExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1 || lastDot == filePath.length - 1) return '.jpg';
    return filePath.substring(lastDot);
  }
}

// ── Value types ───────────────────────────────────────────────────────────────

/// Platform-agnostic image wrapper returned by [CameraService].
///
/// Backed entirely by [XFile] — no dart:io [File] involved.
/// Works on mobile, web, and desktop.
class PickedImage {
  /// The underlying cross-platform file reference.
  final XFile xFile;

  const PickedImage({required this.xFile});

  /// Path string (file path on mobile; blob URL on web).
  String get path => xFile.path;

  /// Filename with extension (e.g. `scan_1234567890.jpg`).
  String get name => xFile.name;

  /// Raw image bytes — works on all platforms via [XFile.readAsBytes].
  Future<List<int>> readAsBytes() => xFile.readAsBytes();

  /// Raw image bytes as a [Uint8List] — convenience wrapper.
  Future<Uint8List> readAsBytesTyped() async =>
      Uint8List.fromList(await xFile.readAsBytes());
}

/// Thrown by [CameraService] when the picker itself errors.
class CameraServiceException implements Exception {
  final String message;
  const CameraServiceException(this.message);

  @override
  String toString() => 'CameraServiceException: $message';
}
