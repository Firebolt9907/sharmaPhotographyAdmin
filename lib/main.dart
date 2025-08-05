import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sharma_photography_admin/enums.dart';
import 'package:sharma_photography_admin/imageUpload.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var descController = TextEditingController();
  var tokenController = TextEditingController();
  var pickedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Add New Photo or Painting"),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            TextField(
              controller: tokenController,
              decoration: InputDecoration(labelText: "Github Token"),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  var location = await getLocation(pickedFile.path);
                  print("Location: $location");
                  setState(() {});
                }
              },
              child: Text("Select Image"),
            ),
            pickedFile != null
                ? Image.asset(
                    pickedFile.path,
                    width: MediaQuery.sizeOf(context).width - 20,
                    height: MediaQuery.sizeOf(context).width - 20,
                  )
                : Container(),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            ElevatedButton(
              onPressed: () {
                uploadImage(
                  tokenController.text,
                  pickedFile.path,
                  descController.text,
                  ImageType.photo,
                );
              },
              child: Text("Add new Photo"),
            ),
            ElevatedButton(
              onPressed: () {
                uploadImage(
                  tokenController.text,
                  pickedFile.path,
                  descController.text,
                  ImageType.painting,
                );
              },
              child: Text("Add new Painting"),
            ),
          ],
        ),
      ),
    );
  }
}

getLocation(String imagePath) async {
  final bytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null || image.exif.gpsIfd.data.isEmpty) {
    throw Exception("No GPS data found in image");
  }
  var longitude = latLonDecode(image.exif.gpsIfd.data[4]);
  var latitude = latLonDecode(image.exif.gpsIfd.data[2]);
  print(
    "https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1",
  );
  http
      .get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1',
        ),
      )
      .then((response) {
        if (response.statusCode == 200) {
          print("city: ${response.body}");
        } else {
          print(response.body);
          print(response.statusCode);
          print('Failed to get location');
        }
      });
  return "No location found";
}

latLonDecode(var longitudeOrLatitude) {
  var str = longitudeOrLatitude.toString();
  str = str.replaceAll("/1,", ",");
  var degrees = double.parse(str.split(", ")[0].replaceAll("[", ""));
  var minutes = double.parse(str.split(", ")[1]);
  var seconds = double.parse(str.split(", ")[2].replaceAll("/100]", "")) / 100;
  return (degrees + (minutes / 60) + (seconds / 3600)).toStringAsFixed(8);
}
