// FILE: lib/services/realtime_service.dart
// File ini berisi layanan untuk mendengarkan perubahan data secara realtime dari Supabase.
// Fungsi: Membuka channel Realtime pada tabel 'tempat' dan memantau event INSERT, UPDATE, DELETE.
//         Ketika ada perubahan data dari pengguna lain atau dari admin, aplikasi akan menerima notifikasi
//         dan dapat memperbarui tampilan secara otomatis (misalnya menambah marker baru di peta).
// Informasi penting: Hanya satu channel yang boleh aktif dalam satu waktu (static _isListening).
//         Menggunakan Supabase Realtime dengan event PostgresChanges.
//         Callback (onInsert, onUpdate, onDelete) diberikan dari luar (misalnya oleh TempatProvider).

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';

// Type definitions untuk callback (fungsi yang dipanggil saat ada event).
typedef OnNewTempat = void Function(TempatModel tempat);
typedef OnDeletedTempat = void Function(int id);
typedef OnUpdatedTempat = void Function(TempatModel tempat);

class RealtimeService {
  // Supabase client instance.
  static final _client = Supabase.instance.client;
  // Channel Realtime yang aktif (hanya satu).
  static RealtimeChannel? _channel;
  // Status apakah sedang mendengarkan.
  static bool _isListening = false;

  // Getter untuk status listening.
  static bool get isListening => _isListening;

  // Memulai mendengarkan event realtime pada tabel 'tempat'.
  // Parameter opsional: callback untuk insert, update, delete.
  static void startListening({
    OnNewTempat? onInsert,
    OnUpdatedTempat? onUpdate,
    OnDeletedTempat? onDelete,
  }) {
    // Jika sudah listening, jangan buat channel baru (log peringatan).
    if (_isListening) {
      ErrorLogger.w('RealtimeService already listening');
      return;
    }

    try {
      // Buat channel dengan nama 'public:tempat' (sesuai skema dan tabel).
      _channel = _client
          .channel('public:tempat')
          // Dengarkan event INSERT.
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConfig.tempatTable,
            callback: (payload) {
              // Log data baru.
              ErrorLogger.i('Realtime INSERT: ${payload.newRecord}');
              try {
                // Parse payload ke TempatModel.
                final tempat = TempatModel.fromJson(payload.newRecord);
                // Panggil callback jika ada.
                onInsert?.call(tempat);
              } catch (e) {
                ErrorLogger.e('Realtime INSERT parse failed', e);
              }
            },
          )
          // Dengarkan event UPDATE.
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: SupabaseConfig.tempatTable,
            callback: (payload) {
              // Log ID tempat yang diupdate.
              ErrorLogger.i('Realtime UPDATE: ${payload.newRecord['id']}');
              try {
                final tempat = TempatModel.fromJson(payload.newRecord);
                onUpdate?.call(tempat);
              } catch (e) {
                ErrorLogger.e('Realtime UPDATE parse failed', e);
              }
            },
          )
          // Dengarkan event DELETE.
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: SupabaseConfig.tempatTable,
            callback: (payload) {
              // Log ID tempat yang dihapus.
              ErrorLogger.i('Realtime DELETE: ${payload.oldRecord['id']}');
              try {
                final id = payload.oldRecord['id'] as int;
                onDelete?.call(id);
              } catch (e) {
                ErrorLogger.e('Realtime DELETE parse failed', e);
              }
            },
          )
          // Subscribe ke channel, dengan callback status dan error.
          .subscribe((status, error) {
            if (error != null) {
              ErrorLogger.e('Realtime subscribe error', error);
            } else {
              ErrorLogger.i('Realtime status: $status');
              // Set _isListening true jika status subscribed.
              _isListening = status == RealtimeSubscribeStatus.subscribed;
            }
          });

      ErrorLogger.i('RealtimeService started');
    } catch (e, stack) {
      ErrorLogger.e('RealtimeService.startListening failed', e, stack);
    }
  }

  // Menghentikan listening dan membuang channel.
  static Future<void> stopListening() async {
    if (_channel != null) {
      // Hapus channel dari client.
      await _client.removeChannel(_channel!);
      _channel = null;
      _isListening = false;
      ErrorLogger.i('RealtimeService stopped');
    }
  }
}