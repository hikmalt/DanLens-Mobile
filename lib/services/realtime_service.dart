// lib/services/realtime_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../utils/error_logger.dart';

typedef OnNewTempat = void Function(TempatModel tempat);
typedef OnDeletedTempat = void Function(int id);
typedef OnUpdatedTempat = void Function(TempatModel tempat);

class RealtimeService {
  static final _client = Supabase.instance.client;
  static RealtimeChannel? _channel;
  static bool _isListening = false;

  static bool get isListening => _isListening;

  /// Start listening to realtime changes on the tempat table
  static void startListening({
    OnNewTempat? onInsert,
    OnUpdatedTempat? onUpdate,
    OnDeletedTempat? onDelete,
  }) {
    if (_isListening) {
      ErrorLogger.w('RealtimeService already listening');
      return;
    }

    try {
      _channel = _client
          .channel('public:tempat')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConfig.tempatTable,
            callback: (payload) {
              ErrorLogger.i('Realtime INSERT: ${payload.newRecord}');
              try {
                final tempat = TempatModel.fromJson(payload.newRecord);
                onInsert?.call(tempat);
              } catch (e) {
                ErrorLogger.e('Realtime INSERT parse failed', e);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: SupabaseConfig.tempatTable,
            callback: (payload) {
              ErrorLogger.i('Realtime UPDATE: ${payload.newRecord['id']}');
              try {
                final tempat = TempatModel.fromJson(payload.newRecord);
                onUpdate?.call(tempat);
              } catch (e) {
                ErrorLogger.e('Realtime UPDATE parse failed', e);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: SupabaseConfig.tempatTable,
            callback: (payload) {
              ErrorLogger.i('Realtime DELETE: ${payload.oldRecord['id']}');
              try {
                final id = payload.oldRecord['id'] as int;
                onDelete?.call(id);
              } catch (e) {
                ErrorLogger.e('Realtime DELETE parse failed', e);
              }
            },
          )
          .subscribe((status, error) {
            if (error != null) {
              ErrorLogger.e('Realtime subscribe error', error);
            } else {
              ErrorLogger.i('Realtime status: $status');
              _isListening = status == RealtimeSubscribeStatus.subscribed;
            }
          });

      ErrorLogger.i('RealtimeService started');
    } catch (e, stack) {
      ErrorLogger.e('RealtimeService.startListening failed', e, stack);
    }
  }

  static Future<void> stopListening() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
      _isListening = false;
      ErrorLogger.i('RealtimeService stopped');
    }
  }
}