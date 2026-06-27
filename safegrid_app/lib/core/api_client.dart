import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  static String _baseUrl = 'http://127.0.0.1:3000';

  /// True when running on GitHub Pages or any HTTPS context without a real server.
  /// In demo mode all API calls fall back to local mock data.
  static bool get isDemo {
    if (!kIsWeb) return false;
    // On GitHub Pages the origin contains 'github.io'
    // Also treat as demo if the user left the field empty and we're on HTTPS
    final origin = Uri.base.origin;
    return origin.contains('github.io') || origin.startsWith('https://');
  }

  static void setServerIp(String ip) {
    if (ip.trim().isEmpty) return;
    String cleanIp = ip.trim();
    if (!cleanIp.startsWith('http')) {
      cleanIp = 'http://$cleanIp';
    }
    if (!cleanIp.contains(':3000')) {
      cleanIp = '$cleanIp:3000';
    }
    _baseUrl = cleanIp;
  }

  static Dio get dio => Dio(BaseOptions(
    baseUrl: '$_baseUrl/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
}
