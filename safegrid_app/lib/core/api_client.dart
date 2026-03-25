import 'package:dio/dio.dart';

class ApiClient {
  static String _baseUrl = 'http://127.0.0.1:3000'; // Default simulador local
  
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
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
}
