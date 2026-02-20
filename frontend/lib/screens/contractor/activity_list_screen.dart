import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/status_badge.dart';

class ActivityListScreen extends StatelessWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Site Activity"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All Activity", true),
                const SizedBox(width: 10),
                _buildFilterChip("Check-ins", false),
                const SizedBox(width: 10),
                _buildFilterChip("Completed", false),
                const SizedBox(width: 10),
                _buildFilterChip("Issues", false),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("TODAY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
          const SizedBox(height: 12),

          _buildActivityItem(
            name: "Rajesh Kumar",
            role: "Welder",
            action: "Checked In",
            time: "08:00 AM",
            statusColor: AppColors.success,
            avatarInitials: "RK",
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            name: "Sunil Verma",
            role: "Supervisor",
            action: "Site Inspection Completed",
            time: "08:45 AM",
            statusColor: AppColors.primaryBlue,
            avatarInitials: "SV",
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            name: "Amit Singh",
            role: "General Labor",
            action: "Missed Check-in",
            time: "09:00 AM",
            statusColor: AppColors.error,
            avatarInitials: "AS",
          ),
          
          const SizedBox(height: 24),
          const Text("YESTERDAY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          _buildActivityItem(
            name: "M. Thompson",
            role: "Project Manager",
            action: "Updated Inventory",
            time: "05:30 PM",
            statusColor: AppColors.textGrey,
            avatarInitials: "MT",
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textGrey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String role,
    required String action,
    required String time,
    required Color statusColor,
    required String avatarInitials,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: Text(avatarInitials, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(role, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(text: action, color: statusColor),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}