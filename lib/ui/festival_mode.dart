import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../app/festival_task_handler.dart';

/// Contrôle le service avant-plan « mode festival » : rend l'appareil
/// localisable même appli en arrière-plan. ADAPTATEUR DEVICE (Android d'abord).
class FestivalMode {
  /// À appeler une fois au démarrage (avant tout start/stop).
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fl_festival',
        channelName: 'Mode festival',
        channelDescription: 'Te garde localisable par tes amis.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Réveille onRepeatEvent toutes les 30 s pour reconnecter si besoin.
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Demande les permissions (localisation « tout le temps » + notification) puis
  /// démarre le service. Renvoie false si une permission manque ou hors mobile.
  static Future<bool> start() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    // 1) Localisation : « pendant l'utilisation » suffit. Un service avant-plan
    //    de type `location` peut lire le GPS tant qu'il tourne ; Android ne
    //    propose de toute façon pas « tout le temps » via le dialogue runtime
    //    (ça se fait dans les réglages système, optionnel pour plus de fiabilité).
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    // 2) Notification (obligatoire pour un service avant-plan).
    final notif = await FlutterForegroundTask.requestNotificationPermission();
    if (notif != NotificationPermission.granted) return false;

    // 3) Démarrage du service.
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'FriendsLocalizer',
      notificationText: 'Tu es localisable (mode festival)',
      callback: startFestivalTask,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> isOn() => FlutterForegroundTask.isRunningService;
}
