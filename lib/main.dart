// CECS 327
// Kayla Ma, Daryl Nguyen, Tony Guirguis
//Project 2 - File Sharing App

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mdb;
import 'constant.dart';

void main() {
  runApp(MyApp());
}

//created to set up structure of the app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
      scaffoldBackgroundColor: Color.fromARGB(255, 218, 166, 210)),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

//User Interface with uploading and displaying files features
class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> files = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //create title and descriptions to show ontop of the app
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 218, 166, 210),
        title: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('File Sharing System w/ MongoDB and Flutter', style: TextStyle(fontSize: 30)),
          Text('By: Kayla Ma, Daryl Nguyen, & Tony Guirguis', style: TextStyle(fontSize: 13)),
        ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //add file image above the buttons
            Image.asset("images/file_icon.png",
            height: 200,
            width: 200,),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () async {
                await uploadFileToDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, // Customize the button color
              ),
              child: Text(
                'Upload File',
                style: TextStyle(color: Colors.white), // Customize the text color
              ),
            ),
            SizedBox(height: 30),
             ElevatedButton(
              onPressed: () async {
                await showFileList();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, // Customize the button color
              ),
              child: Text(
                'Show Files',
                style: TextStyle(color: Colors.white), // Customize the text color
              ),
            ),
            SizedBox(height: 20),
            if (files.isNotEmpty)
              Column(
                children: files
                    .map(
                      (file) => ListTile(
                            title: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black), // Customize the border color
                              ),
                              child: Center(
                                child: Text(file['filename']),
                              ),
                            ),
                        onTap: () {
                          // Handle file tap, display file content
                          displayContent(context, file['filename'], List<int>.from(file['data']));
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

Future<void> uploadFileToDatabase() async {
  // Connect to MongoDB
  var db = await mdb.Db.create(MONGO_URL);
  var collection = db.collection(COLLECTION_NAME);
  await db.open();

  try {
    // this method allows you to choose a file from your device
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    //if the file doesn't equal null then the file is uploaded to the database
    if (result != null) {
      PlatformFile resultFile = result.files.first;
      File file = File(resultFile.path!);
      List<int> fileBytes = file.readAsBytesSync();
      print(file);

      // Check if file bytes are not null
      if (fileBytes != null) {
        // Create a new document in the collection and insert the file data
        await collection.insertOne({'filename': resultFile.name, 'data': fileBytes});
        print('File uploaded successfully!');
      } else {
        print('Failed to read file bytes.');
      }
    } else {
      print('No file selected.');
    }
  } finally {
    // Close the database connection
    await db.close();
  }
}

  Future<void> showFileList() async {
    // Connect to MongoDB
    var db = await mdb.Db.create(MONGO_URL);
    await db.open();
    var collection = db.collection(COLLECTION_NAME);

    try {
      // Retrieve files from the database
      files = await collection.find().toList();
    } finally {
      // Close the database connection
      await db.close();
    }

    // Update the UI with the refreshed file list
    setState(() {});
  }
}

Future<void> displayContent(BuildContext context, String filename, List<int> fileData) async {
  String content;

  // Check file type (only text and image files)
  if (filename.endsWith('.txt')) {
    //display text if file is .txt
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$filename:'),
          content: SingleChildScrollView(
            child: Text(utf8.decode(fileData)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  } else if (filename.endsWith('.jpg') || filename.endsWith('.png')) {
    // If it's an image file, display the image
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$filename:'),
          content: SingleChildScrollView(
            child: Image.memory(Uint8List.fromList(fileData)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  } else {
    // Handle other file types accordingly
    print('Unsupported file type: $filename');
  }
}

