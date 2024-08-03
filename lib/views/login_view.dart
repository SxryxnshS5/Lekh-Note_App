import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text;
    final password = _password.text;
    try {
      // ignore: unused_local_variable
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // On successful login, navigate to the homepage
      Navigator.of(context).pushReplacementNamed('/home/');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'User not found';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'invalid-credential':
          message = 'Invalid credential';
          break;
        case 'user-disabled':
          message = 'The user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Try again later.';
          break;
        case 'channel-error':
          message = 'Enter your credentials';
          break;    
        default:
          message = 'An error occurred. Please try again.';
          break;
      }
      // Show error message using a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: ' Enter your email here',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: ' Enter your password',
            ),
          ),
          ElevatedButton(
            onPressed: _login,
            child: const Text('Login'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/register/',
                (route) => false,
              );
            },
            child: const Text('Not registered yet? Register here!'),
          ),
        ],
      ),
    );
  }
}
