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

  void _showAddChoreBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        final TextEditingController taskController = TextEditingController();
        String? selectedMemberId;
        String? selectedMemberName;
        DateTime? selectedDate;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B), // Surface/Card color for modal
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: Color(0xFF334155))),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFamilyMembers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                  var members = snapshot.data!;

                  return StatefulBuilder(
                    builder: (context, setStateSheet) {
                      if (selectedMemberId == null && members.isNotEmpty) {
                         final me = members.firstWhere((m) => m['uid'] == currentUser?.uid, orElse: () => members.first);
                         selectedMemberId = me['uid'];
                         selectedMemberName = me['name'];
                      }

                      return ListView(
                        controller: scrollController,
                        children: [
                          Center(
                            child: Container(
                              width: 50, height: 5,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)),
                            ),
                          ),

                          const Text("New Chore", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC))),
                          const SizedBox(height: 20),

                          TextField(
                            controller: taskController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 18, color: Color(0xFFF8FAFC)),
                            decoration: InputDecoration(
                              hintText: "What needs to be done?",
                              fillColor: const Color(0xFF0F172A), // Slightly darker inside input
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text("Assign to", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: members.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final isSelected = member['uid'] == selectedMemberId;
                                
                                return GestureDetector(
                                  onTap: () {
                                    setStateSheet(() {
                                      selectedMemberId = member['uid'];
                                      selectedMemberName = member['name'];
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 85,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A), // Indigo for selection
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155)),
                                      boxShadow: isSelected 
                                        ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                                        : [],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isSelected ? const Color(0xFF1E293B) : const Color(0xFF1E293B),
                                          foregroundColor: isSelected ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
                                          child: Text(member['name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          member['name'],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12, 
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text("Deadline", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Color(0xFF10B981), // Emerald
                                        onPrimary: Color(0xFFF8FAFC),
                                        surface: Color(0xFF1E293B),
                                        onSurface: Color(0xFFF8FAFC),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                }
                              );
                              if (picked != null) {
                                setStateSheet(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A), // Match input backgrounds
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: selectedDate != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate == null ? "No Deadline" : DateFormat('MMM d, y').format(selectedDate!),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedDate != null ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
                                      fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal
                                    ),
                                  ),
                                  const Spacer(),
                                  if (selectedDate != null)
                                    GestureDetector(
                                      onTap: () => setStateSheet(() => selectedDate = null),
                                      child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                                    )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: () async {
                              if (taskController.text.isNotEmpty && selectedMemberId != null) {
                                await FirebaseFirestore.instance.collection('families').doc(widget.familyId).collection('chores').add({
                                  'title': taskController.text.trim(),
                                  'isCompleted': false,
                                  'assignedTo': selectedMemberId,
                                  'assignedToName': selectedMemberName,
                                  'dueDate': selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
                                  'createdBy': currentUser!.uid,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            child: const Text("Create Chore"),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
        var chores = snapshot.data!.docs;
        if (chores.isEmpty) return const Center(child: Text("All caught up!", style: TextStyle(color: Color(0xFF94A3B8))));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chores.length,
          itemBuilder: (context, index) {
            var chore = chores[index];
            var data = chore.data() as Map<String, dynamic>;
            bool isCompleted = data['isCompleted'] ?? false;
            
            String? dueDateText;
            Color dateColor = const Color(0xFF94A3B8);
            if (data['dueDate'] != null) {
              DateTime dt = (data['dueDate'] as Timestamp).toDate();
              dueDateText = DateFormat('MMM d').format(dt);
              if (dt.isBefore(DateTime.now().subtract(const Duration(days: 1))) && !isCompleted) {
                dateColor = Colors.redAccent;
              }
            }

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    activeColor: const Color(0xFF10B981), // Emerald Success
                    checkColor: const Color(0xFF0F172A), 
                    side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                    shape: const CircleBorder(),
                    value: isCompleted,
                    onChanged: (val) => chore.reference.update({'isCompleted': val}),
                  ),
                ),
                title: Text(
                  data['title'], 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? const Color(0xFF334155) : const Color(0xFFF8FAFC)
                  )
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(data['assignedToName'] ?? "Unknown", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    if (dueDateText != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today, size: 14, color: dateColor),
                      const SizedBox(width: 4),
                      Text(dueDateText, style: TextStyle(color: dateColor, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]
                  ],
                ),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
        var familyData = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> memberIds = familyData['members'] ?? [];

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF334155)),
                borderRadius: BorderRadius.circular(24)
              ),
              child: Column(
                children: [
                  const Text("Family Join Code", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  SelectableText(familyData['code'] ?? "---", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6366F1), letterSpacing: 4)), // Indigo
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
                          leading: CircleAvatar(backgroundColor: const Color(0xFF6366F1), child: Text(user['displayName'][0], style: const TextStyle(color: Color(0xFFF8FAFC)))),
                          title: Text(user['displayName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC))),
                          subtitle: Text(user['email'], style: const TextStyle(color: Color(0xFF94A3B8))),
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
        onPressed: _showAddChoreBottomSheet,
        backgroundColor: const Color(0xFF10B981), // Emerald
        foregroundColor: const Color(0xFFF8FAFC),
        child: const Icon(Icons.add),
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