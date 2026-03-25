class User {
  final String id;
  final String name;
  final String role; // admin, operator, viewer
  final String username;

  User({required this.id, required this.name, required this.role, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      username: json['username'],
    );
  }
}

class Device {
  final String id;
  final String name;
  final String ip;
  final String type;
  final String zone;
  final bool isTrusted;
  final String status;
  final bool isIsolated;

  Device({required this.id, required this.name, required this.ip, required this.type, required this.zone, required this.isTrusted, required this.status, required this.isIsolated});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      ip: json['ip'],
      type: json['type'],
      zone: json['zone'],
      isTrusted: json['isTrusted'] == true || json['isTrusted'] == 1,
      status: json['status'] ?? 'online',
      isIsolated: json['isIsolated'] == true || json['isIsolated'] == 1,
    );
  }
}

class SecurityEvent {
  final String id;
  final String type;
  final String severity; 
  final DateTime timestamp;
  final String description;

  SecurityEvent({required this.id, required this.type, required this.severity, required this.timestamp, required this.description});

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'],
      type: json['type'],
      severity: json['severity'],
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
    );
  }
}

class CriticalSystem {
  final String id;
  final String name;
  final String status;
  final List<String> dependencies;

  CriticalSystem({required this.id, required this.name, required this.status, required this.dependencies});

  factory CriticalSystem.fromJson(Map<String, dynamic> json) {
    return CriticalSystem(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
    );
  }
}

class IncidentEvent {
  final String id;
  final String incidentId;
  final DateTime timestamp;
  final String description;
  final String? deviceId;

  IncidentEvent({required this.id, required this.incidentId, required this.timestamp, required this.description, this.deviceId});

  factory IncidentEvent.fromJson(Map<String, dynamic> json) {
    return IncidentEvent(
      id: json['id'],
      incidentId: json['incidentId'],
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      deviceId: json['deviceId'],
    );
  }
}

class Incident {
  final String id;
  final String type;
  final String severity;
  final String status;
  final DateTime startedAt;
  final List<IncidentEvent> timeline;
  final String? explanation;

  Incident({required this.id, required this.type, required this.severity, required this.status, required this.startedAt, required this.timeline, this.explanation});

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      type: json['type'],
      severity: json['severity'],
      status: json['status'],
      startedAt: DateTime.parse(json['startedAt']),
      timeline: (json['timeline'] as List?)?.map((e) => IncidentEvent.fromJson(e)).toList() ?? [],
      explanation: json['explanation'],
    );
  }
}

class Insight {
  final String id;
  final String type; // info, warning, critical, tip
  final String title;
  final String message;
  final String? relatedEntityId;

  Insight({required this.id, required this.type, required this.title, required this.message, this.relatedEntityId});
}

class DemoStep {
  final String id;
  final String instruction;
  final String targetUIElement;
  final String? title;

  DemoStep({required this.id, required this.instruction, required this.targetUIElement, this.title});
}
