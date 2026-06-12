import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final ok = await _startService();
    if (ok) await _setEnabled(true); // mémorise l'intention (relance au démarrage)
    return ok;
  }

  static Future<bool> _startService() async {
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'FriendsLocalizer',
      notificationText: 'Tu es localisable (mode festival)',
      callback: startFestivalTask,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    await _setEnabled(false);
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> isOn() => FlutterForegroundTask.isRunningService;

  static const String _kEnabledKey = 'festivalModeEnabled';

  static Future<void> _setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, v);
  }

  /// À appeler au démarrage de l'app : si le mode festival était actif avant de
  /// quitter (et les permissions toujours accordées), relance le service pour
  /// rester localisable sans nouvelle manipulation. Ne bloque jamais le lancement.
  static Future<void> restoreIfEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kEnabledKey) != true) return;
      if (await FlutterForegroundTask.isRunningService) return; // déjà actif
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return; // permission retirée entre-temps : on n'insiste pas
      }
      await _startService();
    } catch (_) {
      // toute erreur ici ne doit pas empêcher l'app de démarrer
    }
  }

  /// La localisation est-elle accordée « tout le temps » (arrière-plan) ?
  static Future<bool> isAlways() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return await Geolocator.checkPermission() == LocationPermission.always;
  }

  /// Tente de passer la localisation en « tout le temps ».
  ///
  /// Renvoie true si c'est déjà/maintenant accordé. Sinon (cas courant sur
  /// Android 11+, où le système ne propose pas « tout le temps » en pop-up),
  /// ouvre les réglages de l'app pour que l'utilisateur le coche à la main et
  /// renvoie false (action en attente côté utilisateur).
  static Future<bool> requestAlways() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.always) return true;
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    // whileInUse accordé : tente l'escalade vers « tout le temps » (inline sur
    // Android 10, sinon il faut passer par les réglages système).
    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.always) return true;
    await Geolocator.openAppSettings();
    return false;
  }

  /// L'app est-elle exemptée d'optimisation batterie ? (true = pas de bridage,
  /// donc le service avant-plan ne sera pas tué par l'économie de batterie.)
  static Future<bool> isBatteryUnrestricted() async {
    if (!Platform.isAndroid) return true; // notion Android uniquement
    try {
      return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (_) {
      return true; // en cas de doute, ne pas afficher d'alerte inutile
    }
  }

  /// Demande l'exemption d'optimisation batterie (pop-up système). C'est le
  /// principal levier de fiabilité : sans ça, certains fabricants coupent le
  /// service en arrière-plan au bout de quelques minutes.
  static Future<void> requestBatteryUnrestricted() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (_) {
      // certains appareils n'autorisent pas la pop-up : on ouvre les réglages
      try {
        await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      } catch (_) {}
    }
  }
}
