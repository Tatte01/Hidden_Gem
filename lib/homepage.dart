import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Screens/screens.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String idToken;
  final int? preindex;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.idToken,
    this.preindex,
    });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    MapScreen(userId: widget.userId, idToken: widget.idToken),
    ProfileScreen(userId: widget.userId, idToken: widget.idToken),
    FriendsScreen(userId: widget.userId, idToken: widget.idToken),
    GemScreen(userId: widget.userId, idToken: widget.idToken),
  ];

  @override
  Widget build(BuildContext context) {
    //debug
    print('User ID: ${widget.userId}');
    print('ID Token: ${widget.idToken}');
    print("${widget.preindex}");

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Gems',
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.preindex ?? 0;
  }
}
