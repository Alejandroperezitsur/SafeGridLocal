import '../core/api_client.dart';
import '../models/models.dart';
import 'package:dio/dio.dart';

// ─── Demo Mode State ────────────────────────────────────────────────────────
// Shared mutable demo state (simulates a real backend in memory)
class _DemoState {
  static bool _attackActive = false;
  static bool _deviceIsolated = false;
  static bool _systemRecovered = false;

  static List<Device> get devices => _attackActive
      ? [
          Device(id: 'd1', name: 'PLC-Energía-01', ip: '10.0.1.11', type: 'PLC', zone: 'OT', isTrusted: true, status: 'compromised', isIsolated: _deviceIsolated),
          Device(id: 'd2', name: 'HMI-Control-02', ip: '10.0.1.12', type: 'HMI', zone: 'OT', isTrusted: true, status: 'compromised', isIsolated: _deviceIsolated),
          Device(id: 'd3', name: 'Router-SCADA', ip: '10.0.1.1', type: 'Router', zone: 'OT', isTrusted: true, status: 'online', isIsolated: false),
          Device(id: 'd4', name: 'Servidor-IT-01', ip: '192.168.1.10', type: 'Server', zone: 'IT', isTrusted: true, status: 'online', isIsolated: false),
          Device(id: 'd5', name: 'PC-Admin', ip: '192.168.1.20', type: 'Workstation', zone: 'IT', isTrusted: false, status: 'online', isIsolated: false),
        ]
      : [
          Device(id: 'd1', name: 'PLC-Energía-01', ip: '10.0.1.11', type: 'PLC', zone: 'OT', isTrusted: true, status: 'online', isIsolated: false),
          Device(id: 'd2', name: 'HMI-Control-02', ip: '10.0.1.12', type: 'HMI', zone: 'OT', isTrusted: true, status: 'online', isIsolated: false),
          Device(id: 'd3', name: 'Router-SCADA', ip: '10.0.1.1', type: 'Router', zone: 'OT', isTrusted: true, status: 'online', isIsolated: false),
          Device(id: 'd4', name: 'Servidor-IT-01', ip: '192.168.1.10', type: 'Server', zone: 'IT', isTrusted: true, status: 'online', isIsolated: false),
          Device(id: 'd5', name: 'PC-Admin', ip: '192.168.1.20', type: 'Workstation', zone: 'IT', isTrusted: false, status: 'online', isIsolated: false),
        ];

  static List<SecurityEvent> get events => _attackActive
      ? [
          SecurityEvent(id: 'e1', type: 'ransomware_detected', severity: 'critical', timestamp: DateTime.now().subtract(const Duration(minutes: 3)), description: 'Ransomware detectado en PLC-Energía-01: cifrado de archivos de configuración'),
          SecurityEvent(id: 'e2', type: 'lateral_movement', severity: 'high', timestamp: DateTime.now().subtract(const Duration(minutes: 2)), description: 'Movimiento lateral detectado: OT → HMI-Control-02'),
          SecurityEvent(id: 'e3', type: 'c2_communication', severity: 'high', timestamp: DateTime.now().subtract(const Duration(minutes: 1)), description: 'Comunicación C2 bloqueada en DMZ'),
        ]
      : [
          SecurityEvent(id: 'e4', type: 'auth_attempt', severity: 'low', timestamp: DateTime.now().subtract(const Duration(hours: 2)), description: 'Intento de autenticación fallido en Router-SCADA'),
          SecurityEvent(id: 'e5', type: 'port_scan', severity: 'medium', timestamp: DateTime.now().subtract(const Duration(hours: 1)), description: 'Escaneo de puertos detectado desde 10.0.0.99'),
        ];

  static List<Incident> get incidents => _attackActive
      ? [
          Incident(
            id: 'i1',
            type: 'ransomware',
            severity: 'critical',
            status: _deviceIsolated ? 'contained' : 'active',
            startedAt: DateTime.now().subtract(const Duration(minutes: 4)),
            explanation: 'Ransomware tipo Lockbit propagándose por red OT via protocolo Modbus sin autenticación.',
            timeline: [
              IncidentEvent(id: 'ie1', incidentId: 'i1', timestamp: DateTime.now().subtract(const Duration(minutes: 4)), description: 'Intrusión inicial vía phishing en PC-Admin', deviceId: 'd5'),
              IncidentEvent(id: 'ie2', incidentId: 'i1', timestamp: DateTime.now().subtract(const Duration(minutes: 3)), description: 'Movimiento lateral a red OT por falta de segmentación', deviceId: 'd1'),
              IncidentEvent(id: 'ie3', incidentId: 'i1', timestamp: DateTime.now().subtract(const Duration(minutes: 2)), description: 'Cifrado de archivos PLC iniciado', deviceId: 'd2'),
            ],
          ),
        ]
      : [];

