import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
            ElevatedButton(
              onPressed: () async {
                pickedFile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
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
            ElevatedButton(onPressed: () {}, child: Text("Add new Photo")),
            ElevatedButton(onPressed: () {}, child: Text("Add new Painting")),
          ],
        ),
      ),
    );
  }
}

