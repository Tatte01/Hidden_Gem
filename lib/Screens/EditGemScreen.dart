import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';



class EditScreen extends StatefulWidget {
  final String userId;
  final String idToken;
  final String? gemName;
  final String? description;
  final double? lat;
  final double? lng;
  final String? image;
  final int index;


  const EditScreen({
    super.key,
    required this.userId,
    required this.idToken,
    this.gemName,
    this.description,
    this.lat,
    this.lng,
    this.image,
    required this.index
    });

  @override
  State<EditScreen> createState() => _EditScreenPage();
}


class _EditScreenPage extends State<EditScreen> {
  final TextEditingController _gemName = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String? _imageUrl;
  bool private = false;
  bool _isSaving = false;
  String _errorMessage = '';
  String _successMessage = '';

  final String databaseUrl = dotenv.get('DATA_BASE_URL');
  Map<String, dynamic> gemData = {};

  @override
  void initState() {
    super.initState();
    _gemName.text = widget.gemName ?? "";
    _description.text = widget.description ?? "";

    _imageUrl = (widget.image?.isNotEmpty ?? false) ? widget.image : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          if (_gemName.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.upload),
              onPressed: _imagePicker,
            ),
        ],
        centerTitle: true,
        title: Text(widget.gemName?.isNotEmpty ?? false ? 'Edit ${widget.gemName!}' : 'Create New Gem'),
        ),
      body: Padding(
        padding : const EdgeInsets.all(20),
        child: Column(
          children: [
            (_imageUrl?.isNotEmpty ?? false)
              ? Container(
                  width: 200,
                  height: 200,
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : (widget.gemName?.isNotEmpty ?? false)
                  ? Text("This Gem Has no Picture")
                  : SizedBox.shrink(),
            const SizedBox(height: 20),
            TextField(
              controller: _gemName,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gem Name',
                icon: Icon(Icons.location_on),
                iconColor: Colors.lightBlue,
              )
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gem Description',
                icon: Icon(Icons.description),
                iconColor: Colors.lightBlue,
              )
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: private,
                    onChanged: (bool value) {
                      setState(() {
                        private = value;
                        print('Private $value');
                      });
                    },
                  ),
                  Text("Private? ", style: const TextStyle(fontWeight: FontWeight.bold))
                ],
              ),
            ),
            
            if (_successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save Gem'),
              ),
            ),
          ]
        )
      )
    );
  }


  Future<void> _saveGem() async {
    setState(() {
      _isSaving = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final bool nameChanged = widget.gemName != _gemName.text;
      String gemNameToUse = nameChanged ? _gemName.text : widget.gemName ?? "";
      
      final url = Uri.parse(
        '$databaseUrl/Users/${widget.userId}/Gems/$gemNameToUse.json?auth=${widget.idToken}'
      );

      final bool isNewGem = widget.gemName == null || widget.gemName!.isEmpty;

      if (nameChanged && !isNewGem) {
        await _renameGemWithPreservedData();
        return; 
      }

      final Map<String, dynamic> gemData = isNewGem ? {
        'Name': _gemName.text,
        'Decoration': _description.text,
        'Latitude': widget.lat,
        'Longitude': widget.lng,
        'Created': DateFormat("yyyy-MM-dd 'at' HH:mm:ss").format(DateTime.now()),
        'Image': _imageUrl,
        'Private': private,
      } : {
        'Name': _gemName.text,
        'Decoration': _description.text,
        'Latitude': widget.lat,
        'Longitude': widget.lng,
        'Image': _imageUrl,
        'Private': private,
      };

      final response = await (isNewGem ? http.put : http.patch)(
        url,
        body: json.encode(gemData),
        headers: {'Content-Type': 'application/json'},
      );

      _handleResponse(response);
    } catch (e) {
      _handleError('Error saving data: $e');
    }
  }

  Future<void> _renameGemWithPreservedData() async {
    try {
      // 1. Get the OLD gem data (to preserve Created date)
      final getUrl = Uri.parse(
        '$databaseUrl/Users/${widget.userId}/Gems/${widget.gemName}.json?auth=${widget.idToken}'
      );
      
      final getResponse = await http.get(getUrl);
      
      if (getResponse.statusCode != 200) {
        throw Exception('Failed to get old gem data');
      }

      final oldGemData = json.decode(getResponse.body);

      // 2. Create NEW gem with OLD data + updated fields
      final newUrl = Uri.parse(
        '$databaseUrl/Users/${widget.userId}/Gems/${_gemName.text}.json?auth=${widget.idToken}'
      );

      final Map<String, dynamic> newGemData = {
        ...oldGemData,
        'Name': _gemName.text,
        'Decoration': _description.text,
        'Latitude': widget.lat,
        'Longitude': widget.lng,
        'Image': _imageUrl,
        'Private': private,
      };

      // 3. Save the new gem
      final putResponse = await http.put(
        newUrl,
        body: json.encode(newGemData),
        headers: {'Content-Type': 'application/json'},
      );

      if (putResponse.statusCode != 200) {
        throw Exception('Failed to create new gem');
      }

      // 4. Delete the old gem
      final deleteUrl = Uri.parse(
        '$databaseUrl/Users/${widget.userId}/Gems/${widget.gemName}.json?auth=${widget.idToken}'
      );

      final deleteResponse = await http.delete(deleteUrl);
      
      if (deleteResponse.statusCode == 200) {
        print('Successfully renamed gem and preserved creation date');
        _handleSuccess();
      } else {
        print('Warning: New gem created but old gem not deleted');
        _handleSuccess();
      }

    } catch (e) {
      _handleError('Error renaming gem: $e');
    }
  }

  void _handleResponse(http.Response response) {
    print('Save response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      _handleSuccess();
    } else {
      _handleError('Failed to save data. Status code: ${response.statusCode}');
    }
  }

void _handleSuccess() {
  setState(() {
    _successMessage = 'Gem saved successfully!';
    _isSaving = false;
  });
  
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userId: widget.userId,
            idToken: widget.idToken,
            preindex: widget.index,
          ),
        ),
      );
    }
  });
}

