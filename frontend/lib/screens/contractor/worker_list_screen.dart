import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/bottom_nav_contractor.dart';
import '../../services/api_service.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  int _currentIndex = 1;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _workers = [];
  int? _selectedSiteId;
  List<SiteSummary> _sites = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final sites = await _apiService.getSites();
      final allWorkers = await _apiService.getWorkers();
      setState(() {
        _sites = sites
            .map((s) => SiteSummary(id: s.id, name: s.name))
            .toList();
        _workers = allWorkers;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Worker Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_sites.isNotEmpty)
            Container(
              color: AppColors.primaryBlue,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Row(
                children: [
                  const Text(
                    "Site:",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: AppColors.primaryBlue,
                        value: _selectedSiteId,
                        hint: const Text(
                          "All sites",
                          style: TextStyle(color: Colors.white70),
                        ),
                        iconEnabledColor: Colors.white,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text("All sites", style: TextStyle(color: Colors.white)),
                          ),
                          ..._sites.map(
                                (s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(
                                s.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          setState(() => _selectedSiteId = value);
                          await _reloadWorkers();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            color: AppColors.primaryBlue,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search workers...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Active', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Checked In', 'checked_in'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Absent', 'absent'),
                  ],
                ),
              ],
            ),
          ),
          
          // Worker List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _reloadWorkers,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _workers.length,
                itemBuilder: (context, index) {
                  final w = _workers[index];
                  final name = w['full_name'] ?? w['username'] ?? 'Worker';
                  final phone = w['phone'] ?? '-';
                  final trust = (w['trust_score'] ?? 50).round();
                  final initials = _getInitials(name);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildWorkerCard(
                      name: name,
                      role: 'Worker',
                      trustScore: trust,
                      status: '—',
                      statusColor: AppColors.textGrey,
                      avatar: initials,
                      shiftTime: '—',
                      phone: phone,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavContractor(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/contractor-dashboard');
              break;
            case 1:
              // Already on worker list
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/inventory');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/contractor-profile');
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sites.isEmpty ? null : _onAddWorkerPressed,
        backgroundColor: AppColors.accentOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Worker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _reloadWorkers() async {
    try {
      final workers = await _apiService.getWorkers(siteId: _selectedSiteId);
      if (!mounted) return;
      setState(() => _workers = workers);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return (parts[0].isNotEmpty ? parts[0][0] : '') +
        (parts[1].isNotEmpty ? parts[1][0] : '');
  }

  Future<void> _onAddWorkerPressed() async {
    if (_selectedSiteId == null && _sites.isNotEmpty) {
      _selectedSiteId = _sites.first.id;
    }
    final siteId = _selectedSiteId;
    if (siteId == null) return;

    final allWorkers = await _apiService.getWorkers();
    if (!mounted) return;

    Map<String, dynamic>? selected;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Assign Worker to Site",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allWorkers.length,
                  itemBuilder: (context, index) {
                    final w = allWorkers[index];
                    final name = w['full_name'] ?? w['username'] ?? 'Worker';
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(w['phone'] ?? '-'),
                      onTap: () {
                        selected = w;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    try {
      await _apiService.addWorkerToSite(
        siteId: siteId,
        workerId: selected!['id'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker assigned successfully')),
      );
      await _reloadWorkers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard({
    required String name,
    required String role,
    required int trustScore,
    required String status,
    required Color statusColor,
    required String avatar,
    required String shiftTime,
    required String phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                icon: Icons.schedule,
                label: shiftTime,
              ),
              _buildInfoItem(
                icon: Icons.star_rounded,
                label: 'Trust: $trustScore%',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Call worker
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // View details
                  },
                  icon: const Icon(Icons.visibility, size: 16, color: Colors.white),
                  label: const Text('Details', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

}

class SiteSummary {
  final int id;
  final String name;

  SiteSummary({required this.id, required this.name});
}

    