import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'notification_service.dart'; // Make sure this file exists!

class HomeScreen extends StatefulWidget {
  final String familyId;

  const HomeScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; 
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // --- NOTIFICATION SETUP ---
    // This initializes permissions and saves the token when the user opens the Home Screen
    final notifService = NotificationService();
    notifService.requestPermission();
    notifService.saveToken();
    notifService.initForegroundListeners();
  }

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
        if (snapshot.hasError) return Center(child: Text("Error loading chores"));
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        var chores = snapshot.data!.docs;

        if (chores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("All caught up! No chores pending.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: chores.length,
          itemBuilder: (context, index) {
            var chore = chores[index];
            var data = chore.data() as Map<String, dynamic>;
            
            // Format Date
            String dueDateText = "No deadline";
            if (data['dueDate'] != null) {
              DateTime dt = (data['dueDate'] as Timestamp).toDate();
              dueDateText = DateFormat('MMM d, y').format(dt);
            }

            bool isCompleted = data['isCompleted'] ?? false;

            return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    activeColor: Colors.green,
                    shape: CircleBorder(),
                    value: isCompleted,
                    onChanged: (bool? val) {
                      chore.reference.update({'isCompleted': val});
                    },
                  ),
                ),
                title: Text(
                  data['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                        SizedBox(width: 4),
                        Text(
                          data['assignedToName'] ?? 'Unassigned',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, 
                             color: data['dueDate'] != null ? Colors.redAccent : Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          dueDateText,
                          style: TextStyle(
                            fontSize: 12, 
                            color: data['dueDate'] != null ? Colors.redAccent : Colors.grey
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // --- RESTRICTED DELETE BUTTON ---
                // Only show if the current user created this task
                trailing: (data['createdBy'] == currentUser?.uid)
                    ? IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                        onPressed: () => chore.reference.delete(),
                      )
                    : null, 
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
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  Text("Family Join Code", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SelectableText(
                    familyData['code'] ?? "ERROR",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.blue[900]),
                  ),
                  SizedBox(height: 8),
                  Text("Share this code to invite others", style: TextStyle(color: Colors.blue[600], fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: memberIds.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(memberIds[index]).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return SizedBox(); 
                      var user = userSnapshot.data!;
                      String name = user['displayName'] ?? "Unknown";
                      String email = user['email'] ?? "";
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", 
                                       style: TextStyle(color: Colors.blue[900])),
                          ),
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(email),
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

  // --- ACTION: FETCH MEMBERS & SHOW DIALOG ---
  Future<List<Map<String, dynamic>>> _fetchFamilyMembers() async {
    try {
      DocumentSnapshot familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .get();
      
      List<dynamic> memberIds = familyDoc['members'] ?? [];
      List<Map<String, dynamic>> members = [];

      for (String uid in memberIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        
        if (userDoc.exists) {
          members.add({
            'uid': uid,
            'name': userDoc['displayName'] ?? 'Unknown',
          });
        }
      }
      return members;
    } catch (e) {
      print("Error fetching members: $e");
      return [];
    }
  }

  void _showAddChoreDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Dialog State Variables
        TextEditingController _taskController = TextEditingController();
        DateTime? _selectedDate;
        String? _selectedMemberId;
        String? _selectedMemberName;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Assign New Chore"),
              content: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFamilyMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 100, 
                      child: Center(child: CircularProgressIndicator())
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text("Could not load family members.");
                  }

                  var members = snapshot.data!;

                  // Default assignment: Current User
                  if (_selectedMemberId == null) {
                    var me = members.firstWhere(
                      (m) => m['uid'] == currentUser!.uid, 
                      orElse: () => members[0]
                    );
                    _selectedMemberId = me['uid'];
                    _selectedMemberName = me['name'];
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Task Title
                        TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            labelText: "Chore Title",
                            hintText: "e.g. Wash the car",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // 2. Assign To (Dropdown)
                        Text("Assign To:", style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedMemberId,
                          items: members.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['uid'],
                              child: Text(m['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateDialog(() {
                              _selectedMemberId = val;
                              _selectedMemberName = members.firstWhere((m) => m['uid'] == val)['name'];
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // 3. Due Date Picker
                        Text("Due Date:", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != _selectedDate) {
                              setStateDialog(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null 
                                      ? "Select Date" 
                                      : DateFormat('MMM d, y').format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null ? Colors.grey : Colors.black
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_taskController.text.isNotEmpty && _selectedMemberId != null) {
                      await FirebaseFirestore.instance
                          .collection('families')
                          .doc(widget.familyId)
                          .collection('chores')
                          .add({
                        'title': _taskController.text.trim(),
                        'isCompleted': false,
                        'assignedTo': _selectedMemberId,
                        'assignedToName': _selectedMemberName,
                        'dueDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
                        'createdBy': currentUser!.uid, // Used for delete permission
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Assign"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "My Family" : "Members"),
        centerTitle: true,
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
          ? FloatingActionButton.extended(
              onPressed: _showAddChoreDialog,
              icon: Icon(Icons.add),
              label: Text("New Chore"),
              backgroundColor: Colors.blue[700],
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: "Chores"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Members"),
        ],
      ),
    );
  }
}