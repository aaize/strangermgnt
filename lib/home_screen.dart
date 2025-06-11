import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'history.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

  }


  Widget _buildVisitorsList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError) {
      return Text(
        'Error: ${snapshot.error}',
        style: const TextStyle(color: Colors.white),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending visitors',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All visitors will appear here',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        final doc = snapshot.data!.docs[index];
        final visitor = doc.data()! as Map<String, dynamic>;

        DateTime? registeredAt;
        try {
          registeredAt = DateTime.parse(visitor['registered_at']);
        } catch (_) {
          registeredAt = null;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              // Visitor Info Section (tappable for image)
              GestureDetector(
                onTap: () {
                  final imageUrl = visitor['visitor_pass_url'] ?? '';
                  if (imageUrl.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(10),
                        child: Container(
                          height: 611,
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No image available for this visitor"),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visitor['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (visitor['visitor_pass_url']?.isNotEmpty ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Tap for pass',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Purpose: ${visitor['purpose'] ?? 'Not specified'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${visitor['phone'] ?? 'Not provided'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      if (registeredAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Registered: ${registeredAt.toLocal().toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () async {
                          try {
                            await _moveVisitorToCancelled(doc);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${visitor['name'] ?? 'Visitor'} has been cancelled'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error cancelling visitor'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.xmark_circle,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        onPressed: () async {
                          try {
                            await _moveVisitorToMet(doc);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${visitor['name'] ?? 'Visitor'} marked as visited'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error marking visitor as met'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.check_mark_circled,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Visited',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          username = userData['username'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    setState(() {}); // This will trigger a rebuild and refresh the StreamBuilders
  }

  Future<void> _moveVisitorToMet(DocumentSnapshot visitorDoc) async {
    try {
      final visitorData = visitorDoc.data()! as Map<String, dynamic>;

      // Add timestamp for when they were marked as met
      visitorData['met_at'] = DateTime.now().toIso8601String();
      visitorData['status'] = 'met';

      // Add to visitors-met collection
      await FirebaseFirestore.instance
          .collection('visitors-met')
          .add(visitorData);

      // Remove from original visitors collection
      await visitorDoc.reference.delete();
    } catch (e) {
      print('Error moving visitor to met: $e');
      rethrow;
    }
  }

  Future<void> _moveVisitorToCancelled(DocumentSnapshot visitorDoc) async {
    try {
      final visitorData = visitorDoc.data()! as Map<String, dynamic>;

      // Add timestamp for when they were cancelled
      visitorData['cancelled_at'] = DateTime.now().toIso8601String();
      visitorData['status'] = 'cancelled';

      // Add to visitors-cancelled collection
      await FirebaseFirestore.instance
          .collection('visitors-cancelled')
          .add(visitorData);

      // Remove from original visitors collection
      await visitorDoc.reference.delete();
    } catch (e) {
      print('Error moving visitor to cancelled: $e');
      rethrow;
    }
  }

  void _showActionDialog(BuildContext context, DocumentSnapshot visitorDoc) {
    final visitorData = visitorDoc.data()! as Map<String, dynamic>;
    final visitorName = visitorData['name'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: Text(
          'Visitor Action',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'What would you like to do with $visitorName?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _moveVisitorToCancelled(visitorDoc);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$visitorName has been cancelled'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error cancelling visitor'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Visit'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _moveVisitorToMet(visitorDoc);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$visitorName marked as visited'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error marking visitor as met'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Visited'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1A2F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (username == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1A2F),
        body: Center(
          child: Text('User not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A1A2F),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A1A2F),
            body: Center(
              child: Text('User not found', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String name = userData['username'] ?? 'Unknown';
        final String email = userData['email'] ?? 'Faculty';
        final String profileImage = userData['profileImage'] ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFF0A1A2F),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              backgroundColor: const Color(0xFF1A2332),
              color: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: profileImage.isNotEmpty
                                    ? NetworkImage(profileImage)
                                    : const AssetImage('assets/logo.png') as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const SizedBox(height: 1),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: GestureDetector( child: Icon(
                              Icons.history_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                              onTap:() {
                                Navigator.push(
                                    context, MaterialPageRoute(builder:(context)
                                    => HistoryScreen(userId: widget.userId),
                                ),
                                );
                              },
                            ),

                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // VISITORS LIST FROM FIRESTORE FILTERED BY visited_to_username
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('visitors')
                            .where('visited_to_username', isEqualTo: username)
                            .orderBy('registered_at', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Show loading while fetching data
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              children: [
                                // VISITORS LIST TITLE with loading count
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pending Visitors',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Center(child: CircularProgressIndicator()),
                              ],
                            );
                          }

                          // Calculate count from the same data
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                          return Column(
                            children: [
                              // VISITORS LIST TITLE with count
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pending Visitors',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // VISITORS LIST CONTENT
                              _buildVisitorsList(snapshot),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // LOGOUT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.red.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}