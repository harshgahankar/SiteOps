import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_contractor.dart';

class AnomalyRadarScreen extends StatefulWidget {
  const AnomalyRadarScreen({super.key});

  @override
  State<AnomalyRadarScreen> createState() => _AnomalyRadarScreenState();
}

class _AnomalyRadarScreenState extends State<AnomalyRadarScreen> with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  int _currentIndex = 1; // Default to 1 since this is the Radar screen

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Anomaly Radar"),
        centerTitle: true,
        automaticallyImplyLeading: false, // This removes the back button
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Radar Visualizer
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Sweep
                  AnimatedBuilder(
                    animation: _sweepController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: RadarPainter(_sweepController.value),
                        size: const Size(320, 320),
                      );
                    },
                  ),
                  
                  // Concentric Circles
                  _buildRadarCircle(240),
                  _buildRadarCircle(160),
                  _buildRadarCircle(80),
                  
                  // Pulse Blips
                  _buildAnimatedBlip(top: 80, right: 70, color: AppColors.error, icon: Icons.error_rounded),
                  _buildAnimatedBlip(bottom: 100, left: 60, color: AppColors.accentOrange, icon: Icons.warning_rounded),
                  _buildAnimatedBlip(top: 150, left: 100, color: AppColors.info, icon: Icons.radar_rounded),
                  
                  // Center Text
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("92%", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1)),
                        Text("SAFETY SCORE", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 2. Alert List Header
            _buildAlertHeader(),

            const SizedBox(height: 16),

            // 3. Alerts
            _buildModernAlertCard(
              title: "Unauthorized Zone Access",
              location: "Sector 4 - Restricted Area",
              time: "2 mins ago",
              severity: "CRITICAL",
              color: AppColors.error,
              icon: Icons.no_accounts_rounded,
            ),
            const SizedBox(height: 16),
            _buildModernAlertCard(
              title: "High Temperature Detected",
              location: "Generator Unit B",
              time: "15 mins ago",
              severity: "WARNING",
              color: AppColors.accentOrange,
              icon: Icons.thermostat_rounded,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavContractor(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Standard Navigation Logic
          if (index == 0) Navigator.pushNamed(context, '/contractor-dashboard');
          if (index == 2) Navigator.pushNamed(context, '/inventory');
          if (index == 3) Navigator.pushNamed(context, '/contractor-profile');
        },
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildAlertHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LIVE ALERTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text("3 anomalies detected", style: TextStyle(fontSize: 14, color: AppColors.textDark.withOpacity(0.6))),
          ],
        ),
        TextButton(onPressed: () {}, child: const Text("Clear All", style: TextStyle(color: AppColors.textGrey))),
      ],
    );
  }

  Widget _buildRadarCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
      ),
    );
  }

  Widget _buildAnimatedBlip({double? top, double? bottom, double? left, double? right, required Color color, required IconData icon}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40 * _pulseController.value,
                height: 40 * _pulseController.value,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3 * (1 - _pulseController.value)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernAlertCard({required String title, required String location, required String time, required String severity, required Color color, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(severity, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(time, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(location, style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Radar Painter ---

class RadarPainter extends CustomPainter {
  final double angle;
  RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [Colors.transparent, AppColors.accentOrange.withOpacity(0.3), AppColors.accentOrange.withOpacity(0.5)],
        stops: const [0.0, 0.9, 1.0],
        transform: GradientRotation(angle * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
    
    final linePaint = Paint()
      ..color = AppColors.accentOrange.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final dx = center.dx + radius * math.cos(angle * math.pi * 2);
    final dy = center.dy + radius * math.sin(angle * math.pi * 2);
    canvas.drawLine(center, Offset(dx, dy), linePaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) => oldDelegate.angle != angle;
}