import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _client = Supabase.instance.client;

  Future<String> uploadImage(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ext = p.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$ext';
    final filePath = '${user.id}/$fileName';

    await _client.storage.from('item-images').upload(filePath, File(file.path));

    return _client.storage.from('item-images').getPublicUrl(filePath);
  }
}
