import '../core/api_client.dart';
import '../models/models.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  Future<User?> login(String username, String password) async {
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {
        'username': username,
        'password': password
      });
      return User.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid credentials or Brute Force blocked');
      }
      throw Exception('Network error');
    }
  }
}

class DataRepository {
  Future<List<Device>> getDevices() async {
    final res = await ApiClient.dio.get('/devices');
    return (res.data as List).map((e) => Device.fromJson(e)).toList();
  }

  Future<List<SecurityEvent>> getEvents() async {
    final res = await ApiClient.dio.get('/events');
    return (res.data as List).map((e) => SecurityEvent.fromJson(e)).toList();
  }

  Future<List<CriticalSystem>> getSystems() async {
    final res = await ApiClient.dio.get('/systems');
    return (res.data as List).map((e) => CriticalSystem.fromJson(e)).toList();
  }

  Future<void> simulateAttack(String role) async {
    await ApiClient.dio.post('/simulate', data: {'role': role});
  }

  Future<void> resetSimulation(String role) async {
    await ApiClient.dio.post('/reset', data: {'role': role});
  }
}
