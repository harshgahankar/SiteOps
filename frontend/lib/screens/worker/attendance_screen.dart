import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_worker.dart'; // Ensure this import is correct

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int _selectedDayIndex = 3;
  int _currentIndex = 1; // Set to 0 (Home) or whichever tab this belongs to

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Attendance"),
        centerTitle: true,
        automaticallyImplyLeading: false, // 1. Removes the back button
        elevation: 0,
      ),
      // 2. Add the Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavWorker(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          
          // Navigation Mapping
          if (index == 0) Navigator.pushNamed(context, '/worker-dashboard');
          if (index == 2) Navigator.pushNamed(context, '/wage-summary');
          if (index == 3) Navigator.pushNamed(context, '/worker-profile');
        },
      ),
      body: Column(
        children: [
          // Modern Calendar Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(7, (index) {
                  bool isSelected = _selectedDayIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white.withOpacity(0.7) : AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${20 + index}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildModernAttendanceCard(
                  date: "Today, Oct 23",
                  site: "Oak Ridge Skyway",
                  timeIn: "08:05 AM",
                  timeOut: "--:--",
                  status: "On Shift",
                  statusColor: AppColors.accentOrange,
                  progress: 0.65,
                ),
                _buildModernAttendanceCard(
                  date: "Tue, Oct 22",
                  site: "Oak Ridge Skyway",
                  timeIn: "08:00 AM",
                  timeOut: "05:00 PM",
                  status: "Present",
                  statusColor: AppColors.success,
                  progress: 1.0,
                ),
                _buildModernAttendanceCard(
                  date: "Mon, Oct 21",
                  site: "Oak Ridge Skyway",
                  timeIn: "08:15 AM",
                  timeOut: "05:10 PM",
                  status: "Late",
                  statusColor: Colors.amber,
                  progress: 1.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAttendanceCard({
    required String date, 
    required String site, 
    required String timeIn, 
    required String timeOut, 
    required String status,
    required Color statusColor,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date, 
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(site, style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(), 
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModernTimeColumn("CLOCK IN", timeIn, Icons.login_rounded),
              _buildModernTimeColumn("CLOCK OUT", timeOut, Icons.logout_rounded),
              _buildModernTimeColumn("TOTAL", "9h", Icons.timer_outlined),
            ],
          ),
          if (progress < 1.0) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTimeColumn(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textGrey),
            const SizedBox(width: 6),
            Text(
              label, 
              style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          time, 
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)
        ),
      ],
    );
  }
}