// this was created by gemini
// i didnt want to deal with base64 and sha hashes

import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sharma_photography_admin/enums.dart'; // For path manipulation

class GitHubService {
  final String _token;
  final String _owner;
  final String _repo;

  GitHubService({
    required String token,
    required String owner,
    required String repo,
  }) : _token = token,
       _owner = owner,
       _repo = repo;

  Uri _apiUrl(String path) =>
      Uri.parse('https://api.github.com/repos/$_owner/$_repo/contents/$path');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/vnd.github.v3+json',
  };

  /// Orchestrates the entire process: uploads an image, then updates a JSON index file.
  ///
  /// - [imageBytes]: The raw bytes of the image file to upload.
  /// - [targetImagePath]: The full path where the image will be saved in the repo (e.g., 'assets/images/new_image.jpg').
  /// - [jsonIndexPath]: The path to the JSON index file (e.g., 'data/images.json').
  /// - [additionalMetadata]: Optional map of other data to include in the JSON record.
  Future<void> uploadImageAndUpdateIndex({
    required Uint8List imageBytes,
    required String targetImagePath,
    required String jsonIndexPath,
    Map<String, dynamic> additionalMetadata = const {},
    required ImageType imageType,
  }) async {
    // STEP 1: Upload the image file
    print("Step 1: Uploading image to $targetImagePath...");
    final String commitMessage = 'Added image ${p.basename(targetImagePath)}';
    final uploadResponse = await _uploadFile(
      path: targetImagePath,
      contentBytes: imageBytes,
      commitMessage: commitMessage,
    );

    final String downloadUrl = uploadResponse['content']['download_url'];
    print("Image uploaded successfully. URL: $downloadUrl");

    // STEP 2: Prepare the metadata and update the JSON index
    print("Step 2: Updating JSON index at $jsonIndexPath...");
    final Map<String, dynamic> newImageData = {
      'fileName': p.basename(targetImagePath),
      'url': downloadUrl,
      'uploadedAt': DateTime.now().toIso8601String(),
      'imageType': imageType
          .toString()
          .split('.')
          .last, // Convert enum to string
      ...additionalMetadata, // Merge any extra data
    };

    await _appendToJsoNArray(
      path: jsonIndexPath,
      newItem: newImageData,
      commitMessage: 'Updated image index for ${p.basename(targetImagePath)}',
    );

    print("Process complete! Image uploaded and index updated.");
  }

  /// Private helper to upload a file (binary content).
  /// Returns the decoded JSON response from GitHub on success.
  Future<Map<String, dynamic>> _uploadFile({
    required String path,
    required Uint8List contentBytes,
    required String commitMessage,
  }) async {
    final String contentBase64 = base64Encode(contentBytes);

    final body = json.encode({
      'message': commitMessage,
      'content': contentBase64,
    });

    final response = await http.put(
      _apiUrl(path),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 201) {
      // 201 for Created
      return json.decode(response.body);
    } else if (response.statusCode == 422) {
      print("file already exists, cancelling upload");
      return json.decode(response.body); // Return the error response as is
    } else {
      throw Exception(
        'Failed to upload file "$path": ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Private helper to download, modify, and re-upload a JSON file.
  Future<void> _appendToJsoNArray({
    required String path,
    required Map<String, dynamic> newItem,
    required String commitMessage,
    String jsonArrayKey = 'images',
  }) async {
    String? currentSha;
    Map<String, dynamic> jsonData;

    final getResponse = await http.get(_apiUrl(path), headers: _headers);

    if (getResponse.statusCode == 200) {
      final responseBody = json.decode(getResponse.body);
      currentSha = responseBody['sha'];
      print(responseBody);
      print(responseBody['content']);
      final contentString = utf8.decode(
        base64Decode(responseBody['content'].replaceAll(RegExp(r'\s+'), '')),
      );
      jsonData = json.decode(contentString);
    } else if (getResponse.statusCode == 404) {
      jsonData = {jsonArrayKey: []};
    } else {
      throw Exception(
        'Failed to get JSON file: ${getResponse.statusCode} ${getResponse.body}',
      );
    }

    if (jsonData[jsonArrayKey] is! List) {
      jsonData[jsonArrayKey] = [];
    }
    final List<dynamic> dataList = jsonData[jsonArrayKey];
    dataList.insert(0, newItem);

    final updatedContentString = json.encode(jsonData);
    final updatedContentBase64 = base64Encode(
      utf8.encode(updatedContentString),
    );

    final requestBody = json.encode({
      'message': commitMessage,
      'content': updatedContentBase64,
      if (currentSha != null) 'sha': currentSha,
    });

    final putResponse = await http.put(
      _apiUrl(path),
      headers: _headers,
      body: requestBody,
    );

    if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
      throw Exception(
        'Failed to update JSON file: ${putResponse.statusCode} ${putResponse.body}',
      );
    }
  }
}
