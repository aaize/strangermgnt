import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:face_camera/face_camera.dart';
import 'package:strangermgnt/amcdetails_screen.dart';
import 'package:strangermgnt/detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:strangermgnt/login_register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceCamera.initialize(); // Initialize face camera
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://menujxctgbuhjsiilssd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lbnVqeGN0Z2J1aGpzaWlsc3NkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMTQ1NjEsImV4cCI6MjA2NDc5MDU2MX0.MyaqrlEqJdwdwJO6PPH9hm3IkkH4BcLEGKvfE70L-OU',
  );

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  File? _profileImage;
  bool _hasCapturedImage = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onPhotoTaken(File? image) {
    if (image != null) {
      setState(() {
        _profileImage = image;
        _hasCapturedImage = true;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _profileImage = null;
      _hasCapturedImage = false;
    });
  }

  void _usePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Login successful!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A1A2F)  // A professional blue similar to the image
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/amclogo.png', // make sure logo.png exists and is declared in pubspec.yaml
                    height: 130,
                    width: 220,
                  ),
                  SizedBox(height: 80,),
                  // App Logo/Title



                  // Circular Face Capture Area
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _hasCapturedImage && _profileImage != null
                          ? Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                        width: 244,
                        height: 250,
                      )
                          : CircularFaceCaptureWidget(
                        onPhotoTaken: _onPhotoTaken,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Instructions Text
                  Text(
                    _hasCapturedImage
                        ? 'Face captured successfully!'
                        : 'Position your face in the circle above',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),


                  // Action Buttons (shown only when photo is taken)
                  if (_hasCapturedImage) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: CupertinoIcons.refresh,
                          label: '',
                          onTap: _retakePhoto,
                          isPrimary: false,

                        ),
                        _buildActionButton(
                          icon: CupertinoIcons.checkmark_alt,
                          label: '',
                          onTap: () {
                            if (_profileImage != null) {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => DetailScreen(profileImage: _profileImage!),
                                ),
                              );
                            } else {
                              print('No photo selected');
                            }
                          },
                          isPrimary: true,
                          color: Colors.green,
                        ),


                      ],
                    ),

                  ],
                  const SizedBox(height: 60),
                  _buildUsernameLoginButton(),

                  // Additional Login Options
                  if (!_hasCapturedImage) ...[
                    _buildAlternativeLoginButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color, // Accept custom color
  }) {
    final backgroundColor = color ?? (isPrimary ? Colors.white : Colors.white.withOpacity(0.2));
    final iconTextColor = color != null
        ? Colors.white
        : (isPrimary ? const Color(0xFF667eea) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconTextColor,
              size: 18,
            ),
            if (label.isNotEmpty) const SizedBox(width: 8),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: iconTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildUsernameLoginButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginRegisterScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, // White background
          borderRadius: BorderRadius.circular(30), // iOS-style pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Login with Username & Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0A1A2F), // Dark iOS background for text
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }



  Widget _buildAlternativeLoginButton() {
    return GestureDetector(
      onTap: () {
        // Alternative login method
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AMCDetailsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),


        child: Text(
          'About Us',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Circular Face Capture Widget - FIXED VERSION
class CircularFaceCaptureWidget extends StatefulWidget {
  final Function(File?) onPhotoTaken;

  const CircularFaceCaptureWidget({
    Key? key,
    required this.onPhotoTaken,
  }) : super(key: key);

  @override
  State<CircularFaceCaptureWidget> createState() => _CircularFaceCaptureWidgetState();
}

class _CircularFaceCaptureWidgetState extends State<CircularFaceCaptureWidget>
    with SingleTickerProviderStateMixin {
  FaceCameraController? _controller;
  File? _capturedImage;
  File? _croppedCircularImage;
  bool _hasCaptured = false;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _hasError = false;
  String _statusMessage = 'Initializing camera...';
  Color _statusColor = Colors.white;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Face positioning thresholds
  static const double centerXMin = 0.40;
  static const double centerXMax = 0.60;
  static const double centerYMin = 0.35;
  static const double centerYMax = 0.55;
  static const double minFaceWidth = 0.25;
  static const double minFaceHeight = 0.25;
  static const double maxFaceWidth = 0.40;
  static const double maxFaceHeight = 0.40;

  Timer? _captureTimer;
  Timer? _initTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeCamera();
  }

  void _initializeCamera() async {
    try {
      print('Starting camera initialization...');

      // Add timeout for initialization
      _initTimer = Timer(const Duration(seconds: 10), () {
        if (!_isCameraInitialized && mounted) {
          setState(() {
            _hasError = true;
            _statusMessage = 'Camera timeout. Tap to retry.';
            _statusColor = Colors.red;
          });
        }
      });

      _controller = FaceCameraController(
        autoCapture: true,
        defaultCameraLens: CameraLens.front,
        onCapture: (File? image) {
          print('Image captured: ${image?.path}');
          if (image != null && !_hasCaptured) {
            setState(() {
              _capturedImage = image;
            });
            _processCircularCapture();
          }
        },
        onFaceDetected: (Face? face) {
          if (!_hasCaptured && !_isProcessing && _isCameraInitialized) {
            _handleFaceDetection(face);
          }
        },
      );

      // Wait for camera to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        _initTimer?.cancel();
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'Position your face in the circle';
          _statusColor = Colors.white;
        });
        print('Camera initialized successfully');
      }
    } catch (e) {
      print('Camera initialization error: $e');
      if (mounted) {
        _initTimer?.cancel();
        setState(() {
          _hasError = true;
          _statusMessage = 'Camera error. Tap to retry.';
          _statusColor = Colors.red;
        });
      }
    }
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _isCameraInitialized = false;
      _statusMessage = 'Initializing camera...';
      _statusColor = Colors.white;
    });
    _initializeCamera();
  }

  void _handleFaceDetection(Face? face) {
    if (face == null) {
      _updateStatus('No face detected', Colors.red);
      _cancelCapture();
      return;
    }

    final bounds = face.boundingBox;
    final centerX = bounds.left + bounds.width / 2;
    final centerY = bounds.top + bounds.height / 2;

    final bool isWellPositioned = _isFaceWellPositioned(
        centerX, centerY, bounds.width, bounds.height);

    if (isWellPositioned) {
      _startCaptureSequence();
    } else {
      _provideFeedback(centerX, centerY, bounds.width, bounds.height);
      _cancelCapture();
    }
  }

  bool _isFaceWellPositioned(double centerX, double centerY, double width, double height) {
    return centerX >= centerXMin &&
        centerX <= centerXMax &&
        centerY >= centerYMin &&
        centerY <= centerYMax &&
        width >= minFaceWidth &&
        height >= minFaceHeight &&
        width <= maxFaceWidth &&
        height <= maxFaceHeight &&
        _isProperFaceRatio(width, height);
  }

  bool _isProperFaceRatio(double width, double height) {
    final ratio = width / height;
    return ratio >= 0.7 && ratio <= 1.3;
  }

  void _provideFeedback(double centerX, double centerY, double width, double height) {
    String message;
    Color color = Colors.orange;

    if (width < minFaceWidth || height < minFaceHeight) {
      message = 'Move closer';
    } else if (width > maxFaceWidth || height > maxFaceHeight) {
      message = 'Move back';
    } else if (!_isProperFaceRatio(width, height)) {
      message = 'Position properly';
    } else if (centerX < centerXMin) {
      message = 'Move right';
    } else if (centerX > centerXMax) {
      message = 'Move left';
    } else if (centerY < centerYMin) {
      message = 'Move down';
    } else if (centerY > centerYMax) {
      message = 'Move up';
    } else {
      message = 'Center your face';
    }

    _updateStatus(message, color);
  }

  void _startCaptureSequence() {
    if (_captureTimer != null) return;

    _updateStatus('Perfect! Hold steady...', Colors.green);
    _animationController.repeat(reverse: true);

    _countdownSeconds = 2;
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _statusMessage = 'Capturing in $_countdownSeconds...';
          _statusColor = Colors.green;
        });
        _countdownSeconds--;
      } else {
        timer.cancel();
        _captureTimer = null;
        _controller?.captureImage();
      }
    });
  }

  Future<void> _processCircularCapture() async {
    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Processing...';
        _statusColor = Colors.blue;
      });

      if (_capturedImage == null) {
        throw Exception('No captured image available');
      }

      final imageBytes = await _capturedImage!.readAsBytes();
      final ui.Image originalImage = await decodeImageFromList(imageBytes);

      final ui.Image circularImage = await _createCircularImage(originalImage);

      final ByteData? byteData = await circularImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = Directory.systemTemp;
      final imagePath = '${directory.path}/circular_face_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      if (await imageFile.exists()) {
        setState(() {
          _croppedCircularImage = imageFile;
          _hasCaptured = true;
          _isProcessing = false;
          _statusMessage = 'Captured!';
          _statusColor = Colors.green;
        });
        _animationController.stop();

        widget.onPhotoTaken(_croppedCircularImage);
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      print('Image processing error: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Failed. Try again.';
        _statusColor = Colors.red;
      });
      _cancelCapture();
    }
  }

  Future<ui.Image> _createCircularImage(ui.Image originalImage) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = originalImage.width < originalImage.height
        ? originalImage.width
        : originalImage.height;

    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final srcRect = Rect.fromCenter(
      center: Offset(originalImage.width / 2, originalImage.height / 2),
      width: size.toDouble(),
      height: size.toDouble(),
    );

    final dstRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

    canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(size, size);
  }

  void _cancelCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _countdownSeconds = 2;
    _animationController.stop();
    _animationController.reset();
  }

  void _updateStatus(String message, Color color) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _statusColor = color;
      });
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _initTimer?.cancel();
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasError ? _retryInitialization : null,
      child: Stack(
        children: [
          // Camera view - Only show when initialized and no error
          if (_isCameraInitialized && !_hasError && _controller != null)
            Positioned.fill(
              child: ClipOval(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 200,
                      height: 390,
                      child: SmartFaceCamera(
                        controller: _controller!,
                        messageBuilder: (context, face) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Loading indicator when camera is not initialized
          if (!_isCameraInitialized && !_hasError)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),

          // Error state
          if (_hasError)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

          // Circular overlay with face detection guide
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: CircularFaceGuidePainter(
                    scale: _scaleAnimation.value,
                    isActive: _animationController.isAnimating,
                  ),
                );
              },
            ),
          ),

          // Status message overlay
          Positioned(
            bottom: 10,
            left: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for circular face guide
class CircularFaceGuidePainter extends CustomPainter {
  final double scale;
  final bool isActive;

  CircularFaceGuidePainter({required this.scale, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width * 0.48) * scale;

    // Create a subtle inner circle guide
    final innerGuidePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.8, innerGuidePaint);

    // Circle outline paint
    final circlePaint = Paint()
      ..color = isActive ? Colors.green.withOpacity(0.9) : Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Inner glow effect
    final glowPaint = Paint()
      ..color = isActive ? Colors.green.withOpacity(0.4) : Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, circlePaint);

    _drawAlignmentGuides(canvas, center, radius);
  }

  void _drawAlignmentGuides(Canvas canvas, Offset center, double radius) {
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const crossSize = 8.0;
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      guidePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
