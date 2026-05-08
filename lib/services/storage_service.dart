// lib/services/storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../utils/error_logger.dart';

class StorageService {
  static final _client = Supabase.instance.client;
  static const _uuid = Uuid();

  static Future<String?> uploadTempatImage(File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$ext';

      await _client.storage
          .from(SupabaseConfig.tempatImagesBucket)
          .upload(fileName, imageFile, fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: false,
          ));

      ErrorLogger.i('Image uploaded: $fileName');
      return fileName;
    } catch (e, stack) {
      ErrorLogger.e('uploadTempatImage failed', e, stack);
      return null;
    }
  }

  static Future<bool> deleteTempatImage(String fileName) async {
    try {
      await _client.storage
          .from(SupabaseConfig.tempatImagesBucket)
          .remove([fileName]);
      return true;
    } catch (e, stack) {
      ErrorLogger.e('deleteTempatImage failed', e, stack);
      return false;
    }
  }

  static String getTempatImageUrl(String fileName) {
    return _client.storage
        .from(SupabaseConfig.tempatImagesBucket)
        .getPublicUrl(fileName);
  }

  static Future<List<String>> listTempatImages() async {
    try {
      final files = await _client.storage
          .from(SupabaseConfig.tempatImagesBucket)
          .list();
      return files.map((f) => f.name).toList();
    } catch (e, stack) {
      ErrorLogger.e('listTempatImages failed', e, stack);
      return [];
    }
  }
}