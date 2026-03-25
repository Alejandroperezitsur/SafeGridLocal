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
  final hasActiveRansomware = incidents.any((i) => i.type == 'ransomware' && i.status == 'active');
  
  List<Insight> list = [];
  
  if (hasActiveRansomware) {
    list.add(Insight(
      id: 'ins_ransom',
      type: 'critical',
      title: 'Propagación en Curso',
      message: 'El ransomware está infectando la red OT. Usa la pestaña "Red" para aislar dispositivos inmediatamente.',
    ));
  }
  
  final unknownDevices = devices.where((d) => !d.isTrusted).length;
  if (unknownDevices > 0) {
    list.add(Insight(
      id: 'ins_unknown',
      type: 'warning',
      title: 'Dispositivos No Confiables',
      message: 'Se detectaron $unknownDevices dispositivos desconocidos. Esto podría ser el inicio de un movimiento lateral.',
    ));
  }

  if (list.isEmpty) {
    list.add(Insight(
      id: 'ins_idle',
      type: 'tip',
      title: 'Estado Seguro',
      message: 'Todo parece en orden. Tip: Revisa periódicamente el puntaje de riesgo para detectar anomalías silenciosas.',
    ));
  }
  
  return list;
});

final demoStepProvider = StateProvider<int>((ref) => 0);
final isDemoActiveProvider = StateProvider<bool>((ref) => false);