void _handleError(String message) {
  setState(() {
    _errorMessage = message;
    _isSaving = false;
  });
}

  Future<void> _imagePicker() async {
    print('=== Starting image picker ===');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      print('Image picked: ${image?.path}');

      if (image != null) {
        print('Starting upload to Firebase Storage...');
        String uploadURL = await _uploadToFirebaseStorage(File(image.path));
        print('Upload completed. URL: $uploadURL');
        
        setState(() {
          _imageUrl = uploadURL;
        });
        print('_imageUrl updated in state');
      } else {
        print('No image selected');
      }
    } catch (e) {
      print(' Error in image picker: $e');
    }
  }

  Future<String> _uploadToFirebaseStorage(File imageFile) async {
    print('=== Starting Firebase upload ===');
    try {
      User? user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid}');
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      String fileName = 'GemPicture.jpg';
      String storagePath = '${user.uid}/${widget.gemName}/$fileName';
      
      print('Storage path: $storagePath');
      print('Gem name: ${widget.gemName}');
      print('File size: ${await imageFile.length()} bytes');

      Reference storageRef = FirebaseStorage.instance.ref();
      Reference fileRef = storageRef.child(storagePath);

      print('Starting file upload...');

      final metadata = SettableMetadata(
        customMetadata: {
          'authToken': widget.idToken,
        },
      );
      
      TaskSnapshot snapshot = await fileRef.putFile(imageFile, metadata);
      print('Upload completed. Bytes transferred: ${snapshot.bytesTransferred}');
      
      print('Getting download URL...');
      String downloadURL = await fileRef.getDownloadURL();
      print('Download URL obtained: $downloadURL');

      return downloadURL;
    } catch (e) {
      print('Error in _uploadToFirebaseStorage: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}



