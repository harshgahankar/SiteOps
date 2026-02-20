import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/contractor/contractor_profile_screen.dart';
import 'package:frontend/screens/worker/worker_profile_screen.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/worker/worker_dashboard.dart';
import 'screens/worker/check_in_screen.dart';
import 'screens/worker/wage_summary_screen.dart';
import 'screens/worker/attendance_screen.dart';
import 'screens/contractor/contractor_dashboard.dart';
import 'screens/contractor/inventory_screen.dart';
import 'screens/contractor/anomaly_radar_screen.dart';
import 'screens/contractor/activity_list_screen.dart';
import 'screens/contractor/worker_list_screen.dart';
import 'screens/contractor/register_worker_face_screen.dart';

void main() {
  runApp(
    // Wrap app with Provider for state management
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SiteOpsApp(),
    ),
  );
}

class SiteOpsApp extends StatelessWidget {
  const SiteOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiteOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/worker-dashboard': (context) => const WorkerDashboard(),
        '/check-in': (context) => const CheckInScreen(),
        '/wage-summary': (context) => const WageSummaryScreen(),
        '/attendance': (context) => const AttendanceHistoryScreen(),
        '/contractor-dashboard': (context) => const ContractorDashboard(),
        '/inventory': (context) => const InventoryScreen(),
        '/anomaly-radar': (context) => const AnomalyRadarScreen(),
        '/worker-list': (context) => const WorkerListScreen(),
        '/contractor-profile': (context) => const ContractorProfileScreen(),
        '/worker-profile' : (context) => const WorkerProfileScreen(),
        '/register-worker-face': (context) => const RegisterWorkerFaceScreen(),
      },
    );
  }
}
