import 'package:flutter/foundation.dart';
import 'models.dart';
import '../app/geo.dart';
import '../app/location_service.dart' show LocatedPosition;

export 'models.dart';
export '../app/geo.dart' show GeoPoint;
export '../app/location_service.dart' show LocatedPosition;

/// Source de données de l'app, observable. Implémentation fake (ce plan) puis
/// réelle (crypto/mesh/stockage) plus tard, sans toucher les écrans.
abstract class AppRepository extends ChangeNotifier {
  AppIdentity? get identity;
  Future<void> createIdentity(String name);

  List<GroupSummary> get groups;
  List<GroupMember> members(String groupId);
  Future<GroupSummary> createGroup(String name);

  String inviteFor(String groupId);
  Future<void> joinFromInvite(String payload);

  /// Quitte un groupe (le retire localement).
  Future<void> leaveGroup(String groupId);

  AppSettings get settings;
  void updateSettings(AppSettings settings);

  GeoPoint get myPosition;

  /// Ma position courante pour servir de centre au radar : vrai GPS sur mobile,
  /// coordonnées manuelles sur desktop. Repli sur [myPosition] si le GPS n'a pas
  /// (encore) de fix.
  Future<GeoPoint> currentPosition();

  /// Flux de ma position : émet à chaque déplacement (mobile). Permet au radar
  /// de garder mon centre à jour tant que l'écran Localiser est ouvert — donc de
  /// voir la distance diminuer en marchant, même sur une demande momentanée.
  /// Flux vide sur desktop/test (position manuelle, pas de mouvement).
  Stream<GeoPoint> positionUpdates();

  Future<void> ensureConnected();

  /// Rafraîchit le nombre de membres des groupes affichés en interrogeant
  /// l'annuaire du serveur (sans démarrer le moteur de localisation). À appeler
  /// quand on ouvre la liste des groupes. Échoue silencieusement hors-ligne.
  Future<void> refreshGroups();

  Future<void> requestLocation({
    required String groupId,
    required String targetId,
    bool live = false,
  });
  LocatedPosition? located(String responderId);
}
