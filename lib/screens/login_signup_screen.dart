import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
TextEditingController nameController = TextEditingController();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.whatAuth});
  final String whatAuth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    bool errorCheck = false;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.whatAuth),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            // shrinkWrap: true,
            children: [
              const SizedBox(
                height: 16,
              ),
              Hero(
                tag: 'imageTag',
                child: Image.asset(
                  'images/logo.png',
                  height: MediaQuery.of(context).size.height / 4,
                ),
              ),
              Visibility(
                  visible: widget.whatAuth == 'Sign Up' ? true : false,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(fixedSize: Size(size.width, 70)),
                  onPressed: () async {
                    try {
                      final userCredential = widget.whatAuth == 'Sign Up'
                          ? await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: emailController.text,
                              password: passwordController.text,
                            )
                          : await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: emailController.text,
                              password: passwordController.text,
                            );
                      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("Users").child(userCredential.user!.uid);

                      if (widget.whatAuth == 'Sign Up') {
                        Map<String, dynamic> userData = {
                          'name': nameController.text.toString(),
                          'email': emailController.text.toString(),
                          'uid': userCredential.user!.uid,
                        };
                        userRef.set(userData);
                      }
                      if (userCredential.user != null) {
                        // Login successful, navigate to the home page
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const MyHomePage(),
                          ));
                        }
                      }
                    } catch (e) {
                      // Handle login errors
                      if (kDebugMode) {
                        print('Error: $e');
                      }
                    }
                  },
                  child: Text(widget.whatAuth)),
            ],
          ),
        ),
      ),
    );
  }
}
