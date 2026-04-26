import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brain_anchor/services/supabase_config.dart';

class StorageService {
  final _supabase = SupabaseConfig.client;

  /// Uploads a file to Supabase Storage, saves metadata, and returns the public URL.
  Future<String?> uploadProviderDocument({
    required String providerId,
    required File file,
  }) async {
    try {
      // In a real device, you might use path separator based on platform. 
      // For cross-platform fallback:
      final fallbackName = file.path.split(Platform.pathSeparator).last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$fallbackName';
      final storagePath = '$providerId/$fileName';

      // 1. Upload to storage bucket named 'provider_documents'
      await _supabase.storage.from('provider_documents').upload(
            storagePath,
            file,
          );

      // 2. Get public URL
      final publicUrl = _supabase.storage
          .from('provider_documents')
          .getPublicUrl(storagePath);

      // 3. Insert metadata into provider_documents table
      await _supabase.from('provider_documents').insert({
        'provider_id': providerId,
        'file_name': fileName,
        'storage_path': storagePath,
      });

      return publicUrl;
    } catch (e) {
      // Handle or log error
      return null;
    }
  }
}
