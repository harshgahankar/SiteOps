import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_worker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _siteInfo;
  Map<String, dynamic>? _status;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSite(),
      _refreshStatus(),
    ]);
  }

  Future<void> _loadSite() async {
    try {
      final response = await _apiService.getWorkerSite();
      if (!mounted) return;
      setState(() => _siteInfo = response);
    } catch (_) {
      // ignore, worker might not be assigned yet
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final response = await _apiService.getCurrentAttendanceStatus();
      if (!mounted) return;
      setState(() => _status = response);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.fullName ?? user?.username ?? "Worker";
    final siteName = _siteInfo?['site_name'] ?? "No active site";
    final siteLocation = _siteInfo?['site_location'] ?? "—";
    final contractorName = _siteInfo?['contractor_name'] ?? "—";
    final statusLabel = _status?['status'] ?? "not_checked_in";

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
                        "Welcome,",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 14, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
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
                      border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Active Site Card (High Fidelity)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        "Active Site",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      siteName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white60, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          siteLocation,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn("STATUS", statusLabel.toUpperCase()),
                        _buildInfoColumn("CONTRACTOR", contractorName),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Status Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: "TRUST SCORE",
                      content: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: 0.95,
                                  strokeWidth: 8,
                                  color: AppColors.success,
                                  backgroundColor: Color(0xFFF1F5F9),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              const Text(
                                "95",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Top 5%",
                              style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      title: "TODAY'S STATUS",
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(color: AppColors.textLight, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Not Checked In",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Next: 08:00 AM Shift",
                            style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/check-in'),
                  child: const Column(
                    children: [
                            Text(
                              "CHECK-IN NOW",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              "Requires Location Access",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54, 
                              ),
                            ),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Modern List Item (Wage Preview)
              _buildModernListItem(
                icon: Icons.account_balance_wallet_rounded,
                title: "Wage Preview",
                subtitle: "Calculated based on 24 days",
                onTap: () => Navigator.pushNamed(context, '/wage-summary'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavWorker(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Handle navigation
          if (index == 1) Navigator.pushNamed(context, '/attendance');
          if (index == 2) Navigator.pushNamed(context, '/wage-summary');
          if (index == 3) Navigator.pushNamed(context, '/worker-profile');
        },
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }

  Widget _buildStatusCard({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildModernListItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textGrey.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
