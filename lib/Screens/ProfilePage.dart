import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/loginScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String idToken;
  
  const ProfileScreen({
    super.key, 
    required this.userId,
    required this.idToken
    });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _imageUrl;
  File? _selectedImage;
  Map<String, dynamic> gemData = {};


  bool _isSaving = false;
  String _errorMessage = '';
  String _successMessage = '';
  final String databaseUrl = dotenv.get('DATA_BASE_URL');

  Future<void> _loadUserData() async {
    try {
      final res = await http.get(
        Uri.parse('$databaseUrl/Users/${widget.userId}.json?auth=${widget.idToken}')
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _nameController.text = data['Name'] ?? '';
          _bioController.text = data['Bio'] ?? ''; 
          _email.text = data['Email'] ?? '';
          _imageUrl = data['ProfileImageUrl'];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final url = Uri.parse(
        '$databaseUrl/Users/${widget.userId}.json?auth=${widget.idToken}'
      );

      final userData = {
        'Name': _nameController.text,
        'Email': _email.text,
        'Bio': _bioController.text,
        'ProfileImageUrl': _imageUrl,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      print('Saving data for: $url');
      print('Data: $userData');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      print('Save response status: ${response.statusCode}');
      print('Save response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Profile saved successfully!';
          _isSaving = false;
        });
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = '';
            });
          }
        });

      } else {
        setState(() {
          _errorMessage = 'Failed to save data. Status code: ${response.statusCode}';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving data: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _imagePicker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if(image != null) {
      String uploadURL = await _uploadToFirebaseStorage(File(image.path));
      setState(() {
      _imageUrl = uploadURL;
    });
    _saveProfile();
    }
  }

  Future<String> _uploadToFirebaseStorage(File imageFile) async {

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    String fileName = 'profile.jpg';

    Reference storageRef = FirebaseStorage.instance.ref();
    
    await storageRef.child('profile_pictures/${user.uid}/$fileName').putFile(imageFile);
    String downloadURL = await storageRef.child('profile_pictures/${user.uid}/$fileName').getDownloadURL();
    return downloadURL;
  }

  Future<void> _loadGems() async {
    final url = Uri.parse('$databaseUrl/Users/${widget.userId}/Gems.json?auth=${widget.idToken}');
    final response = await http.get(url);

    print("Loading gems... Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("Found ${data.length} gems in database");

      setState(() {
        gemData = data;
      });
      print(gemData);
    } else {
      print("Failed to load gems: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Profile Page'),
        actions: [
          IconButton(
            icon:Icon(Icons.upload),
            onPressed: () => _imagePicker()
          ),
          IconButton(
          icon: Icon(Icons.logout, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Are you sure?'),
                content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'By Clicking OK you confirm sign out.'
                  ),
                  Text(
                    'Cancel to stay logged in'
                  )
                ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    }
                  )
                ]
              )
            );
          }
        ),
        ]
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child:SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(140),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 10,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    )
                  ]
                ),
                child: CircleAvatar( 
                  radius: 100,
                  backgroundColor: Colors.grey,
                  backgroundImage: _selectedImage != null 
                    ? FileImage(_selectedImage!) 
                    : _imageUrl != null 
                        ? NetworkImage(_imageUrl!) 
                        : null,
                  child: _imageUrl == null && _selectedImage == null
                      ? const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        )
                      : null, 
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  hintText: 'Name LastName "Malte Eriksson"',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: '"user@hotmail.com"',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bioController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell me about yourself',
                ),
              ),

              const SizedBox(height: 30),

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
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Profile'),
                  ),
                ),
            ],
          ),
        )
      ),
    );
  }

    @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}