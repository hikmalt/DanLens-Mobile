// C:\Users\hikma\Desktop\DanLens\danlens\lib\services\tempat_service.dart
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/error_logger.dart';

class TempatService {
  /// Get all places with optional filter & search
  static Future<List<TempatModel>> getAll({
    int? kategoriId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await SupabaseService.getAllTempat(
        kategoriId: kategoriId,
        search: search,
        limit: limit,
        offset: offset,
      );
    } catch (e, stack) {
      ErrorLogger.e('TempatService.getAll failed', e, stack);
      return [];
    }
  }

  /// Get random images for carousel
  static Future<List<TempatModel>> getRandom({int limit = 8}) async {
    return await SupabaseService.getRandomTempat(limit: limit);
  }

  /// Get single place by ID
  static Future<TempatModel?> getById(int id) async {
    return await SupabaseService.getTempatById(id);
  }

  /// Insert new place
  static Future<TempatModel?> insert(Map<String, dynamic> data) async {
    return await SupabaseService.insertTempat(data);
  }

  /// Update existing place
  static Future<bool> update(int id, Map<String, dynamic> data) async {
    return await SupabaseService.updateTempat(id, data);
  }

  /// Delete place
  static Future<bool> delete(int id) async {
    return await SupabaseService.deleteTempat(id);
  }

  /// Get nearby places (using Haversine)
  static Future<List<TempatModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    return await SupabaseService.getNearby(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }

  /// Get top rated places (manual sorting)
  static Future<List<TempatModel>> getTopRated({
    int limit = 10,
  }) async {
    final all = await getAll(limit: 100);
    all.sort((a, b) => (b.reviewRating ?? 0).compareTo(a.reviewRating ?? 0));
    return all.take(limit).toList();
  }

  /// Get places by category with search
  static Future<List<TempatModel>> getByCategory(int kategoriId) async {
    return await getAll(kategoriId: kategoriId);
  }

  /// Search places by name or address
  static Future<List<TempatModel>> search(String query) async {
    return await getAll(search: query);
  }

  /// Get recently viewed (via TempatProvider)
  // This is handled in TempatProvider, but we could add a local cache version here
}