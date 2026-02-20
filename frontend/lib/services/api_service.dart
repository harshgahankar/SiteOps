import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/site.dart';
import '../models/attendance.dart';
import '../models/inventory.dart';
import '../models/alert.dart';

class ApiService {
  // Change this based on your setup
  // For Android emulator: use 10.0.2.2
  // For iOS simulator: use localhost
  // For physical device: use your computer's IP address
  // Current Wi-Fi IPv4: 172.18.1.34 (from ipconfig)
  static const String baseUrl = 'http://172.18.1.34:8000/api';
  
  final storage = const FlutterSecureStorage();

  // Auth token management
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle HTTP errors
  void _handleError(http.Response response) {
  String message = "Request failed";

  try {
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      // FastAPI errors can be:
      // {"detail":"some error"}
      // {"detail":[{...}]}
      if (decoded is Map<String, dynamic>) {
        final detail = decoded["detail"];

        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          // Extract first validation error
          if (detail.isNotEmpty && detail[0] is Map) {
            message = detail[0]["msg"]?.toString() ?? message;
          } else {
            message = detail.toString();
          }
        } else if (decoded["message"] != null) {
          message = decoded["message"].toString();
        } else {
          message = decoded.toString();
        }
      } else {
        message = decoded.toString();
      }
    } else {
      message = "Empty response from server";
    }
  } catch (e) {
    message = "Request failed: ${response.body}";
  }

  throw Exception(message);
}

  // ==================== AUTH ENDPOINTS ====================

  Future<Map<String, dynamic>> register({
  required String username,
  required String email,
  required String password,
  required String fullName,
  required String role,
  String? phone,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: await _getHeaders(includeAuth: false),
    body: jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      'phone': phone,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    if (response.body.isEmpty) {
      throw Exception("Server returned empty response");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    // Save token ONLY if it exists
    if (decoded.containsKey("access_token")) {
      await saveToken(decoded["access_token"]);
    }

    return decoded;
  } else {
    _handleError(response);
    throw Exception("Register failed");
  }
}

  Future<Map<String, dynamic>> login({
  required String username,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    },
    body: {
      'username': username,
      'password': password,
    },
  );

  if (response.statusCode == 200) {
    if (response.body.isEmpty) {
      throw Exception("Server returned empty response");
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (!decoded.containsKey("access_token")) {
      throw Exception("Login response missing access_token");
    }

    await saveToken(decoded["access_token"]);
    return decoded;
  } else {
    _handleError(response);
    throw Exception("Login failed");
  }
}

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      _handleError(response);
      throw Exception('Failed to get user info');
    }
  }

  Future<void> logout() async {
    await deleteToken();
  }

  // ==================== WORKER ENDPOINTS ====================

  Future<Map<String, dynamic>> getWorkerDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/worker/dashboard'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _handleError(response);
      throw Exception('Failed to load dashboard');
    }
  }

  Future<Attendance> checkIn({
    required int siteId,
    required double locationLat,
    required double locationLng,
    required String deviceInfo,
    required bool biometricVerified,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/worker/check-in'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'site_id': siteId,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'device_info': deviceInfo,
        'biometric_verified': biometricVerified,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Attendance.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Check-in failed');
    }
  }

  Future<Map<String, dynamic>> verifyWorkerFace({
    required int workerId,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/worker/verify-face');
    final headers = await _getHeaders();
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.fields['worker_id'] = workerId.toString();
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception("Empty response from server");
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception("Invalid response format");
      }
      return decoded;
    } else {
      _handleError(response);
      throw Exception('Face verification failed');
    }
  }

  Future<Map<String, dynamic>> registerWorkerFace({
    required int workerId,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/worker/register-face');
    final headers = await _getHeaders();
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.fields['worker_id'] = workerId.toString();
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception("Empty response from server");
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception("Invalid response format");
      }
      return decoded;
    } else {
      _handleError(response);
      throw Exception('Face registration failed');
    }
  }

  Future<Attendance> checkOut({required int attendanceId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/worker/check-out'),
      headers: await _getHeaders(),
      body: jsonEncode({'attendance_id': attendanceId}),
    );

    if (response.statusCode == 200) {
      return Attendance.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Check-out failed');
    }
  }

  Future<List<Attendance>> getAttendanceHistory({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var url = '$baseUrl/worker/attendance';
    final params = <String, String>{};

    if (fromDate != null) {
      params['from_date'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      params['to_date'] = toDate.toIso8601String();
    }

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to load attendance history');
    }
  }

  Future<Map<String, dynamic>> getWageSummary({
    int? month,
    int? year,
  }) async {
    var url = '$baseUrl/worker/wages';
    final params = <String, String>{};

    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _handleError(response);
      throw Exception('Failed to load wage summary');
    }
  }

  Future<Map<String, dynamic>> getWorkerSite() async {
    final response = await http.get(
      Uri.parse('$baseUrl/worker/my-site'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _handleError(response);
      throw Exception('Failed to load worker site');
    }
  }

  Future<Map<String, dynamic>> getCurrentAttendanceStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/worker/current-status'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _handleError(response);
      throw Exception('Failed to load attendance status');
    }
  }

  Future<User> updateWorkerProfile({
    String? fullName,
    String? phone,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;

    final response = await http.put(
      Uri.parse('$baseUrl/users/update-profile'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to update profile');
    }
  }

  Future<User> uploadProfilePhoto(File imageFile) async {
    final uri = Uri.parse('$baseUrl/users/upload-photo');
    final headers = await _getHeaders();
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to upload profile photo');
    }
  }

  // ==================== CONTRACTOR ENDPOINTS ====================

  Future<Map<String, dynamic>> getContractorDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contractor/dashboard'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _handleError(response);
      throw Exception('Failed to load dashboard');
    }
  }

  Future<List<Map<String, dynamic>>> getWorkers({
    int? siteId,
    String? status,
  }) async {
    var url = '$baseUrl/contractor/workers';
    final params = <String, String>{};

    if (siteId != null) params['site_id'] = siteId.toString();
    if (status != null) params['status'] = status;

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      _handleError(response);
      throw Exception('Failed to load workers');
    }
  }

   Future<void> addWorkerToSite({
    required int siteId,
    required int workerId,
  }) async {
    final uri = Uri.parse('$baseUrl/contractor/sites/$siteId/add-worker')
        .replace(queryParameters: {
      'worker_id': workerId.toString(),
    });
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      _handleError(response);
      throw Exception('Failed to assign worker');
    }
  }

  Future<List<Site>> getSites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contractor/sites'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Site.fromJson(json)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to load sites');
    }
  }

  Future<Site> createSite(Map<String, dynamic> siteData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contractor/sites'),
      headers: await _getHeaders(),
      body: jsonEncode(siteData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Site.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to create site');
    }
  }

  Future<List<Map<String, dynamic>>> getSiteLiveWages({int? siteId}) async {
    var url = '$baseUrl/contractor/attendance/site-live-wages';
    final params = <String, String>{};
    if (siteId != null) params['site_id'] = siteId.toString();
    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      _handleError(response);
      throw Exception('Failed to load live wages');
    }
  }

  // ==================== INVENTORY ENDPOINTS ====================

  Future<List<InventoryItem>> getInventory({
    int? siteId,
    String? category,
    String? status,
  }) async {
    var url = '$baseUrl/inventory';
    final params = <String, String>{};

    if (siteId != null) params['site_id'] = siteId.toString();
    if (category != null) params['category'] = category;
    if (status != null) params['status'] = status;

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InventoryItem.fromJson(json)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to load inventory');
    }
  }

  Future<InventoryItem> createInventoryItem(Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory'),
      headers: await _getHeaders(),
      body: jsonEncode(itemData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to create inventory item');
    }
  }

  Future<InventoryItem> updateInventoryItem(
    int itemId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/inventory/$itemId'),
      headers: await _getHeaders(),
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to update inventory item');
    }
  }

  Future<void> deleteInventoryItem(int itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/inventory/$itemId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      _handleError(response);
      throw Exception('Failed to delete inventory item');
    }
  }

  // ==================== ALERTS ENDPOINTS ====================

  Future<List<Alert>> getAlerts({
    int? siteId,
    String? severity,
    bool? isResolved,
  }) async {
    var url = '$baseUrl/contractor/alerts';
    final params = <String, String>{};

    if (siteId != null) params['site_id'] = siteId.toString();
    if (severity != null) params['severity'] = severity;
    if (isResolved != null) params['is_resolved'] = isResolved.toString();

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Alert.fromJson(json)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to load alerts');
    }
  }

  Future<Alert> createAlert(Map<String, dynamic> alertData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contractor/alerts'),
      headers: await _getHeaders(),
      body: jsonEncode(alertData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Alert.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to create alert');
    }
  }

  Future<Alert> resolveAlert(int alertId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/contractor/alerts/$alertId/resolve'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Alert.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to resolve alert');
    }
  }

  Future<List<Map<String, dynamic>>> getActivityFeed() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contractor/activity-feed'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      _handleError(response);
      throw Exception('Failed to load activity feed');
    }
  }
}
