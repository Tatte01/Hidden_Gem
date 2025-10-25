import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homepage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_button/sign_button.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  GoogleSignInAccount? _user;
  final String apiKey = dotenv.get('FIREBASE_API_KEY');
  final String apiBaseUrl = dotenv.get('API_BASE_URL');
  bool isLoggedIn = false;

void _handleLogin(BuildContext context) async {
  String email = _emailController.text;
  String password = _passwordController.text;
  
  print("Attempting to login With: $email");
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;
    if (user != null) {
      print("Success! User ID: ${user.uid}");
      
      if (user.emailVerified) {
        setState(() {
          isLoggedIn = true;
        });

        String idToken = await user.getIdToken() ?? '';
        
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => HomeScreen(
              userId: user.uid,
              idToken: idToken,
            )),
          );
        });
      } else {
        print("Your email is not verified!!");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account not Verified!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('You need to go to your email and follow the Link.'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Re-Send'),
                onPressed: () {
                  Navigator.pop(context);
                  user.sendEmailVerification();
                },
              ),
            ],
          ),
        );
      }
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'invalid-email') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: The Email is not registered, try to register first")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: The Password is wrong.")),
      );
    } 
    print("Firebase Auth Error: ${e.code} - ${e.message}");
  } catch (e) {
    print("Network Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login failed: Network error")),
    );
  }
}

  void _handleRegister(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // Create the user account
      final response = await http.post(
        Uri.parse('$apiBaseUrl/accounts:signUp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String userId = responseData['localId'];
        final String idToken = responseData['idToken'];
        
        print("Success! User ID: $userId");
        
        // Send email verification
        await _sendEmailVerification(idToken);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration successful! Please check your email to verify your account."),
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        final errorData = json.decode(response.body);
        print("Firebase Error: ${errorData['error']['message']}");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${errorData['error']['message']}")),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    }
  }

  Future<void> _sendEmailVerification(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/accounts:sendOobCode?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requestType': 'VERIFY_EMAIL',
          'idToken': idToken,
        }),
      );
      
      if (response.statusCode == 200) {
        print("Email verification sent successfully!");
      } else {
        final errorData = json.decode(response.body);
        print("Failed to send verification email: ${errorData['error']['message']}");
        throw Exception("Failed to send verification email: ${errorData['error']['message']}");
      }
    } catch (e) {
      print("Error sending verification email: $e");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          children: [
            const SizedBox(height: 100),
            AnimatedContainer(
              duration: Duration(seconds: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 71, 71, 71),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlue,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: EdgeInsets.all(20.0),
              child: Icon( isLoggedIn ? Icons.lock_open : Icons.lock,
                color: isLoggedIn ?  Colors.green : Color.fromARGB(255, 1, 149, 218),
                size: 80,
              ),
            ),

            const SizedBox(height: 25),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                icon: Icon(Icons.mail),
                iconColor: Colors.lightBlue
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                icon: Icon(Icons.key),
                iconColor: Colors.lightBlue,
              ),
            ),
            const SizedBox(height: 30),
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:() => _handleLogin(context),
                child: Text('Login')
                ),
                ElevatedButton(
                  onPressed:() => {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'If you enter your email we will send you an email with a reset password link. \n'
                          ),
                          Text(
                            'Make sure to look in your spam folder it can take up to 5 min before you get your email'
                          ),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              icon: Icon(Icons.mail),
                              iconColor: Colors.lightBlue
                            ),
                          ),
                        ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text('Send'),
                            onPressed: () async {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
                            Navigator.pop(context);
                            }
                          )
                        ]
                      )
                    )
                  },
                  child: Text("Forgot Password? ")
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: Divider(thickness: 3,)),
                Text('OR'),
                Expanded(child: Divider(thickness: 3,))
              ],
            ),

            const SizedBox(height: 10),

            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleRegister(context),
                  child: Text('Register')
                  ),
                const SizedBox(height: 50,),
                SignInButton(
                  buttonType: ButtonType.google,
                  onPressed:() async {
                    final Map<String, String>? loginResult =  await googlelogin();
                    if (loginResult != null) {
                      setState(() {
                        isLoggedIn = true;
                      });
                      Future.delayed(Duration(seconds: 2), () {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => HomeScreen(
                            userId: loginResult['userId']!,
                            idToken: loginResult['idToken']!
                          ))
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login failed of cancelled'))
                      );
                    }
                  }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> googlelogin() async {
    try {
      await GoogleSignIn().signOut();
      
      final user = await GoogleSignIn().signIn();
      GoogleSignInAuthentication userAuth = await user!.authentication;

      var credential = GoogleAuthProvider.credential(
        idToken: userAuth.idToken,
        accessToken: userAuth.accessToken
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      String? firebaseIdToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && firebaseIdToken != null) {
      return {
        'userId': userId,
        'idToken': firebaseIdToken
      };
    }
    return null;

    } catch (e) {
      print('login error $e');
      return null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }
}