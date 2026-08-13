import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple Cloudinary upload helper (unsigned preset).
///
/// `cloudName` and `uploadPreset` should be set to your Cloudinary account values.
/// Returns the secure URL of the uploaded image.
Future<String> uploadToCloudinary({
  required File file,
  required String cloudName,
  required String uploadPreset,
}) async {
  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath('file', file.path));

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  if (response.statusCode != 200) {
    throw Exception('Cloudinary upload failed: ${response.statusCode} ${response.body}');
  }
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data['secure_url'] as String;
}
