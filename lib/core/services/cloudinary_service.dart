import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  
  static CloudinaryPublic get _cloudinary => CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  /// Upload une image vers Cloudinary
  static Future<String> uploadImage(String filePath, String folder) async {
    try {
      print('[UPLOAD] Upload Image Cloudinary: $filePath vers $folder');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier introuvable: $filePath');
      }

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception('Délai dépassé pour l\'upload image.'),
      );

      return response.secureUrl;
    } catch (e) {
      print('[ERROR] Erreur upload Image Cloudinary: $e');
      throw Exception('Erreur upload image: $e');
    }
  }

  /// Upload un fichier audio vers Cloudinary
  static Future<String> uploadAudio(String filePath, String folder) async {
    try {
      print('[UPLOAD] Upload Audio Cloudinary: $filePath vers $folder');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier audio introuvable: $filePath');
      }

      // Upload vers Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Video, // Utiliser Video pour l'audio
        ),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception('Délai dépassé pour l\'upload audio.'),
      );

      final url = response.secureUrl;
      print('[SUCCESS] Upload Audio réussi: $url');
      
      return url;
    } catch (e) {
      print('[ERROR] Erreur upload Audio Cloudinary: $e');
      throw Exception('Erreur upload audio: $e');
    }
  }

  /// Upload plusieurs images
  static Future<List<String>> uploadMultipleImages(
    List<String> filePaths,
    String folder,
  ) async {
    final List<String> urls = [];
    
    for (int i = 0; i < filePaths.length; i++) {
      final url = await uploadImage(filePaths[i], folder);
      urls.add(url);
    }
    
    return urls;
  }
}