  static List<CriticalSystem> get systems => _attackActive
      ? [
          CriticalSystem(id: 's1', name: 'Sistema de Distribución Eléctrica', status: _systemRecovered ? 'operational' : 'degraded', dependencies: ['d1', 'd2']),
          CriticalSystem(id: 's2', name: 'Sistema de Tratamiento de Agua', status: _systemRecovered ? 'operational' : 'offline', dependencies: ['d3']),
          CriticalSystem(id: 's3', name: 'Red de Comunicaciones SCADA', status: 'operational', dependencies: ['d3', 'd4']),
        ]
      : [
          CriticalSystem(id: 's1', name: 'Sistema de Distribución Eléctrica', status: 'operational', dependencies: ['d1', 'd2']),
          CriticalSystem(id: 's2', name: 'Sistema de Tratamiento de Agua', status: 'operational', dependencies: ['d3']),
          CriticalSystem(id: 's3', name: 'Red de Comunicaciones SCADA', status: 'operational', dependencies: ['d3', 'd4']),
        ];
}

// ─── Auth Repository ──────────────────────────────────────────────────────────
class AuthRepository {
  static const _demoCredentials = {
    'admin': ('admin123', 'Administrador del Sistema', 'admin'),
    'operator': ('op123', 'Operador de Control', 'operator'),
    'viewer': ('view123', 'Observador', 'viewer'),
  };

  Future<User?> login(String username, String password) async {
    // Try real server first (if not on GitHub Pages)
    if (!ApiClient.isDemo) {
      try {
        final res = await ApiClient.dio.post('/auth/login', data: {
          'username': username,
          'password': password,
        });
        return User.fromJson(res.data);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          throw Exception('Credenciales incorrectas o bloqueo por fuerza bruta');
        }
        // Fall through to demo mode if server unreachable
      }
    }

    // Demo mode: validate against hardcoded credentials
    await Future.delayed(const Duration(milliseconds: 600)); // simulate latency
    final cred = _demoCredentials[username.trim()];
    if (cred != null && cred.$1 == password.trim()) {
      return User(
        id: 'demo_${username.trim()}',
        name: cred.$2,
        role: cred.$3,
        username: username.trim(),
      );
    }
    throw Exception('Credenciales incorrectas');
  }
}

// ─── Data Repository ──────────────────────────────────────────────────────────
class DataRepository {
  Future<List<Device>> getDevices() async {
    if (!ApiClient.isDemo) {
      try {
        final res = await ApiClient.dio.get('/devices');
        return (res.data as List).map((e) => Device.fromJson(e)).toList();
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    return _DemoState.devices;
  }

  Future<List<SecurityEvent>> getEvents() async {
    if (!ApiClient.isDemo) {
      try {
        final res = await ApiClient.dio.get('/events');
        return (res.data as List).map((e) => SecurityEvent.fromJson(e)).toList();
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _DemoState.events;
  }

  Future<List<Incident>> getIncidents() async {
    if (!ApiClient.isDemo) {
      try {
        final res = await ApiClient.dio.get('/incidents');
        return (res.data as List).map((e) => Incident.fromJson(e)).toList();
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _DemoState.incidents;
  }

  Future<List<CriticalSystem>> getSystems() async {
    if (!ApiClient.isDemo) {
      try {
        final res = await ApiClient.dio.get('/systems');
        return (res.data as List).map((e) => CriticalSystem.fromJson(e)).toList();
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return _DemoState.systems;
  }

  Future<void> simulateAttack(String role) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/simulate', data: {'role': role});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _DemoState._attackActive = true;
    _DemoState._deviceIsolated = false;
    _DemoState._systemRecovered = false;
  }

  Future<void> resetSimulation(String role) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/reset', data: {'role': role});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 400));
    _DemoState._attackActive = false;
    _DemoState._deviceIsolated = false;
    _DemoState._systemRecovered = false;
  }

  Future<void> isolateDevice(String role, String deviceId) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/respond/isolate', data: {'role': role, 'deviceId': deviceId});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _DemoState._deviceIsolated = true;
  }

  Future<void> reconnectDevice(String role, String deviceId) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/respond/reconnect', data: {'role': role, 'deviceId': deviceId});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _DemoState._deviceIsolated = false;
  }

  Future<void> shutdownZone(String role, String zone) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/respond/shutdown_zone', data: {'role': role, 'zone': zone});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> containIncident(String role, String incidentId) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/respond/contain', data: {'role': role, 'incidentId': incidentId});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    _DemoState._deviceIsolated = true;
  }

  Future<void> recoverSystem(String role, String systemId) async {
    if (!ApiClient.isDemo) {
      try {
        await ApiClient.dio.post('/respond/recover', data: {'role': role, 'systemId': systemId});
        return;
      } on DioException {
        // fall through to demo
      }
    }
    await Future.delayed(const Duration(milliseconds: 400));
    _DemoState._systemRecovered = true;
  }
}
