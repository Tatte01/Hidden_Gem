import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/loginScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'SingleGemScreen.dart';
import 'FriendsGemsScreen.dart';

class FriendsProfile extends StatefulWidget {
  final String userId;
  final String idToken;
  final String myId;
  
  const FriendsProfile({
    super.key, 
    required this.userId,
    required this.idToken,
    required this.myId,
    });

  @override
  State<FriendsProfile> createState() => _FriendsProfileState();
}

class _FriendsProfileState extends State<FriendsProfile> {
  final TextEditingController _nameController = TextEditingController();
    final TextEditingController _email = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _imageUrl;

  final String databaseUrl = dotenv.get('DATA_BASE_URL');
  
  Map<String, dynamic> gemData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGems();
  }

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

  void _loadGems() async {
    final url = Uri.parse('$databaseUrl/Users/${widget.userId}/Gems.json?auth=${widget.idToken}');
    final response = await http.get(url);

    print("Loading gems... Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
    final Map<String, dynamic> filteredData = {};
    for (final entry in data.entries) {
      final gemKey = entry.key;
      final gemData = entry.value;
      
      // Check if gem is public
      if (gemData is Map) {
        final isPrivate = gemData['Private'] == true;
        if (!isPrivate) {
          filteredData[gemKey] = gemData;
        }
      }
    }
      print("Found ${data.length} gems in database but only ${filteredData.length} Public");
      setState(() {
        gemData = filteredData;
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
        title: Text('${_nameController.text} Profile'),
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
                  backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!) 
                      : null,

                  child: _imageUrl == null || _imageUrl!.isEmpty
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
                readOnly: true,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  hintText: 'Name LastName "Malte Eriksson"',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                readOnly: true,
                controller: _bioController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell me about yourself',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Divider(thickness: 3)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Gems'),
                    ),
                    Expanded(child: Divider(thickness: 3)),
                  ],
                ),
              ),

              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                itemCount: gemData.length,
                itemBuilder: (context, index) {
                  String key = gemData.keys.elementAt(index);
                  var item = gemData[key];
                  
                  return Card(
                    color: Colors.grey[350],
                    elevation: 10,
                    margin: const EdgeInsets.fromLTRB(20, 10, 20 ,10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item['Name'] ?? 'No Name'}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                            icon: const Icon(Icons.fullscreen),
                            iconSize: 20,
                            color: Colors.black,
                            onPressed: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendsGemScreen(
                                    userId: widget.userId,
                                    idToken: widget.idToken,
                                    gemName: item['Name'],
                                    description: item['Decoration'],
                                    myId: widget.myId,
                                    image: item['Image'],
                                  ),
                                ),
                              )
                            },
                          ),
                        ],
                      ),
                      Column(
                        children : [
                          const SizedBox(height: 8),
                          (item['Image']?.isNotEmpty ?? false)
                            ? Container(
                                width: 200,
                                height: 200,
                                child: Image.network(
                                  item['Image']!,
                                  fit: BoxFit.cover,
                                ),
                          ) : Text("This gem does not have a Image"),
                          Text(' Description: ${item['Decoration']}'),
                        ])
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      )
    ),
  );
}
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}