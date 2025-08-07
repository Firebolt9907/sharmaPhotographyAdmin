import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sharma_photography_admin/enums.dart';
import 'package:sharma_photography_admin/githubService.dart';

uploadImage(
  String token,
  String pickedFilePath,
  String description,
  ImageType imageType,
) async {
  final github = GitHubService(
    token: token,
    owner: 'Firebolt9907',
    repo: 'sharmaPhotographyData',
  );

  Future<XFile?> testCompress(File file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      rotate: 0,
      format: CompressFormat.webp,
    );

    return result;
  }

  var webpImage = await testCompress(
    File(pickedFilePath),
    pickedFilePath.replaceAll('.jpg', '.webp'),
  );

  await github.uploadImageAndUpdateIndex(
    imageBytes: await File(pickedFilePath).readAsBytes(),
    webpImageBytes: await File(webpImage!.path).readAsBytes(),
    targetJPGPath: 'jpg/${pickedFilePath.split('/').last}',
    targetWEBPPath: 'webp/${webpImage.path.split('/').last}',
    jsonIndexPath: 'images.json',
    imageType: imageType,
    additionalMetadata: {'description': description},
  );
}
