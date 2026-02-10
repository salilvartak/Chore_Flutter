import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // For logging out

class HomeScreen extends StatefulWidget {
  final String familyId;

  // We require the familyId to know which data to load
  const HomeScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0 = Chores, 1 = Members
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- UI: CHORES TAB ---
  Widget _buildChoresTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .collection('chores')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var chores = snapshot.data!.docs;

        if (chores.isEmpty) {
          return Center(child: Text("No chores yet! Add one below."));
        }

        return ListView.builder(
          itemCount: chores.length,
          itemBuilder: (context, index) {
            var chore = chores[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: Checkbox(
                  value: chore['isCompleted'] ?? false,
                  onChanged: (bool? val) {
                    // Toggle Complete Status
                    chore.reference.update({'isCompleted': val});
                  },
                ),
                title: Text(
                  chore['title'],
                  style: TextStyle(
                    decoration: (chore['isCompleted'] ?? false)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text("Assigned to: ${chore['assignedToName'] ?? 'Unassigned'}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => chore.reference.delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI: MEMBERS TAB ---
  Widget _buildMembersTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        var familyData = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> memberIds = familyData['members'] ?? [];

        return Column(
          children: [
            // Display Family Code for sharing
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              width: double.infinity,
              child: Column(
                children: [
                  Text("Family Code (Share this!)", style: TextStyle(color: Colors.grey)),
                  Text(
                    familyData['code'] ?? "ERROR",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: memberIds.length,
                itemBuilder: (context, index) {
                  // Fetch user details for each ID
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(memberIds[index]).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return ListTile(title: Text("Loading..."));
                      var user = userSnapshot.data!;
                      return ListTile(
                        leading: CircleAvatar(child: Text(user['displayName'][0] ?? "?")),
                        title: Text(user['displayName'] ?? "Unknown"),
                        subtitle: Text(user['email'] ?? ""),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- ACTION: ADD CHORE DIALOG ---
  void _showAddChoreDialog() {
    TextEditingController _taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Chore"),
        content: TextField(
          controller: _taskController,
          decoration: InputDecoration(hintText: "e.g. Wash dishes"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_taskController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('families')
                    .doc(widget.familyId)
                    .collection('chores')
                    .add({
                  'title': _taskController.text,
                  'isCompleted': false,
                  'assignedTo': currentUser!.uid,
                  'assignedToName': currentUser!.displayName,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Family"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: _selectedIndex == 0 ? _buildChoresTab() : _buildMembersTab(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddChoreDialog,
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: "Chores"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Members"),
        ],
      ),
    );
  }
}