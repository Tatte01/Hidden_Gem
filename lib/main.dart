import 'package:flutter/material.dart';
import 'loginScreen.dart';
import 'homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized() ;

  await dotenv.load(fileName:".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Check if still loading auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          // 2. Check if user is logged in
          if (snapshot.hasData && snapshot.data != null) {
            // 3. Get the token immediately using FutureBuilder
            return FutureBuilder<String>(
              future: snapshot.data!.getIdToken().then((token) => token ?? ''), 
              builder: (context, tokenSnapshot) {
                // 4. Check if still loading token
                if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return HomeScreen(
                  userId: snapshot.data!.uid,
                  idToken: tokenSnapshot.data!,
                );
              },
            );
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}