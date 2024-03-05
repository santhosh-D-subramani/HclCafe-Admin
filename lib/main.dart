import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hclcafe_admin/screens/login_signup_screen.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) => runApp(
        const MyApp(),
      ));
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      if (kDebugMode) {
        print('User is currently signed out!');
      }
    } else {
      if (kDebugMode) {
        print('User is signed in!');
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        if (kDebugMode) {
          print('User is currently signed out!');
        }
      } else {
        if (kDebugMode) {
          print('User is signed in!');
        }
      }
    });
    User? user = FirebaseAuth.instance.currentUser;
    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HCLCAFE Admin',
        theme: ThemeData(
          colorScheme: lightDynamic ?? ThemeData.light(useMaterial3: true).colorScheme,
          useMaterial3: true,
          brightness: Brightness.light,
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      kIsWeb ? ThemeData.light(useMaterial3: true).colorScheme.inversePrimary : lightDynamic!.inversePrimary))),
        ),
        darkTheme: ThemeData(
          colorScheme: darkDynamic ?? ThemeData.dark(useMaterial3: true).colorScheme,
          useMaterial3: true,
          brightness: Brightness.dark,
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      kIsWeb ? ThemeData.dark(useMaterial3: true).colorScheme.inversePrimary : darkDynamic!.inversePrimary))),
        ),
        home: user == null ? const AuthSelector() : const MyHomePage(),
      );
    });
  }
}

class AuthSelector extends StatelessWidget {
  const AuthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Hero(
                  tag: 'imageTag',
                  child: Image.asset(
                    'images/logo.png',
                    height: MediaQuery.of(context).size.height / 3,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 1.1,
                  height: kBottomNavigationBarHeight,
                  child: ElevatedButton(
                      // style: ElevatedButton.styleFrom(
                      //     backgroundColor:
                      //         MediaQuery.of(context).platformBrightness ==
                      //                 Brightness.light
                      //             ? commonColorScheme.light!.inversePrimary
                      //             : commonColorScheme.dark!.inversePrimary),
                      child: const Text('Login'),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen(
                                      whatAuth: 'Login',
                                    )));
                      }),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 1.1,
                  height: kBottomNavigationBarHeight,
                  child: ElevatedButton(
                      // style: ElevatedButton.styleFrom(
                      //     backgroundColor:
                      //         MediaQuery.of(context).platformBrightness ==
                      //                 Brightness.light
                      //             ? commonColorScheme.light!.inversePrimary
                      //             : commonColorScheme.dark!.inversePrimary),
                      child: const Text('Sign Up'),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen(
                                      whatAuth: 'Sign Up',
                                    )));
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
