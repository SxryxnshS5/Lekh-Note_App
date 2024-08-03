import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {

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

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register', style:TextStyle(color: Colors.white)),
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
                onPressed: () async {
                  final email = _email.text;
                  final password = _password.text;
                  try {
                    // ignore: unused_local_variable
                    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    Navigator.of(context).pushReplacementNamed('/verify_email/');
                  } on FirebaseAuthException catch (e) {
                    String message;
                    switch (e.code) {
                      case 'invalid-email':
                        message = 'The email address is badly formatted.';
                        break;
                      case 'weak-password':
                        message = 'The password provided is too weak.';
                        break;
                      case 'email-already-in-use':
                        message = 'The account already exists for that email.';
                        break;
                      case 'channel-error':
                        message = 'Enter your credentials';
                        break;  
                      default:
                        print(e.code);
                        message = 'An error occurred. Please try again.';
                        break;
                    }

                    // Show error message using a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } catch (e) {
                    // Handle non-Firebase related errors
                    String message = 'An unexpected error occurred. Please try again.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                }, 
              child: const Text('Register'),
              ),
              ElevatedButton(onPressed: (){
                Navigator.of(context).pushNamedAndRemoveUntil(
                '/login/', 
                (route) => false
                );
              }, 
              child: const Text('Already registed? Login here!'))
            ],
          ),
    );
  }
}
