import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

final authRepoProvider = Provider((ref) => AuthRepository());
final dataRepoProvider = Provider((ref) => DataRepository());

final currentUserProvider = StateProvider<User?>((ref) => null);

final dashboardRefreshProvider = StreamProvider<void>((ref) async* {
  yield null;
  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    ref.invalidate(devicesProvider);
    ref.invalidate(eventsProvider);
    ref.invalidate(systemsProvider);
    ref.invalidate(incidentsProvider);
    yield null;
  }
});

final devicesProvider = FutureProvider<List<Device>>((ref) => ref.read(dataRepoProvider).getDevices());
final eventsProvider = FutureProvider<List<SecurityEvent>>((ref) => ref.read(dataRepoProvider).getEvents());
final systemsProvider = FutureProvider<List<CriticalSystem>>((ref) => ref.read(dataRepoProvider).getSystems());
final incidentsProvider = FutureProvider<List<Incident>>((ref) => ref.read(dataRepoProvider).getIncidents());

final riskScoreProvider = Provider<int>((ref) {
  final incidents = ref.watch(incidentsProvider).value ?? [];
  final events = ref.watch(eventsProvider).value ?? [];
  
  int score = 0;
  
  for (var inc in incidents) {
    if (inc.status == 'active') {
      if (inc.severity == 'critical') score += 50;
      else if (inc.severity == 'high') score += 20;
      else if (inc.severity == 'medium') score += 10;
    }
  }
  
  for (var e in events) {
    if (e.severity == 'high') score += 3;
    else if (e.severity == 'medium') score += 2;
    else if (e.severity == 'low') score += 1;
  }
  return score;
});

final learningModeProvider = StateProvider<bool>((ref) => true);
final isNewUserProvider = StateProvider<bool>((ref) => true);

final insightsProvider = Provider<List<Insight>>((ref) {
  final incidents = ref.watch(incidentsProvider).value ?? [];
  final devices = ref.watch(devicesProvider).value ?? [];
  final systems = ref.watch(systemsProvider).value ?? [];
  
  final hasActiveRansomware = incidents.any((i) => i.type == 'ransomware' && i.status == 'active');
  final isSystemDown = systems.any((s) => s.status != 'operational');
  final hasIsolated = devices.any((d) => d.isIsolated);
  final allResolved = incidents.isNotEmpty && incidents.every((i) => i.status == 'resolved' || i.status == 'contained');
  
  List<Insight> list = [];
  
  if (hasActiveRansomware) {
    list.add(Insight(
      id: 'ins_ransom',
      type: 'critical',
      title: 'Paso 1: Contención en Red (Aislamiento)',
      message: 'El ransomware está infectando la red OT. Usa la pestaña "Red / Purdue" y presiona "AISLAR" en los dispositivos comprometidos para detener la propagación.',
    ));
    list.add(Insight(
      id: 'ins_segregation',
      type: 'warning',
      title: 'Aislamiento de Redes (IT vs OT)',
      message: '💡 Nota Educativa: ¿Por qué IT y DMZ no se infectaron? Una arquitectura segura divide la red en zonas. El atacante entró a OT, pero no pudo saltar a IT gracias a los firewalls perimetrales de la DMZ.',
    ));
  }
  
  if (hasIsolated && isSystemDown) {
    list.add(Insight(
      id: 'ins_recover',
      type: 'tip',
      title: 'Paso 2: Recuperación Física',
      message: 'Has contenido la amenaza en la red. Ahora ve a la pestaña "Infraestructura" y presiona "RECUPERAR" para reiniciar los procesos físicos (Energía/Agua).',
    ));
  } else if (hasIsolated && !isSystemDown && allResolved) {
    list.add(Insight(
      id: 'ins_reconnect',
      type: 'tip',
      title: 'Paso 3: Retorno a Operaciones',
      message: 'El incidente está resuelto y la planta opera normalmente. Ve a la pestaña "Red" y presiona "RECONECTAR" en los equipos aislados para dejarlos en verde.',
    ));
  }
  
  final unknownDevices = devices.where((d) => !d.isTrusted).length;
  if (unknownDevices > 0 && !hasActiveRansomware) {
    list.add(Insight(
      id: 'ins_unknown',
      type: 'warning',
      title: 'Dispositivos No Confiables (Riesgo de Movimiento Lateral)',
      message: 'Se detectaron $unknownDevices dispositivos desconocidos.\n💡 "Movimiento Lateral" es cuando un atacante usa un equipo infectado para saltar a otros dentro de la misma red.',
    ));
  }

  if (list.isEmpty) {
    list.add(Insight(
      id: 'ins_idle',
      type: 'tip',
      title: 'Estado Seguro',
      message: 'Todo en verde. Tip: Usa el botón "Iniciar Simulación" para ver cómo un ciberataque causa un colapso físico, y aprende a detenerlo.',
    ));
  }
  
  return list;
});

final demoStepProvider = StateProvider<int>((ref) => 0);
final isDemoActiveProvider = StateProvider<bool>((ref) => false);
