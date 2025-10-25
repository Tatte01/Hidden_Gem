import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'SingleGemScreen.dart';

class GemScreen extends StatefulWidget {
  final String userId;
  final String idToken;

  const GemScreen({
    super.key,
    required this.userId,
    required this.idToken
    });

  @override
  State<GemScreen> createState() => _GemScreenState();
}

class _GemScreenState extends State<GemScreen> {

  Map<String, dynamic> gemData = {};
  final String databaseUrl = dotenv.get('DATA_BASE_URL');
  String _gemCount = "0";

  void _loadGems() async {
    final url = Uri.parse('$databaseUrl/Users/${widget.userId}/Gems.json?auth=${widget.idToken}');
    final response = await http.get(url);

    print("Loading gems... Status: ${response.statusCode}");

    if (response.statusCode == 200)  {
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
        title: Text('Gems Page'),
        ),

    body: ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          iconSize: 20,
                          color: Colors.black,
                          onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingleGemScreen(
                                  userId: widget.userId,
                                  idToken: widget.idToken,
                                  gemName: item['Name'],
                                  description: item['Decoration'],
                                  lat: item['Latitude'],
                                  lng: item['Longitude'],
                                  image: item['Image'],
                                  index: 3,
                                ),
                              ),
                            )
                          },
                        ),
                      ],
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
                      )
                      : Text("This gem does not have a Image"),
                    Text(' Description: ${item['Decoration']}'),
                    ExpansionTile(
                      title: Text('More Info'),
                      dense: true,
                      children: [
                        Text('Latitude: ${item['Latitude']}'),
                        Text('Longitude: ${item['Longitude']}'),
                        Text('Created: ${item['Created']}'),
                      ]
                    ),
                  ]
                )
              ],
            ),
          ),
        );
      },
    ),
  );
}
  @override
  void initState() {
    super.initState();

    _loadGems();
  }
}