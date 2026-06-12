import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/prefs_store.dart';
import '../ui/real_repository.dart';

/// Point d'entrée de l'isolate d'arrière-plan. DOIT être une fonction top-level
/// annotée `vm:entry-point`, sinon le service ne démarre pas.
@pragma('vm:entry-point')
void startFestivalTask() {
  FlutterForegroundTask.setTaskHandler(FestivalTaskHandler());
}

/// Cerveau du « mode festival » : tourne dans l'isolate d'arrière-plan tenu en
/// vie par le service avant-plan. Il refait, hors écran, ce que l'app fait au
/// premier plan (RealRepository + ensureConnected) pour répondre aux demandes de
/// localisation avec le vrai GPS.
///
/// ADAPTATEUR DEVICE : non testé unitairement (service natif). Réutilise du code
/// déjà couvert (crypto/mesh/LocationService/RealRepository).
class FestivalTaskHandler extends TaskHandler {
  RealRepository? _repo;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = await RealRepository.load(PrefsStore(prefs));
    await repo.ensureConnected(); // connecte au relais + commence à répondre
    _repo = repo;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // ensureConnected est idempotent et reconnecte si la connexion est tombée.
    _repo?.ensureConnected();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _repo?.dispose();
    _repo = null;
  }
}
