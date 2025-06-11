import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'success_screen.dart';

class DetailScreen extends StatefulWidget {
  final File? profileImage;

  const DetailScreen({Key? key, required this.profileImage}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isPhoneVerified = false;
  bool _phoneVerificationAttempted = false;
  bool _isPhoneEditable = true;
  final TextEditingController _otpController = TextEditingController();
  bool _showOTPField = false;
  String _verificationId = '';



  String? _selectedDepartment;
  String? _selectedPurpose;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isSubmitting = false;
  //bool _isPhoneVerified = false; // Track phone verification status
  //String? _verificationId; // Store verification ID for OTP verification
  //bool _phoneVerificationAttempted = false; // Track if verification attempted
  bool _phoneVerificationFailed = false; // Track if verification failed
  // Place this at the top (class level)
  String? _selectedVisitedTo; // display name
  final Map<TextEditingController, FocusNode> _focusNodes = {};
  final FocusNode _phoneFocusNode = FocusNode();
  String? _selectedVisitorType;
  final List<String> _visitorTypes = ['PARENT', 'DELIVERY', 'STUDENT','OTHER'];



  final Map<String, String> _userMap = {
    'Mr. Gunasekar MCA Dept': 'MCA20308',
    'Dr. Ayesha Siddiqui (HOD - MCA)': 'MCA30110',
    'Ms. Priya Sharma MBA': 'MBA40207',
    'Mr. Ramesh BCA': 'BCA50125',
    'Dr. Arvind PhD CS': 'PHD60213',
  };

  final List<String> _purposes = [
    'To meet the Principal',
    'To visit Admin Block',
    'To attend a seminar/workshop',
    'To collect certificates/documents',
    'To inquire about admissions',
    'To meet a faculty member',
    'To attend an interview',
    'For an academic project discussion',
    'To visit the library',
    'Others'
  ];



  final List<String> _departments = [
    'MCA (Master of Computer Applications)',
    'MTech (Master of Technology)',
    'BCA (Bachelor of Computer Applications)',
    'MBA (Master of Business Administration)',
    'MSc Computer Science',
    'B.Tech (Bachelor of Technology)',
    'PhD (Doctor of Philosophy)',
    'M.Com (Master of Commerce)',
    'BBA (Bachelor of Business Administration)',
    'Other'
  ];

  @override
  void initState() {

    super.initState();
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {}); // Triggers AnimatedContainer rebuild on focus change
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }


