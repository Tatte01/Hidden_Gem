import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';


class FriendsGemScreen extends StatefulWidget {
final String userId;
final String idToken;
final String gemName;
final String description;
final String myId;
final String? image;

const FriendsGemScreen({
  super.key,
  required this.userId,
  required this.idToken,
  required this.gemName,
  required this.description,
  required this.myId,
  this.image,

});

  @override
  State<FriendsGemScreen> createState() => _FriendsGemScreenState();
}

class _FriendsGemScreenState extends State<FriendsGemScreen> {
  bool _liked = false;
  int _amount = 0;
  final String databaseUrl = dotenv.get('DATA_BASE_URL');

  @override
  void initState() {
    super.initState();
    _loadLikes();
    print('My own user id ${widget.myId}');
    print('My Friends user id ${widget.userId}');
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
        _liked = likesMap.containsKey(widget.myId);
      });
      
      print('Total likes: $_amount, I liked it: $_liked');
    }
  } catch (e) {
    print('Error loading likes: $e');
  }
}


  Future<void> likeGem() async {
    try {
      final url = Uri.parse('$databaseUrl/Users/${widget.userId}/Gems/${widget.gemName}/Likes/${widget.myId}.json?auth=${widget.idToken}');
      
      final res = await http.put(
        url,
        body: json.encode(true),
      );

      if (res.statusCode == 200) {
        print('Successfully liked the gem');
        setState(() {
          _liked = true;
          _loadLikes();
        });
      } else {
        print('Failed to like gem: ${res.statusCode}');
      }
    } catch (e) {
      print('Error liking gem: $e');
    }
  }

  Future<void> unlikeGem() async {
    try {
      final url = Uri.parse('$databaseUrl/Users/${widget.userId}/Gems/${widget.gemName}/Likes/${widget.myId}.json?auth=${widget.idToken}');
      
      final res = await http.delete(url);

      if (res.statusCode == 200) {
        print('Successfully unliked the gem');
        setState(() {
          _liked = false;
          _loadLikes();
        });
      } else {
        print('Failed to unlike gem: ${res.statusCode}');
      }
    } catch (e) {
      print('Error unliking gem: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${widget.gemName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
          child: Column(
          children: [
            (widget.image?.isNotEmpty ?? false)
              ? Container(
                width: 200,
                height: 200,
                child: Image.network(
                  widget.image!,
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
                Text (' $_amount Likes'),
                IconButton(
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    if (_liked == true) {
                      unlikeGem();
                    } else {
                      likeGem();
                    }
                  },
                )
              ]
            ),
          ]
        ),        
      ),
    );
  }
}