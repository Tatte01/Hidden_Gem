import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'FriendsProfile.dart';


class FriendsScreen extends StatefulWidget {
  final String userId;
  final String idToken;
  
  const FriendsScreen({
    super.key, 
    required this.userId,
    required this.idToken
    });

  @override
  State<FriendsScreen> createState() => _FriendsScreen();
}


class _FriendsScreen extends State<FriendsScreen> {
  final TextEditingController _friendsEmail = TextEditingController();

  final String databaseUrl = dotenv.get('DATA_BASE_URL');
  
  List<Map<String, dynamic>> _pendingFriends = [];
  List<Map<String, dynamic>> _acceptedFriends = [];


  
  @override
  void initState() {
    super.initState();
    friendsList();
  }
  Future<List<Map<String, dynamic>>> adding_friend(String email) async {

    Map<String, dynamic> mydata = {};

    
    final res = await http.get(
      Uri.parse('$databaseUrl/Users/${widget.userId}.json?auth=${widget.idToken}')
    );

    if (res.statusCode != 200) {
      print("was unable to get your own data");
      throw Exception('Failed to load my own user Data' );
    }
      
    mydata = json.decode(res.body);

    print('Searching for: $email');  
      
    try {
      final searchUrl = Uri.parse('$databaseUrl/Users.json?auth=${widget.idToken}');
      print('URL: $searchUrl');
      
      final searchResponse = await http.get(searchUrl);
      print('Status: ${searchResponse.statusCode}');
      print('Body: ${searchResponse.body}');
      
      if (searchResponse.statusCode == 200) {
        final dynamic usersData = json.decode(searchResponse.body);
        
        if (usersData != null && usersData is Map && usersData.isNotEmpty) {
          final matchingUsers = (usersData as Map<String, dynamic>).entries.where((entry) {
            final userData = entry.value;
            return userData['Email']?.toString().toLowerCase() == email.toLowerCase();
          }).toList();
          
          print('mydata : ${mydata}');

          if (matchingUsers.isNotEmpty) {
            final foundUser = matchingUsers.first;
            final targetUserId = foundUser.key;
            final targetUserName = foundUser.value['Name'] ?? 'No name';
            
            print('User found: $targetUserName with ID: $targetUserId');
            
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final theirFriendsUrl = Uri.parse('$databaseUrl/Users/$targetUserId/friends/${widget.userId}.json?auth=${widget.idToken}');
            
            await http.put(theirFriendsUrl, body: json.encode({
              'status': 'pending',
              'ProfileImageUrl' : mydata['ProfileImageUrl'] ?? '',
              'Name':  mydata['Name'],
              'timestamp': timestamp,
            }));
            
            print('Friend request sent to $targetUserName');
            
            return [{
              'userId': targetUserId,
              'name': targetUserName,
              'email': email,
            }];
          } else {
            print('No user found with email: $email');
            return []; 
          }
        } else {
          print('No users in database');
          return [];
        }
      } else {
        print('ACCESS DENIED - Status: ${searchResponse.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return []; 
    }
}

  Future<void> friendsList() async {
    final searchUrl = Uri.parse('$databaseUrl/Users/${widget.userId}/friends.json?auth=${widget.idToken}');
    print("Getting Your friends List");
    print('URL: $searchUrl');
    
    final searchResponse = await http.get(searchUrl);
    print('Status: ${searchResponse.statusCode}');
    print('Body: ${searchResponse.body}');

    
    if (searchResponse.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(searchResponse.body);
      
      for (var entry in data.entries) {
        final friendData = entry.value;
        final friendMap = {
          'friendId': entry.key,
          'status': friendData['status'],
          'timestamp': friendData['timestamp'],
          'ProfileImageUrl': friendData['ProfileImageUrl'],
          'Name': friendData['Name'],
        };
        
        if (friendData['status'] == "pending") {
          _pendingFriends.add(friendMap);
          print('Pending Friend: ${entry.key}');
        } else if (friendData['status'] == "accepted") {
          _acceptedFriends.add(friendMap);
          print('Accepted Friend: ${entry.key}');
        }
      }
    }

    setState(() {});
    
    print("This is your pending friends $_pendingFriends");
    print("This is your accepted friends $_acceptedFriends");
  }


  Future<void> accepting_friend(String friendId) async{

    final friendURL = Uri.parse('$databaseUrl/Users/${widget.userId}/friends/$friendId.json?auth=${widget.idToken}');
    final response = await http.patch(
      friendURL,
      body: json.encode({
        'status': 'accepted',
        }),
      );

    if (response.statusCode == 200) {
      print('Friend request accepted!');

      await friendsList();
    }
    else {
      print("Something went wrong and you did not manege to add them as a friend.");
    }
  }

  Future<void> decline_friend(String friendId) async{

    final friendURL = Uri.parse('$databaseUrl/Users/${widget.userId}/friends/$friendId.json?auth=${widget.idToken}');

    final response = await http.delete(friendURL);

    if (response.statusCode == 200) {
      print('Friend request declined and removed!!');

      await friendsList();
    }
    else {
      print("Something went wrong you did not decline the friend.. maybe its a stalker");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Friends Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add a Friend'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _friendsEmail,
                        decoration: InputDecoration(
                          labelText: 'Friends Email',
                          icon: Icon(Icons.person),
                        )
                        
                      )
                    ]
                  ),
                  actions: [
                    TextButton(
                      child: Text('Add'),
                      onPressed: () async{
                        Navigator.pop(context);
                        var email = _friendsEmail.text.trim();
                        _friendsEmail.clear();
                        await adding_friend(email);

                        }
                    )
                  ]
                )
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Divider(thickness: 3)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Pending Friends requests'),
                ),
                Expanded(child: Divider(thickness: 3)),
              ],
            ),
          ),
          SizedBox(
            height: 125,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              itemCount: _pendingFriends.length, 
              itemBuilder: (context, index) { 
                final friend = _pendingFriends[index];
                return Card(
                  color: Colors.grey[350],
                  elevation: 10, 
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),

                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(friend['ProfileImageUrl'] ?? ''),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            friend['Name'] ?? 'No Name',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color:Colors.green),
                          onPressed: (() {
                            print("Accepted ${friend['Name']}");
                            accepting_friend(friend['friendId']);
                          })
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, color:Colors.red),
                          onPressed:(() {
                            decline_friend(friend['friendId']);
                          })
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Divider(thickness: 3)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Friends'),
                ),
                Expanded(child: Divider(thickness: 3)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const  EdgeInsets.fromLTRB(20, 10, 20, 10),
              itemCount: _acceptedFriends.length, 
              itemBuilder: (context, index) { 
                final friend = _acceptedFriends[index];
                return InkWell (
                  onTap: () {
                    print("Clicked user ${friend['Name']}");
                    Navigator.push(
                    context,
                      MaterialPageRoute(
                        builder: (context) => FriendsProfile(
                          userId: friend['friendId'],
                          idToken: widget.idToken,
                          myId: widget.userId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.grey[350],
                    elevation: 10, 
                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(friend['ProfileImageUrl'] ?? ''),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              friend['Name'] ?? 'No Name',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}