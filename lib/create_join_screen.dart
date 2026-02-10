import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; // For navigation after creating/joining family

class CreateJoinScreen extends StatefulWidget {
  @override
  _CreateJoinScreenState createState() => _CreateJoinScreenState();
}

class _CreateJoinScreenState extends State<CreateJoinScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // UI State
  String _mode = 'selection'; // 'selection', 'create', 'join'
  bool _isLoading = false;
  
  // Text Controllers
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();

  // --- LOGIC: GENERATE CODE ---
  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // --- LOGIC: CREATE FAMILY ---
  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    User? user = _auth.currentUser;
    String code = _generateFamilyCode();

    try {
      // 1. Create a new Family Document
      DocumentReference familyRef = await _firestore.collection('families').add({
        'name': _familyNameController.text.trim(),
        'code': code,
        'createdBy': user!.uid,
        'members': [user.uid], // Add creator as first member
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update User Document with Family ID
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'familyId': familyRef.id,
        'role': 'admin', 
      }, SetOptions(merge: true));

      // 3. Navigate to Home
      print("Family Created! Code: $code");
      // Make sure you have imported home_screen.dart at the top!
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => HomeScreen(familyId: familyRef.id))
      );
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: JOIN FAMILY ---
  Future<void> _joinFamily() async {
    String inputCode = _joinCodeController.text.trim().toUpperCase();
    if (inputCode.length != 6) return;

    setState(() => _isLoading = true);
    User? user = _auth.currentUser;

    try {
      // 1. Find family with this code
      QuerySnapshot query = await _firestore
          .collection('families')
          .where('code', isEqualTo: inputCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw "Invalid Family Code";
      }

      DocumentReference familyRef = query.docs.first.reference;

      // 2. Add user to family members list
      await familyRef.update({
        'members': FieldValue.arrayUnion([user!.uid])
      });

      // 3. Update User Document
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'familyId': familyRef.id,
        'role': 'member',
      }, SetOptions(merge: true));

      // 4. Navigate to Home
     Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => HomeScreen(familyId: familyRef.id))
      );
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- WIDGETS ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == 'selection' ? 'Welcome' : _mode == 'create' ? 'Create Family' : 'Join Family'),
        leading: _mode != 'selection' ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => _mode = 'selection'),
        ) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading 
            ? Center(child: CircularProgressIndicator()) 
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // SELECTION MODE
                  if (_mode == 'selection') ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.all(20)),
                      onPressed: () => setState(() => _mode = 'create'),
                      child: Text("Create a new Family Group"),
                    ),
                    SizedBox(height: 20),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.all(20)),
                      onPressed: () => setState(() => _mode = 'join'),
                      child: Text("Join an existing Family"),
                    ),
                  ],

                  // CREATE MODE
                  if (_mode == 'create') ...[
                    Text("Give your family group a name"),
                    SizedBox(height: 10),
                    TextField(
                      controller: _familyNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Family Name (e.g. The Smiths)',
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createFamily,
                      child: Text("Create & Generate Code"),
                    ),
                  ],

                  // JOIN MODE
                  if (_mode == 'join') ...[
                    Text("Enter the 6-digit code shared by your family"),
                    SizedBox(height: 10),
                    TextField(
                      controller: _joinCodeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '6-Digit Code',
                        counterText: "",
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _joinFamily,
                      child: Text("Join Family"),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}