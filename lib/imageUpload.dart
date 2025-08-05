

import 'dart:io';

import 'package:sharma_photography_admin/enums.dart';
import 'package:sharma_photography_admin/githubService.dart';

uploadImage(String token, String pickedFilePath, String description, ImageType imageType) async {
  final github = GitHubService(
    token: token,
    owner: 'Firebolt9907',
    repo: 'sharmaPhotography',
  );

  await github.uploadImageAndUpdateIndex(
    imageBytes: await File(pickedFilePath).readAsBytes(),
    targetImagePath: 'images/${pickedFilePath.split('/').last}',
    jsonIndexPath: 'data/images.json',
    imageType: imageType,
    additionalMetadata: {
      'description': description,
    },
  );
}