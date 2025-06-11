import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SuccessScreen extends StatefulWidget {
  final File profileImage;
  final String name;
  final String email;
  final String phone;
  final String purpose;
  final String department;
  final String visitedToDisplay;
  final String visitedToUsername;
  final String visitedType;

  const SuccessScreen({
    Key? key,
    required this.profileImage,
    required this.name,
    required this.email,
    required this.phone,
    required this.purpose,
    required this.department,
    required this.visitedToDisplay,
    required this.visitedToUsername,
    required this.visitedType,
  }) : super(key: key);

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final ScreenshotController screenshotController = ScreenshotController();
  late final String timestamp;

  bool _isConfirmed = false;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<String> _uploadScreenshotToSupabase(Uint8List imageBytes,
      String fileName) async {
    try {
      // Upload using the new API without .execute()
      await supabase.storage
          .from('visitor-passes')
          .uploadBinary(
        'passes/$fileName.png',
        imageBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
          contentType: 'image/png',
        ),
      );

      // Get public URL of the uploaded image
      final publicUrl = supabase.storage
          .from('visitor-passes')
          .getPublicUrl('passes/$fileName.png');

      return publicUrl;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<void> _confirmAndSave() async {
    if (_isConfirmed || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Capture screenshot image
      final imageBytes = await screenshotController.capture();
      if (imageBytes == null) throw Exception('Failed to capture screenshot.');

      // Upload to Supabase Storage using binary data directly
      final fileName = 'visitor_card_${DateTime
          .now()
          .millisecondsSinceEpoch}';
      final publicImageUrl = await _uploadScreenshotToSupabase(
          imageBytes, fileName);

      // ✅ Upload visitor data to Firebase Firestore instead of Supabase table
      await FirebaseFirestore.instance.collection('visitors').add({
        'name': widget.name,
        'email': widget.email,
        'phone': widget.phone,
        'purpose': widget.purpose,
        'department': widget.department,
        'visited_to_display': widget.visitedToDisplay,
        'visited_to_username': widget.visitedToUsername,
        'registered_at': DateTime.now().toIso8601String(),
        'visitor_pass_url': publicImageUrl,
      });

      setState(() {
        _isConfirmed = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor registration saved to Firestore!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConfirmed = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _captureAndShareCard() async {
    try {
      final image = await screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/visitor_card_${DateTime
            .now()
            .millisecondsSinceEpoch}.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: "My Visitor Pass 📇",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1A2F),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // Add some top spacing
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Registration Complete!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your visitor pass has been generated.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),


                    Screenshot(
                      controller: screenshotController,
                      child: Container(
                        height: 620,
                        width: 340,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                              const Color(0xFFf093fb),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      const Color(0xFFFAFBFF),
                                    ],
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Logo
                                        Container(
                                          child: Image.asset(
                                            'assets/logo.png',
                                            height: 80,
                                            width: 200,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        // Profile Picture
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF667eea),
                                                const Color(0xFF764ba2),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF667eea).withOpacity(0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: CircleAvatar(
                                              radius: 70,
                                              backgroundImage: FileImage(widget.profileImage),
                                              backgroundColor: Colors.grey.shade100,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Name instead of Visitor Badge
                                        Text(
                                          widget.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1a237e),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        Text(
                                          widget.visitedType,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            letterSpacing: 0.8,
                                          ),
                                        ),

                                        const SizedBox(height: 3),

                                        // Information Section
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              _modernInfoRow("Phone Number", widget.phone, Icons.phone_outlined, const Color(0xFF66bb6a)),
                                              _modernInfoRow("Visit Purpose", widget.purpose, Icons.work_outline, const Color(0xFFffa726)),
                                              _modernInfoRow("Department", widget.department, Icons.business_outlined, const Color(0xFFef5350)),
                                              _modernInfoRow("Visiting", widget.visitedToDisplay, Icons.location_on_outlined, const Color(0xFFab47bc)),
                                              _modernInfoRow("Host Username", widget.visitedToUsername, Icons.account_circle_outlined, const Color(0xFF42a5f5)),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        // Registered Time (no border)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF667eea),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.access_time_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Registered: $timestamp',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF1a237e),
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        // Footer line
                                        Container(
                                          height: 3,
                                          width: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF667eea),
                                                const Color(0xFF764ba2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),



                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: _isConfirmed
                          ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Confirmed & Saved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ElevatedButton(
                        onPressed: _isLoading ? null : _confirmAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667eea)),
                          ),
                        )
                            : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _captureAndShareCard,
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text(
                          'Share Visitor Pass',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40), // Add bottom spacing
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _modernInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16), // Decrease icon size here
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12, // Smaller label text
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5, // Smaller value text
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _enhancedInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.indigo.shade600,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80, // Fixed width for labels to align values
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
