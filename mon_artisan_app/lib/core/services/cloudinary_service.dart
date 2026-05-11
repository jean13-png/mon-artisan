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
  /// 
  /// [filePath] : Chemin local du fichier
  /// [folder] : Dossier dans Cloudinary (ex: 'artisans/userId/diplome')
  /// 
  /// Retourne l'URL publique de l'image uploadée
  static Future<String> uploadImage(String filePath, String folder) async {
    try {
      print('[UPLOAD] Upload Cloudinary: $filePath vers $folder');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier introuvable: $filePath');
      }

      // Upload vers Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final url = response.secureUrl;
      print('[SUCCESS] Upload réussi: $url');
      
      return url;
    } catch (e) {
      print('[ERROR] Erreur upload Cloudinary: $e');
      throw Exception('Erreur upload: $e');
    }
  }

  /// Upload plusieurs images
  static Future<List<String>> uploadMultipleImages(
    List<String> filePaths,
    String folder,
  ) async {
    final List<String> urls = [];
    
    for (int i = 0; i < filePaths.length; i++) {
      print('[UPLOAD] Upload ${i + 1}/${filePaths.length}');
      final url = await uploadImage(filePaths[i], folder);
      urls.add(url);
    }
    
    return urls;
  }

  /// Note: La suppression d'images nécessite l'API Admin de Cloudinary
  /// qui n'est pas disponible dans cloudinary_public (client-side only)
  /// Pour supprimer des images, utilisez l'API Admin depuis un backend
}
