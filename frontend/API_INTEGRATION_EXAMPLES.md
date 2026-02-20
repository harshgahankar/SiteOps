# API Integration Examples

This guide shows you how to use the API service in your Flutter screens.

## Basic Pattern

Every API call follows this pattern:

```dart
// 1. Create a Future variable
late Future<DataType> _dataFuture;

// 2. Load data in initState
@override
void initState() {
  super.initState();
  _loadData();
}

void _loadData() {
  _dataFuture = ApiService().getSomeData();
}

// 3. Use FutureBuilder in build method
@override
Widget build(BuildContext context) {
  return FutureBuilder<DataType>(
    future: _dataFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return ErrorDisplay(
          message: 'Failed to load data',
          onRetry: _loadData,
        );
      }
      
      final data = snapshot.data!;
      return _buildYourUI(data);
    },
  );
}
```

## Example: Worker Dashboard with Real Data

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_display.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    setState(() {
      _dashboardFuture = _apiService.getWorkerDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              );
            }

            if (snapshot.hasError) {
              return ErrorDisplay(
                message: snapshot.error.toString(),
                onRetry: _loadDashboard,
              );
            }

            final dashboard = snapshot.data!;
            
            return RefreshIndicator(
              onRefresh: () async => _loadDashboard(),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: _buildDashboardContent(dashboard, user),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    Map<String, dynamic> dashboard,
    User? user,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Good ${_getGreeting()}",
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            user?.fullName ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 24),
          
          // Use real data from dashboard
          _buildActiveSiteCard(dashboard['active_site']),
          
          SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildTrustScoreCard(
                  user?.trustScore ?? 0,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  dashboard['today_status'],
                ),
              ),
            ],
          ),
          
          // Rest of your dashboard UI...
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
```

## Example: Check-In with API

```dart
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

class _CheckInScreenState extends State<CheckInScreen> {
  final ApiService _apiService = ApiService();
  bool _isVerifying = false;

  Future<void> _performCheckIn() async {
    setState(() => _isVerifying = true);

    try {
      // 1. Get location
      final position = await _getCurrentLocation();
      
      // 2. Verify biometric
      final biometricVerified = await _verifyBiometric();
      
      // 3. Get device info
      final deviceInfo = await _getDeviceInfo();
      
      // 4. Call API
      final attendance = await _apiService.checkIn(
        siteId: widget.siteId,
        locationLat: position.latitude,
        locationLng: position.longitude,
        deviceInfo: deviceInfo,
        biometricVerified: biometricVerified,
      );
      
      if (!mounted) return;
      
      // Success!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully checked in!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<Position> _getCurrentLocation() async {
    // Check permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    
    return await Geolocator.getCurrentPosition();
  }

  Future<bool> _verifyBiometric() async {
    final localAuth = LocalAuthentication();
    
    try {
      return await localAuth.authenticate(
        localizedReason: 'Verify your identity to check in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<String> _getDeviceInfo() async {
    // You can use device_info_plus package for this
    return 'Android Device'; // Simplified
  }
}
```

## Example: Inventory List

```dart
class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<InventoryItem>> _inventoryFuture;
  String? _selectedCategory;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    setState(() {
      _inventoryFuture = _apiService.getInventory(
        siteId: widget.siteId,
        category: _selectedCategory,
        status: _selectedStatus,
      );
    });
  }

  Future<void> _addInventoryItem() async {
    try {
      await _apiService.createInventoryItem({
        'site_id': widget.siteId,
        'item_name': 'Cement Bags',
        'category': 'Raw Material',
        'quantity': 100,
        'total_capacity': 500,
        'unit': 'Bags',
        'status': 'healthy',
      });
      
      _loadInventory(); // Refresh
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<InventoryItem>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Failed to load inventory',
              onRetry: _loadInventory,
            );
          }

          final items = snapshot.data!;
          
          if (items.isEmpty) {
            return EmptyState(
              message: 'No inventory items',
              subtitle: 'Add your first item to get started',
              icon: Icons.inventory_2_outlined,
              onAction: _addInventoryItem,
              actionLabel: 'Add Item',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadInventory(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildInventoryCard(item);
              },
            ),
          );
        },
      ),
    );
  }
}
```

## Example: Attendance History

```dart
class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Attendance>> _attendanceFuture;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _toDate = DateTime.now();
    _fromDate = _toDate!.subtract(Duration(days: 30));
    _loadAttendance();
  }

  void _loadAttendance() {
    setState(() {
      _attendanceFuture = _apiService.getAttendanceHistory(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance History'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: FutureBuilder<List<Attendance>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Failed to load attendance',
              onRetry: _loadAttendance,
            );
          }

          final records = snapshot.data!;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildAttendanceCard(record);
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance record) {
    return Card(
      child: ListTile(
        leading: Icon(
          record.isCheckedIn 
            ? Icons.login 
            : Icons.logout,
          color: record.isCheckedIn 
            ? AppColors.success 
            : AppColors.textGrey,
        ),
        title: Text(
          DateFormat('MMM dd, yyyy').format(record.checkInTime),
        ),
        subtitle: Text(
          '${DateFormat('hh:mm a').format(record.checkInTime)} - '
          '${record.checkOutTime != null ? DateFormat('hh:mm a').format(record.checkOutTime!) : 'Not checked out'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (record.locationVerified)
              Icon(Icons.location_on, size: 16, color: AppColors.success),
            if (record.biometricVerified)
              Icon(Icons.fingerprint, size: 16, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
```

## Tips

1. **Always handle errors** - Use try-catch or check snapshot.hasError
2. **Show loading states** - Use CircularProgressIndicator while loading
3. **Add pull-to-refresh** - Use RefreshIndicator for better UX
4. **Handle empty states** - Show EmptyState widget when no data
5. **Logout on 401** - If you get Unauthorized, logout the user
6. **Use Provider for shared state** - Access user info from AuthProvider

## Common Patterns

### Logout on Unauthorized Error
```dart
if (snapshot.hasError && 
    snapshot.error.toString().contains('Unauthorized')) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AuthProvider>().logout();
    Navigator.pushReplacementNamed(context, '/login');
  });
}
```

### Update Item
```dart
Future<void> _updateItem(int itemId, Map<String, dynamic> updates) async {
  try {
    await _apiService.updateInventoryItem(itemId, updates);
    _loadInventory(); // Refresh list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update failed: $e')),
    );
  }
}
```

### Delete Item with Confirmation
```dart
Future<void> _deleteItem(int itemId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Item'),
      content: Text('Are you sure you want to delete this item?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await _apiService.deleteInventoryItem(itemId);
      _loadInventory(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
```

Now you're ready to integrate all your screens with the backend! 🚀
