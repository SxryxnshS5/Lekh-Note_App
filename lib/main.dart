import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lekh/firebase_options.dart';
import 'package:lekh/views/login_view.dart';
import 'package:lekh/views/register_view.dart';
import 'package:lekh/views/verify_email_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/login/': (context) => const LoginView(),
        '/register/': (context) => const RegisterView(),
        '/verify_email/': (context) => const VerifyEmailView(),
        '/home/': (context) => const HomePage(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              if (user.emailVerified) {
                return const NotesView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _noteController = TextEditingController();

  bool _isNoteEmpty = true;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(() {
      setState(() {
        _isNoteEmpty = _noteController.text.isEmpty;
      });
    });
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login/');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> _addNote() async {
    final user = _auth.currentUser;
    if (user != null && _noteController.text.isNotEmpty) {
      try {
        await _firestore.collection('notes').add({
          'userId': user.uid,
          'note': _noteController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _noteController.clear(); // Clear the text field
      } catch (e) {
        print('Error adding note: $e');
      }
    }
  }

  Future<void> _deleteNote(DocumentSnapshot note) async {
    try {
      await _firestore.collection('notes').doc(note.id).delete();
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  Future<void> _editNote(DocumentSnapshot note) async {
    final TextEditingController editController = TextEditingController(text: note['note']);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Edit your note',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (editController.text.isNotEmpty) {
                  try {
                    await _firestore.collection('notes').doc(note.id).update({
                      'note': editController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  } catch (e) {
                    print('Error editing note: $e');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getNotesStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('notes')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lekh', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter your note',
                    ),
                  ),
                ),
                if (!_isNoteEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _noteController.clear();
                    },
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addNote,
                child: const Text('Add Note'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getNotesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading notes'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notes available'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final note = snapshot.data!.docs[index];
                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Note Options'),
                              content: const Text('Do you want to edit or delete this note?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _editNote(note);
                                  },
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteNote(note);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(note['note']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
