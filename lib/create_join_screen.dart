import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class CreateJoinScreen extends StatefulWidget {
  @override
  _CreateJoinScreenState createState() => _CreateJoinScreenState();
}

class _CreateJoinScreenState extends State<CreateJoinScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _mode = 'selection'; // 'selection', 'create', 'join'
  bool _isLoading = false;
  
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    User? user = _auth.currentUser;
    String code = _generateFamilyCode();
    try {
      DocumentReference familyRef = await _firestore.collection('families').add({
        'name': _familyNameController.text.trim(),
        'code': code,
        'createdBy': user!.uid,
        'members': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'familyId': familyRef.id,
        'role': 'admin', 
      }, SetOptions(merge: true));
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(familyId: familyRef.id)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinFamily() async {
    String inputCode = _joinCodeController.text.trim().toUpperCase();
    if (inputCode.length != 6) return;
    setState(() => _isLoading = true);
    User? user = _auth.currentUser;
    try {
      QuerySnapshot query = await _firestore.collection('families').where('code', isEqualTo: inputCode).limit(1).get();
      if (query.docs.isEmpty) throw "Invalid Family Code";
      DocumentReference familyRef = query.docs.first.reference;
      await familyRef.update({'members': FieldValue.arrayUnion([user!.uid])});
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'familyId': familyRef.id,
        'role': 'member',
      }, SetOptions(merge: true));
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(familyId: familyRef.id)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == 'selection' ? 'Welcome' : _mode == 'create' ? 'Create Family' : 'Join Family'),
        leading: _mode != 'selection' ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => setState(() => _mode = 'selection'),
        ) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildViewContent(),
        ),
      ),
    );
  }

  Widget _buildViewContent() {
    if (_mode == 'selection') {
      return Column(
        key: const ValueKey('selection'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => setState(() => _mode = 'create'),
            child: const Text("Create a new Family Group"),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: Color(0xFF2CC0E4), width: 2),
            ),
            onPressed: () => setState(() => _mode = 'join'),
            child: const Text("Join an existing Family", style: TextStyle(color: Color(0xFF2CC0E4), fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (_mode == 'create') {
      return Column(
        key: const ValueKey('create'),
        children: [
          const Text("Give your family group a name", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 16),
          TextField(
            controller: _familyNameController,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Family Name (e.g. The Smiths)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _createFamily, child: const Text("Create & Generate Code")),
        ],
      );
    } else {
      return Column(
        key: const ValueKey('join'),
        children: [
          const Text("Enter the 6-digit code shared by your family", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 16),
          TextField(
            controller: _joinCodeController,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ""),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _joinFamily, child: const Text("Join Family")),
        ],
      );
    }
  }
}