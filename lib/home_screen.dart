import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String familyId;
  const HomeScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final notifService = NotificationService();
    notifService.requestPermission();
    notifService.saveToken();
    notifService.initForegroundListeners();
  }

  // --- ACTIONS ---
  Future<List<Map<String, dynamic>>> _fetchFamilyMembers() async {
    try {
      DocumentSnapshot familyDoc = await FirebaseFirestore.instance.collection('families').doc(widget.familyId).get();
      List<dynamic> memberIds = familyDoc['members'] ?? [];
      List<Map<String, dynamic>> members = [];
      for (String uid in memberIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          members.add({'uid': uid, 'name': userDoc['displayName'] ?? 'Unknown'});
        }
      }
      return members;
    } catch (e) {
      return [];
    }
  }

  void _showAddChoreDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController taskController = TextEditingController();
        String? selectedMemberId;
        String? selectedMemberName;

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Assign New Chore"),
            content: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFamilyMembers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                var members = snapshot.data!;
                
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: taskController, 
                        decoration: const InputDecoration(labelText: "Task Title", border: OutlineInputBorder())
                      ),
                      const SizedBox(height: 16),
                      // FIX: Added explicit types and casting below
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Assign To", border: OutlineInputBorder()),
                        value: selectedMemberId,
                        items: members.map<DropdownMenuItem<String>>((m) {
                          return DropdownMenuItem<String>(
                            value: m['uid'] as String,
                            child: Text(m['name'] as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedMemberId = val;
                            // Find name based on selected ID
                            final selectedMember = members.firstWhere((m) => m['uid'] == val, orElse: () => {});
                            if (selectedMember.isNotEmpty) {
                              selectedMemberName = selectedMember['name'] as String;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (taskController.text.isNotEmpty && selectedMemberId != null) {
                    await FirebaseFirestore.instance.collection('families').doc(widget.familyId).collection('chores').add({
                      'title': taskController.text.trim(),
                      'isCompleted': false,
                      'assignedTo': selectedMemberId,
                      'assignedToName': selectedMemberName,
                      'createdBy': currentUser!.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Assign"),
              )
            ],
          );
        });
      },
    );
  }

  // --- UI TABS ---
  Widget _buildChoresTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .collection('chores')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var chores = snapshot.data!.docs;
        if (chores.isEmpty) return const Center(child: Text("All caught up!", style: TextStyle(color: Colors.blueGrey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chores.length,
          itemBuilder: (context, index) {
            var chore = chores[index];
            var data = chore.data() as Map<String, dynamic>;
            bool isCompleted = data['isCompleted'] ?? false;
            
            return Card(
              child: ListTile(
                leading: Checkbox(
                  activeColor: const Color(0xFF2CC0E4),
                  value: isCompleted,
                  onChanged: (val) => chore.reference.update({'isCompleted': val}),
                ),
                title: Text(data['title'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                subtitle: Text("Assigned to: ${data['assignedToName']}"),
                trailing: data['createdBy'] == currentUser?.uid 
                  ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => chore.reference.delete())
                  : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('families').doc(widget.familyId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var familyData = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> memberIds = familyData['members'] ?? [];

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF2CC0E4).withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  const Text("Family Join Code", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(familyData['code'] ?? "---", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2CC0E4))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: memberIds.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(memberIds[index]).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      var user = userSnap.data!;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: const Color(0xFF2CC0E4), child: Text(user['displayName'][0], style: const TextStyle(color: Colors.white))),
                          title: Text(user['displayName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['email']),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "Daily Chores" : "Family Members"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: _selectedIndex == 0 ? _buildChoresTab() : _buildMembersTab(),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: _showAddChoreDialog,
        backgroundColor: const Color(0xFF2CC0E4),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.task_alt), label: "Chores"),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: "Family"),
        ],
      ),
    );
  }
}