import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingAutoLogin = true; // New flag for auto-login check

  final _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Check for auto-login first, then start animation
    _checkAutoLogin();
  }

  // Check if saved credentials exist and auto-login
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('savedUsername') ?? '';
      final savedPassword = prefs.getString('savedPassword') ?? '';

      if (savedUsername.isNotEmpty && savedPassword.isNotEmpty) {
        // Attempt auto-login with saved credentials
        await _performLogin(savedUsername, savedPassword, isAutoLogin: true);
      } else {
        // No saved credentials, show the login form
        setState(() => _isCheckingAutoLogin = false);
        _animationController.forward();
      }
    } catch (e) {
      // Error checking credentials, show login form
      setState(() => _isCheckingAutoLogin = false);
      _animationController.forward();
    }
  }

  // Perform login operation
  Future<void> _performLogin(String username, String password, {bool isAutoLogin = false}) async {
    if (!isAutoLogin) {
      setState(() => _isLoading = true);
    }

    try {
      final userRef = _firestore.collection('users').doc(username);
      final doc = await userRef.get();

      if (!doc.exists) throw Exception('User not found');
      if (doc['password'] != password) throw Exception('Incorrect password');

      // Save credentials locally on successful login (if not auto-login)
      if (!isAutoLogin) {
        await _saveCredentials(username, password);
      }

      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userId: username)),
        );
      }
    } catch (e) {
      if (isAutoLogin) {
        // Auto-login failed, clear saved credentials and show login form
        await _clearSavedCredentials();
        setState(() => _isCheckingAutoLogin = false);
        _animationController.forward();
      } else {
        // Manual login failed, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } finally {
      if (!isAutoLogin && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Save username and password locally
  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedUsername', username);
    await prefs.setString('savedPassword', password);
  }

  // Clear saved credentials
  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedUsername');
    await prefs.remove('savedPassword');
  }

  // Load saved username and password and fill text fields
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('savedUsername') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';

    if (savedUsername.isEmpty || savedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved credentials found')),
      );
      return;
    }

    setState(() {
      _usernameController.text = savedUsername;
      _passwordController.text = savedPassword;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials loaded')),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      // Login logic
      await _performLogin(username, password);
    } else {
      // Register logic
      setState(() => _isLoading = true);
      try {
        final userRef = _firestore.collection('users').doc(username);
        final doc = await userRef.get();

        if (doc.exists) throw Exception('Username already exists');

        await userRef.set({
          'username': username,
          'password': password,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Save credentials locally on successful registration
        await _saveCredentials(username, password);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userId: username)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking for auto-login
    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1A2F),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(
                color: Colors.white,
                radius: 20,
              ),
              SizedBox(height: 16),
              Text(
                'Checking saved credentials...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFF0A1A2F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo Section
                  Container(
                    height: 130,
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/amclogo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business,
                            size: 60,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 49),

                  // Welcome Text
                  Text(
                    _isLogin ? 'Faculty Login!' : 'Create Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _isLogin
                        ? 'Sign in to continue'
                        : 'Join us and get started',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Form Section
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username Field
                          _buildInputField(
                            controller: _usernameController,
                            hint: 'Username',
                            icon: Icons.person_outline,
                            validator: (value) =>
                            value!.isEmpty ? 'Enter username' : null,
                          ),

                          const SizedBox(height: 20),

                          // Password Field
                          _buildInputField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) =>
                            value!.length < 6 ? 'Min 6 characters' : null,
                          ),

                          const SizedBox(height: 35),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0A1A2F),
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(
                                color: Color(0xFF0A1A2F),
                              )
                                  : Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Load saved credentials button (now secondary option)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: _loadSavedCredentials,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white70),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Load saved credentials',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Toggle Button
                  TextButton(
                    onPressed: _toggleMode,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                          ),
                          TextSpan(
                            text: _isLogin ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
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
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 22,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white.withOpacity(0.7),
            size: 22,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        errorStyle: TextStyle(
          color: Colors.red.shade300,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}