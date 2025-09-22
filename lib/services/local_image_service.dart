import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/flashcard.dart';

class LocalImageService {
  static const String _imageMetadataKey = 'flashcard_images';
  static const String _imageDirectoryName = 'flashcard_images';

  /// Get the local directory for storing flashcard images
  static Future<Directory> _getImageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(appDir.path, _imageDirectoryName));

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  /// Generate a unique filename for a flashcard image
  static String _generateImageFilename(Flashcard card, String extension) {
    // Generate a consistent key based on card content
    final cardKey = card.translations['id'] ?? card.translations.values.first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${cardKey.hashCode.abs()}_$timestamp$extension';
  }

  /// Save an image file for a flashcard
  static Future<String?> saveCardImage(
    Flashcard card,
    String sourcePath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('Source image file does not exist: $sourcePath');
        return null;
      }

      final imageDir = await _getImageDirectory();
      final extension = path.extension(sourcePath).toLowerCase();
      final filename = _generateImageFilename(card, extension);
      final destinationPath = path.join(imageDir.path, filename);

      // Copy the image to our local directory
      await sourceFile.copy(destinationPath);

      // Save metadata
      await _saveImageMetadata(card, filename);

      print('Image saved successfully: $destinationPath');
      return destinationPath;
    } catch (e) {
      print('Error saving card image: $e');
      return null;
    }
  }

  /// Save image from bytes (useful for network images or camera)
  static Future<String?> saveCardImageFromBytes(
    Flashcard card,
    Uint8List imageBytes,
    String extension,
  ) async {
    try {
      final imageDir = await _getImageDirectory();
      final filename = _generateImageFilename(card, extension);
      final destinationPath = path.join(imageDir.path, filename);
      final file = File(destinationPath);

      await file.writeAsBytes(imageBytes);
      await _saveImageMetadata(card, filename);

      print('Image saved from bytes: $destinationPath');
      return destinationPath;
    } catch (e) {
      print('Error saving image from bytes: $e');
      return null;
    }
  }

  /// Get the local image path for a flashcard
  static Future<String?> getCardImagePath(Flashcard card) async {
    try {
      final metadata = await _getImageMetadata();
      final cardKey = _generateCardKey(card);
      final filename = metadata[cardKey];

      if (filename == null) return null;

      final imageDir = await _getImageDirectory();
      final imagePath = path.join(imageDir.path, filename);
      final file = File(imagePath);

      if (await file.exists()) {
        return imagePath;
      } else {
        // Clean up stale metadata
        await _removeImageMetadata(card);
        return null;
      }
    } catch (e) {
      print('Error getting card image path: $e');
      return null;
    }
  }

  /// Check if a flashcard has a local image
  static Future<bool> hasCardImage(Flashcard card) async {
    final imagePath = await getCardImagePath(card);
    return imagePath != null;
  }

  /// Delete a flashcard's image
  static Future<void> deleteCardImage(Flashcard card) async {
    try {
      final imagePath = await getCardImagePath(card);
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          print('Deleted image file: $imagePath');
        }
      }

      await _removeImageMetadata(card);
    } catch (e) {
      print('Error deleting card image: $e');
    }
  }

  /// Clean up orphaned images (images without corresponding metadata)
  static Future<void> cleanupOrphanedImages() async {
    try {
      final imageDir = await _getImageDirectory();
      final metadata = await _getImageMetadata();
      final metadataFilenames = Set<String>.from(metadata.values);

      await for (final entity in imageDir.list()) {
        if (entity is File) {
          final filename = path.basename(entity.path);
          if (!metadataFilenames.contains(filename)) {
            await entity.delete();
            print('Deleted orphaned image: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('Error cleaning up orphaned images: $e');
    }
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final imageDir = await _getImageDirectory();
      int fileCount = 0;
      int totalSize = 0;

      await for (final entity in imageDir.list()) {
        if (entity is File) {
          fileCount++;
          totalSize += await entity.length();
        }
      }

      return {
        'fileCount': fileCount,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting storage stats: $e');
      return {'fileCount': 0, 'totalSizeBytes': 0, 'totalSizeMB': '0.00'};
    }
  }

  /// Clear all stored images
  static Future<void> clearAllImages() async {
    try {
      final imageDir = await _getImageDirectory();
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }

      await _clearImageMetadata();
      print('Cleared all flashcard images');
    } catch (e) {
      print('Error clearing all images: $e');
    }
  }

  // Private helper methods

  static String _generateCardKey(Flashcard card) {
    return card.translations['id'] ?? card.translations.values.first;
  }

  static Future<void> _saveImageMetadata(
    Flashcard card,
    String filename,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadata = await _getImageMetadata();
      final cardKey = _generateCardKey(card);

      metadata[cardKey] = filename;
      await prefs.setString(_imageMetadataKey, json.encode(metadata));
    } catch (e) {
      print('Error saving image metadata: $e');
    }
  }

  static Future<Map<String, String>> _getImageMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_imageMetadataKey);

      if (metadataJson != null) {
        final Map<String, dynamic> decoded = json.decode(metadataJson);
        return decoded.cast<String, String>();
      }

      return <String, String>{};
    } catch (e) {
      print('Error getting image metadata: $e');
      return <String, String>{};
    }
  }

  static Future<void> _removeImageMetadata(Flashcard card) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadata = await _getImageMetadata();
      final cardKey = _generateCardKey(card);

      metadata.remove(cardKey);
      await prefs.setString(_imageMetadataKey, json.encode(metadata));
    } catch (e) {
      print('Error removing image metadata: $e');
    }
  }

  static Future<void> _clearImageMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_imageMetadataKey);
    } catch (e) {
      print('Error clearing image metadata: $e');
    }
  }
}
