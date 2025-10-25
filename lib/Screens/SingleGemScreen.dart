import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../homepage.dart';
import 'EditGemScreen.dart';
import 'dart:convert';

class SingleGemScreen extends StatefulWidget {
final String userId;
final String idToken;
final String gemName;
final String description;
final double lat;
final double lng;
final int index;
final String? image;

const SingleGemScreen({
  super.key,
  required this.userId,
  required this.idToken,
  required this.gemName,
  required this.description,
  required this.lat,
  required this.lng,
  required this.index,
  this.image,
});

  @override
  State<SingleGemScreen> createState() => _SingleGemScreenState();
}

class _SingleGemScreenState extends State<SingleGemScreen> {
  String? _imageUrl;
  int _amount = 0;

  final String databaseUrl = dotenv.get('DATA_BASE_URL');

  Future<void> _deleteGem(String gemName) async {
    final String databaseUrl = dotenv.get('DATA_BASE_URL');

    final http.Response response = await http.delete(
      Uri.parse('$databaseUrl/Users/${widget.userId}/Gems/$gemName.json?auth=${widget.idToken}'),
    );
    if (response.statusCode == 200) {
      print('Gem $gemName Deleted Successfully');
    } else {
      print('Failed to delete Gem. ${response.body}');
    }
  }

  Future<void> _loadLikes() async {
  try {
    final res = await http.get(
      Uri.parse('$databaseUrl/Users/${widget.userId}/Gems/${widget.gemName}.json?auth=${widget.idToken}')
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final likesMap = data['Likes'] is Map ? data['Likes'] as Map : {};
      
      setState(() {
        _amount = likesMap.length;
      });
      
      print('Total likes: $_amount');
    }
  } catch (e) {
    print('Error loading likes: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${widget.gemName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditScreen(
                  userId: widget.userId,
                  idToken: widget.idToken,
                  gemName: widget.gemName,
                  description: widget.description,
                  lat: widget.lat,
                  lng: widget.lng,
                  image: widget.image,
                  index: widget.index,
                  ),
                ),
              )
            }
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            iconSize: 20,
            color: Colors.red,
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Are you sure?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Do you really want to delete Gem ${widget.gemName}',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Yes'),
                      onPressed: () async {
                        await _deleteGem(widget.gemName);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              userId: widget.userId,
                              idToken: widget.idToken,
                              preindex: widget.index,
                            )
                          )
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
              : Text("This gem does not have a Image"),
            const SizedBox(height: 25),
            Text(
              'Description: \n ${widget.description}',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: Divider(thickness: 5,)),
              ],
            ),
            Row(
              children: [
                Text (' $_amount Likes'),
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                  onPressed: () {},
                )
              ]
            ),
          ]
        ),
      ),
    );
  }
}