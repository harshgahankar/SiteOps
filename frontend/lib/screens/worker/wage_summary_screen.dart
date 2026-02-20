import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_worker.dart'; 

class WageSummaryScreen extends StatefulWidget {
  const WageSummaryScreen({super.key});

  @override
  State<WageSummaryScreen> createState() => _WageSummaryScreenState();
}

class _WageSummaryScreenState extends State<WageSummaryScreen> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Wages"),
        automaticallyImplyLeading: false, // Prevents default back button
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Modern Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AVAILABLE FOR WITHDRAWAL",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "\$840.50",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text("Withdraw", style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.history_rounded, color: Colors.white),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // 2. Weekly Activity Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WEEKLY ACTIVITY",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Oct 18 - 24",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "\$452.00 Earned",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Modern Bar Chart
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildModernBar("M", 0.4),
                  _buildModernBar("T", 0.6),
                  _buildModernBar("W", 0.85, isSelected: true),
                  _buildModernBar("T", 0.35),
                  _buildModernBar("F", 0.55),
                  _buildModernBar("S", 0.75),
                  _buildModernBar("S", 0.25),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 3. Recent Shift Logs
            const Text(
              "RECENT SHIFT LOGS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textGrey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildModernWageTile("Oct 23", "Oak Ridge Skyway", "9.0 hrs", "\$135.00"),
            _buildModernWageTile("Oct 22", "City Center Mall", "8.0 hrs", "\$120.00"),
            _buildModernWageTile("Oct 21", "Oak Ridge Skyway", "8.5 hrs", "\$127.50"),
            _buildModernWageTile("Oct 20", "Oak Ridge Skyway", "9.2 hrs", "\$138.00"),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavWorker(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          
          // Navigation Mapping
          if (index == 0) Navigator.pushNamed(context, '/worker-dashboard');
          if (index == 1) Navigator.pushNamed(context, '/attendance');
          if (index == 3) Navigator.pushNamed(context, '/worker-profile');
        },
      ),
    );
  }

  Widget _buildModernBar(String day, double heightPct, {bool isSelected = false}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 120 * heightPct,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentOrange : AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(color: AppColors.accentOrange.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
            ] : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day, 
          style: TextStyle(
            color: isSelected ? AppColors.textDark : AppColors.textGrey, 
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModernWageTile(String date, String site, String hours, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.work_outline_rounded, size: 20, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site, 
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  "$date • $hours worked", 
                  style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            amount, 
            style: const TextStyle(
              fontWeight: FontWeight.w800, 
              fontSize: 16, 
              color: AppColors.success,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}