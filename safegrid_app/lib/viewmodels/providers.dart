import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'dart:async';

final authRepoProvider = Provider((ref) => AuthRepository());
final dataRepoProvider = Provider((ref) => DataRepository());

final currentUserProvider = StateProvider<User?>((ref) => null);

// We use an autoDispose timer to poll the backend every 5 seconds for real-time feel
// since it's a local sim without WebSockets for simplicity.

final dashboardRefreshProvider = StreamProvider<void>((ref) async* {
  yield null;
  while (true) {
    await Future.delayed(const Duration(seconds: 3));
    ref.invalidate(devicesProvider);
    ref.invalidate(eventsProvider);
    ref.invalidate(systemsProvider);
    yield null;
  }
});

final devicesProvider = FutureProvider<List<Device>>((ref) async {
  return ref.read(dataRepoProvider).getDevices();
});

final eventsProvider = FutureProvider<List<SecurityEvent>>((ref) async {
  return ref.read(dataRepoProvider).getEvents();
});

final systemsProvider = FutureProvider<List<CriticalSystem>>((ref) async {
  return ref.read(dataRepoProvider).getSystems();
});

final riskScoreProvider = Provider<int>((ref) {
  final events = ref.watch(eventsProvider).value ?? [];
  int score = 0;
  for (var e in events) {
    if (e.severity == 'high') score += 3;
    else if (e.severity == 'medium') score += 2;
    else if (e.severity == 'low') score += 1;
  }
  return score;
});
