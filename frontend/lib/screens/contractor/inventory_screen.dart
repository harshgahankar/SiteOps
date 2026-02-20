import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_contractor.dart'; // Ensure this import matches your project structure

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 2; // Inventory is typically the 3rd item (index 2)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Site Inventory"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () {},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {},
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.add_rounded),
      ),
      // Adding the Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavContractor(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          
          // Navigation Logic
          if (index == 0) Navigator.pushNamed(context, '/contractor-dashboard');
          if (index == 1) Navigator.pushNamed(context, '/anomaly-radar');
          if (index == 3) Navigator.pushNamed(context, '/contractor-profile');
          // index 2 is current screen
        },
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search materials, tools...",
                  hintStyle: TextStyle(color: AppColors.textGrey.withOpacity(0.6), fontWeight: FontWeight.w400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),

          // 2. Inventory List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildSectionHeader("CRITICAL STOCK", "2 items need attention"),
                const SizedBox(height: 16),
                _buildModernInventoryItem(
                  name: "Cement Bags (Grade 53)",
                  category: "Raw Material",
                  quantity: "45",
                  total: "500",
                  unit: "Bags",
                  status: "Low Stock",
                  color: AppColors.error,
                  icon: Icons.inventory_2_rounded,
                ),
                const SizedBox(height: 16),
                _buildModernInventoryItem(
                  name: "Safety Helmets",
                  category: "Safety Gear",
                  quantity: "12",
                  total: "50",
                  unit: "Units",
                  status: "Reorder",
                  color: AppColors.accentOrange,
                  icon: Icons.construction_rounded,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader("IN STOCK", "12 active items"),
                const SizedBox(height: 16),
                _buildModernInventoryItem(
                  name: "Steel Rods (12mm)",
                  category: "Reinforcement",
                  quantity: "1,200",
                  unit: "Kg",
                  status: "Healthy",
                  color: AppColors.success,
                  icon: Icons.architecture_rounded,
                ),
                const SizedBox(height: 16),
                _buildModernInventoryItem(
                  name: "Bricks (Red Clay)",
                  category: "Masonry",
                  quantity: "5,000",
                  unit: "Units",
                  status: "Healthy",
                  color: AppColors.success,
                  icon: Icons.grid_view_rounded,
                ),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Methods (Remain the same as your original) ---

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textGrey.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildModernInventoryItem({
    required String name,
    required String category,
    required String quantity,
    String? total,
    required String unit,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    double? progress;
    if (total != null) {
      progress = double.parse(quantity.replaceAll(',', '')) / double.parse(total.replaceAll(',', ''));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
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
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(category, style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: quantity, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                        TextSpan(text: " $unit", style: TextStyle(color: AppColors.textGrey.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}