  Future<void> _showOTPDialog() async {
    final TextEditingController otpController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: TextField(
            controller: otpController,
            decoration: const InputDecoration(hintText: 'OTP'),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Verify'),
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.isNotEmpty && _verificationId != null) {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!,
                    smsCode: otp,
                  );

                  try {
                    await FirebaseAuth.instance.signInWithCredential(credential);
                    setState(() {
                      _isPhoneVerified = true;
                      _phoneVerificationAttempted = true;
                      _phoneVerificationFailed = false;
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    setState(() {
                      _isPhoneVerified = false;
                      _phoneVerificationAttempted = true;
                      _phoneVerificationFailed = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid OTP')),
                    );
                  }
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _phoneVerificationAttempted = true;
                  _phoneVerificationFailed = true;
                  _isPhoneVerified = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number before proceeding.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedDepartment != null) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call delay or actual submission
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Registration Successful!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Welcome, ${_nameController.text}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to success screen or next screen
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => SuccessScreen(
              profileImage: widget.profileImage!,
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              purpose: _selectedPurpose ?? '',
              department: _selectedDepartment!,
              visitedToDisplay: _selectedVisitedTo!,
              visitedToUsername: _userMap[_selectedVisitedTo]!,
              visitedType: _selectedVisitorType!,
            ),
          ),
        );
      }
    } else if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a department'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(),

                  // Scrollable Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Profile Image Section
                            _buildProfileSection(),

                            const SizedBox(height: 40),

                            // Form Fields
                            _buildInputField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: CupertinoIcons.person_fill,
                              helperText: "",
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z. ]')),
                              ],
                            ),



                            const SizedBox(height: 24),

                            _buildPhoneInputField(),

                            // Send OTP Button

                            const SizedBox(height: 24),

                            _buildInputField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: CupertinoIcons.mail_solid,
                              keyboardType: TextInputType.emailAddress,
                              helperText: 'Optional', // shows below the field
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                }
                                return null; // valid if empty or valid email
                              },
                            ),

                            const SizedBox(height: 24),
                            _buildVisitorTypeDropdown(),
                            const SizedBox(height: 24),

                            _buildPurposeDropdown(),

                            const SizedBox(height: 24),

                            // Department Dropdown
                            _buildDepartmentDropdown(),



                            const SizedBox(height: 30),

                            _buildVisitedToDropdown(),
                            const SizedBox(height: 40),

                            // Submit Button
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _sendOTP() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    try {
      setState(() {
        _showOTPField = true; // Show OTP field below phone input
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          setState(() {
            _isPhoneVerified = true;
            _phoneVerificationAttempted = true;
            _showOTPField = false;
            _isPhoneEditable = false; // 🔒 Lock the field
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
          setState(() {
            _phoneVerificationAttempted = true;
            _isPhoneVerified = false;
            _showOTPField = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
    }
  }


  Widget _buildPhoneInputField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone field with icon and verify button
          Row(
            children: [
              Icon(
                CupertinoIcons.phone,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  enabled: _isPhoneEditable,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                      return 'Enter a valid 10-digit number';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    errorStyle: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              (_phoneVerificationAttempted && _isPhoneVerified)
                  ? const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Colors.greenAccent,
                size: 24,
              )
                  : GestureDetector(
                onTap: () async {
                  await _sendOTP();
                  setState(() {
                    _phoneVerificationAttempted = true;
                    _isPhoneVerified = false;
                    _showOTPField = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // Underline animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: (_phoneFocusNode.hasFocus || _phoneController.text.isNotEmpty)
                  ? LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // OTP input
          if (_showOTPField && !_isPhoneVerified) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  CupertinoIcons.lock,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 1.2,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final otp = _otpController.text.trim();
                  if (otp.length == 6) {
                    try {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: _verificationId,
                        smsCode: otp,
                      );
                      await FirebaseAuth.instance.signInWithCredential(credential);
                      setState(() {
                        _isPhoneVerified = true;
                        _showOTPField = false;
                        _isPhoneEditable = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number verified!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid OTP: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a 6-digit OTP')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // Change phone number link
          if (_isPhoneVerified)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isPhoneEditable = true;
                    _isPhoneVerified = false;
                    _phoneVerificationAttempted = false;
                    _phoneController.clear();
                    _otpController.clear();
                    _showOTPField = false;
                  });
                },
                child: const Text(
                  "Change phone number?",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }




  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(

            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Complete Your Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 52), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Profile Image with Enhanced Styling
        if (widget.profileImage != null)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.file(
                widget.profileImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Colors.green.shade300,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Face Verified',
                style: TextStyle(
                  color: Colors.green.shade200,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildVisitedToDropdown() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.person_2,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField2<String>(
                  value: _selectedVisitedTo,
                  isExpanded: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Visited To',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    errorStyle: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(40),
                      thickness: MaterialStateProperty.all(6),
                      thumbVisibility: MaterialStateProperty.all(true),
                    ),
                  ),
                  iconStyleData: IconStyleData(
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                  items: _userMap.keys.map((String displayName) {
                    return DropdownMenuItem<String>(
                      value: displayName,
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedVisitedTo = newValue;
                    });
                  },
                  validator: (value) => null,
                ),
              ),
            ],
          ),

          // Underline animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 1.2,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: _selectedVisitedTo != null
                  ? LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    required String helperText,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    // Assign or reuse a focus node
    _focusNodes.putIfAbsent(controller, () {
      final node = FocusNode();
      node.addListener(() => setState(() {})); // Redraw on focus change
      return node;
    });

    final focusNode = _focusNodes[controller]!;

    return Container(
      width: MediaQuery.of(context).size.width * 0.9, // Uniform width for all fields
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  inputFormatters: inputFormatters,
                  obscureText: obscureText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.left, // Left-align text
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          // Animated underline
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 1.2,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: (focusNode.hasFocus || controller.text.isNotEmpty)
                  ? LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildDepartmentDropdown() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.building_2_fill,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    hint: Text(
                      'Select Department',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    items: _departments.map((String department) {
                      return DropdownMenuItem<String>(
                        value: department,
                        child: Row(
                          children: [

                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                department,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDepartment = newValue;
                      });
                    },
                    buttonStyleData: const ButtonStyleData(
                      height: 50,
                      padding: EdgeInsets.only(left: 0, right: 8), // No left padding to align with icon
                    ),
                    iconStyleData: IconStyleData(
                      icon: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 300,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      offset: const Offset(0, -5),
                      scrollbarTheme: ScrollbarThemeData(
                        radius: const Radius.circular(40),
                        thickness: MaterialStateProperty.all<double>(6),
                        thumbVisibility: MaterialStateProperty.all<bool>(true),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 48,
                      padding: EdgeInsets.only(left: 16, right: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Gradient underline
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 1.2,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: _selectedDepartment != null
                  ? LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }







  Widget _buildPurposeDropdown() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField2<String>(
                  value: _selectedPurpose,
                  isExpanded: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Purpose of Visit',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    errorStyle: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(40),
                      thickness: MaterialStateProperty.all(6),
                      thumbVisibility: MaterialStateProperty.all(true),
                    ),
                  ),
                  iconStyleData: IconStyleData(
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                  items: _purposes.map((String purpose) {
                    return DropdownMenuItem<String>(
                      value: purpose,
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              purpose,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (BuildContext context) {
                    return _purposes.map((String purpose) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          purpose,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPurpose = newValue;
                    });
                  },
                  validator: (value) => null,
                ),
              ),
            ],
          ),

          // Gradient underline
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 1.2,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: _selectedPurpose != null
                  ? LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF667eea),
          disabledBackgroundColor: Colors.white.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 23,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF667eea).withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Submitting...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Complete Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );


  }
  Widget _buildVisitorTypeDropdown() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.person_crop_circle_badge_checkmark,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: _selectedVisitorType,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    hint: Text(
                      'Select Visitor Type',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    items: _visitorTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                type,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVisitorType = newValue;
                      });
                    },
                    buttonStyleData: const ButtonStyleData(
                      height: 50,
                      padding: EdgeInsets.only(left: 0, right: 8),
                    ),
                    iconStyleData: IconStyleData(
                      icon: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      offset: const Offset(0, -5),
                      scrollbarTheme: ScrollbarThemeData(
                        radius: const Radius.circular(40),
                        thickness: MaterialStateProperty.all<double>(6),
                        thumbVisibility: MaterialStateProperty.all<bool>(true),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 48,
                      padding: EdgeInsets.only(left: 16, right: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Optional underline
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 1.2,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: _selectedVisitorType != null
                  ? LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ],
              )
                  : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}