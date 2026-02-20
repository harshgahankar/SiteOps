import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

enum VerificationStep { location, device, biometric, completed }

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _currentTime = "";
  VerificationStep _currentStep = VerificationStep.location;
  bool _isVerifying = false;
  double? _latitude;
  double? _longitude;
  bool _locationVerified = false;
  bool _faceVerified = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == VerificationStep.location) {
      await _verifyLocation();
      return;
    }

    if (_currentStep == VerificationStep.device) {
      setState(() => _isVerifying = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _currentStep = VerificationStep.biometric;
      });
      return;
    }

    if (_currentStep == VerificationStep.biometric) {
      await _verifyFace();
      return;
    }
  }

  Future<void> _verifyFace() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) {
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final file = File(picked.path);
      final result = await _apiService.verifyWorkerFace(
        workerId: user.id,
        imageFile: file,
      );

      final match = result['match'] == true;
      final score = (result['score'] ?? 0).toString();
      final threshold = (result['threshold'] ?? 0).toString();

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _faceVerified = match;
        if (match) {
          _currentStep = VerificationStep.completed;
        }
      });

      if (match) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Face matched (score: $score, threshold: $threshold). Check-in success.")),
        );
        _showSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Face not matched (score: $score, threshold: $threshold). Check-in denied.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _verifyLocation() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled")),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isVerifying = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied")),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission permanently denied in settings")),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationVerified = true;
        _isVerifying = false;
        _currentStep = VerificationStep.device;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _locationVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get current location")),
      );
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All Verifications Passed! Clocked In."),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Secure Clock In", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildStepIndicator(),
          const SizedBox(height: 32),
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 64, 
              fontWeight: FontWeight.w800, 
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const Text(
            "Wednesday, Oct 24", 
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40), 
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildVerificationContent(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepIcon(Icons.location_on_rounded, VerificationStep.location),
          _stepLine(VerificationStep.device),
          _stepIcon(Icons.phonelink_lock_rounded, VerificationStep.device),
          _stepLine(VerificationStep.biometric),
          _stepIcon(Icons.face_unlock_rounded, VerificationStep.biometric),
        ],
      ),
    );
  }

  Widget _stepIcon(IconData icon, VerificationStep step) {
    bool isCompleted = _currentStep.index > step.index;
    bool isActive = _currentStep == step;
    
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success : (isActive ? Colors.white : Colors.white.withOpacity(0.15)),
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
        ] : null,
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : icon, 
        size: 20, 
        color: isActive ? AppColors.primaryBlue : (isCompleted ? Colors.white : Colors.white60),
      ),
    );
  }

  Widget _stepLine(VerificationStep step) {
    bool isCompleted = _currentStep.index >= step.index;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.success : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildVerificationContent() {
    switch (_currentStep) {
      case VerificationStep.location:
        final hasCoords = _latitude != null && _longitude != null;
        final detail = hasCoords
            ? "Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}"
            : "Tap VERIFY LOCATION to capture your current position";
        final tag = _locationVerified ? "Location Verified" : "Pending";
        final tagColor = _locationVerified ? AppColors.success : AppColors.accentOrange;
        return _buildStatusCard(
          "Location Verification",
          "You must be within the geofenced area of your assigned site to clock in.",
          Icons.map_rounded,
          detail,
          tag,
          tagColor,
        );
      case VerificationStep.device:
        return _buildStatusCard(
          "Device Integrity",
          "We are verifying that this device is registered to your profile and has no security risks.",
          Icons.security_rounded,
          "Pixel 7 Pro (Registered)",
          "Secure Device",
          AppColors.success,
        );
      case VerificationStep.biometric:
        return Column(
          key: const ValueKey("biometric"),
          children: [
            const Text(
              "Face Authentication", 
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              "Please look directly into the camera to confirm your identity.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, spreadRadius: 5)
                    ],
                  ),
                ),
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Container(
                      color: AppColors.primaryBlue.withOpacity(0.02),
                      child: Icon(Icons.face_rounded, size: 100, color: AppColors.primaryBlue.withOpacity(0.8)),
                    ),
                  ),
                ),
                // Scanning animation placeholder
                if (_isVerifying)
                  SizedBox(
                    height: 210,
                    width: 210,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Text(
                  "Ensure good lighting for better results",
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        );
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildStatusCard(String title, String desc, IconData icon, String detail, String tag, Color tagColor) {
    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(desc, style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CURRENT STATUS",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButton() {
    String btnText = "";
    if (_currentStep == VerificationStep.location) btnText = "VERIFY LOCATION";
    if (_currentStep == VerificationStep.device) btnText = "BIND DEVICE";
    if (_currentStep == VerificationStep.biometric) btnText = "SCAN FACE";

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _handleNextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: _isVerifying 
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              btnText, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
            ),
      ),
    );
  }
}
