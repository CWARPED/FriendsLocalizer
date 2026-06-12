/// Préférence de thème de l'utilisateur.
enum AppThemeChoice { auto, light, dark }

class AppIdentity {
  final String name;
  final String memberId; // hex
  const AppIdentity(this.name, this.memberId);
}

class GroupSummary {
  final String id;
  final String name;
  final int memberCount;
  const GroupSummary(this.id, this.name, this.memberCount);
}

class GroupMember {
  final String memberId;
  final String name;
  const GroupMember(this.memberId, this.name);
}

class AppSettings {
  final String serverUrl;
  final bool internetEnabled;
  final bool bluetoothEnabled;
  final double myLat;
  final double myLon;
  final AppThemeChoice themeMode;
  const AppSettings({
    this.serverUrl = '',
    this.internetEnabled = true,
    this.bluetoothEnabled = true,
    this.myLat = 0,
    this.myLon = 0,
    this.themeMode = AppThemeChoice.auto,
  });

  AppSettings copyWith({
    String? serverUrl,
    bool? internetEnabled,
    bool? bluetoothEnabled,
    double? myLat,
    double? myLon,
    AppThemeChoice? themeMode,
  }) =>
      AppSettings(
        serverUrl: serverUrl ?? this.serverUrl,
        internetEnabled: internetEnabled ?? this.internetEnabled,
        bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
        myLat: myLat ?? this.myLat,
        myLon: myLon ?? this.myLon,
        themeMode: themeMode ?? this.themeMode,
      );
}
