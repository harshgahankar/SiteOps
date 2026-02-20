import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_contractor.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ContractorDashboard extends StatefulWidget {
  const ContractorDashboard({super.key});

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  Timer? _timer;
  List<Map<String, dynamic>> _liveWages = [];

  @override
  void initState() {
    super.initState();
    _loadLiveWages();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadLiveWages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLiveWages() async {
    try {
      final data = await _apiService.getSiteLiveWages();
      if (!mounted) return;
      setState(() => _liveWages = data);
    } catch (_) {
      // ignore for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final displayName = user?.fullName ?? user?.username ?? "Contractor";

    final activeWorkers = _liveWages.where((w) => w['status'] == 'checked_in').length;
    final totalWorkers = _liveWages.map((w) => w['worker_id']).toSet().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 14, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.1)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. High-Fidelity Project Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(28),
                  image: DecorationImage(
                    image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
                    opacity: 0.05,
                    repeat: ImageRepeat.repeat,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            "Phase 3 - Structural",
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Current Projects",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white60, size: 14),
                        const SizedBox(width: 8),
                        const Text(
                          "Live worker activity",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Active Workers",
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "$activeWorkers / $totalWorkers",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: totalWorkers == 0 ? 0 : activeWorkers / totalWorkers,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Stat Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "QUICK STATS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.textGrey),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "Active Workers",
                      value: activeWorkers.toString(),
                      total: totalWorkers.toString(),
                      icon: Icons.people_alt_rounded,
                      color: AppColors.info,
                      route: '/worker-list',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: "Live Alerts",
                      value: "03",
                      icon: Icons.notification_important_rounded,
                      color: AppColors.error,
                      route: '/anomaly-radar',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. Live Activity Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "LIVE ACTIVITY",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/anomaly-radar'),
                    child: Row(
                      children: [
                        const Text("View Radar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _buildAlertItem(
                title: "Safety Violation Detected",
                subtitle: "Zone B - Helmet missing",
                time: "10m ago",
                icon: Icons.person_off_rounded,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              _buildAlertItem(
                title: "Material Delay",
                subtitle: "Cement shipment pending",
                time: "1h ago",
                icon: Icons.local_shipping_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavContractor(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Handle navigation
          if (index == 1) Navigator.pushNamed(context, '/anomaly-radar');
          if (index == 2) Navigator.pushNamed(context, '/inventory');
          if (index == 3) Navigator.pushNamed(context, '/contractor-profile');
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {},
        backgroundColor: AppColors.accentOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? total,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                if (total != null)
                  Text(
                    "/$total",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGrey.withValues(alpha: 0.5)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textGrey, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
