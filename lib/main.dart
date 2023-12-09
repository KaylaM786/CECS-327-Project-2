import 'dart:convert'; 
import 'dart:io';
import 'dart:typed_data'; 
import 'package:file_sharing_app/constant.dart';
import 'package:flutter/material.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'package:mongo_dart/mongo_dart.dart' show Db, GridFS; 
  
void main() => runApp(MyApp()); 
  
class MyApp extends StatelessWidget { 
  
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'File Sharing System', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData( 
        primarySwatch: Colors.green, 
      ), 
      home: MyHomePage(title: 'Share Images'), 
    ); 
  } 
} 
  
class MyHomePage extends StatefulWidget { 
  MyHomePage({Key? key, required this.title}) : super(key: key); 
  
  
  final String title; 
  
  @override 
  _MyHomePageState createState() => _MyHomePageState(); 
} 
  
class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{ 

  
  final picker = ImagePicker(); 
  late File _image; 
  late GridFS bucket; 
  late AnimationController _animationController; 
  late Animation<Color> _colorTween; 
  late ImageProvider provider = MemoryImage(Uint8List(0)); 
  var flag = false; 
    
  @override 
  void initState() { 
  
    _animationController = AnimationController( 
      duration: Duration(milliseconds: 1800), 
      vsync: this, 
    ); 
    _colorTween = _animationController.drive(Tween(begin: Colors.purple,end: Colors.white,)); 
    _animationController.repeat(); 
    super.initState(); 
    connection(); 
  } 
  
  Future getImage() async{ 
    
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); 
  
    if(pickedFile!=null){ 
  
      var _cmpressed_image; 
      try { 
        _cmpressed_image = await FlutterImageCompress.compressWithFile( 
            pickedFile.path, 
            format: CompressFormat.heic, 
            quality: 70 
        ); 
      } catch (e) { 
  
        _cmpressed_image = await FlutterImageCompress.compressWithFile( 
            pickedFile.path, 
            format: CompressFormat.jpeg, 
            quality: 70 
        ); 
      } 
      setState(() { 
        flag = true; 
      }); 
  
      Map<String,dynamic> ?image = { 
        "_id" : pickedFile.path.split("/").last, 
        "data": base64Encode(_cmpressed_image) 
      }; 

      var res = await bucket.chunks.insert(image); 
      var img = await bucket.chunks.findOne({ 
        "_id": pickedFile.path.split("/").last 
      }); 

      setState(() { 
        provider = MemoryImage(base64Decode(img!["data"])); 
        flag = false; 
      }); 
    } 
  } 
    
  @override 
  Widget build(BuildContext context) { 
  
    return Scaffold( 
      appBar: AppBar( 
        title: Text(widget.title), 
        backgroundColor: Colors.green, 
      ), 
      body: SingleChildScrollView( 
        child: Center( 
          child:  Column( 
            children: [ 
              SizedBox( 
                height: 20, 
              ), 
              provider == null ? Text('No image selected.') : Image(image: provider,), 
              SizedBox(height: 10,), 
              if(flag==true) 
                CircularProgressIndicator(valueColor: _colorTween), 
                SizedBox(height: 20,),
                ElevatedButton( 
                onPressed: getImage, 
                child: Container( 
                  decoration: BoxDecoration( 
                    gradient: LinearGradient( 
                      colors: <Color>[ 
                        Colors.green, 
                        Color.fromARGB(255, 103, 58, 159), 
                        Color.fromARGB(255, 67, 120, 199), 
                      ], 
                    ), 
                  ), 
                  padding: const EdgeInsets.all(10.0), 
                  child: const Text( 
                      'Select Image', 
                      style: TextStyle(fontSize: 20) 
                  ), 
                ), 
  
              ), 
            ], 
          ), 
        ) 
      ) 
  
    ); 
  } 
  
  Future connection () async{ 
    var db = await Db.create(MONGO_URL);
    await db.open(secure: true); 
    bucket = GridFS(db,COLLECTION_NAME); 
  } 
} 
