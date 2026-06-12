import 'dart:io';
import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../models.dart';
import '../widgets/app_card.dart';
import '../widgets/gps_status_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _serverUrl;
  late final TextEditingController _lat;
  late final TextEditingController _lon;
  late bool _internet;
  late bool _bluetooth;
  late AppThemeChoice _themeMode;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    final s = AppScope.of(context).settings;
    _serverUrl = TextEditingController(text: s.serverUrl);
    _lat = TextEditingController(text: s.myLat.toString());
    _lon = TextEditingController(text: s.myLon.toString());
    _internet = s.internetEnabled;
    _bluetooth = s.bluetoothEnabled;
    _themeMode = s.themeMode;
    _init = true;
  }

  @override
  void dispose() {
    _serverUrl.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.of(context).updateSettings(AppSettings(
      serverUrl: _serverUrl.text.trim(),
      internetEnabled: _internet,
      bluetoothEnabled: _bluetooth,
      myLat: double.tryParse(_lat.text) ?? 0,
      myLon: double.tryParse(_lon.text) ?? 0,
      themeMode: _themeMode,
    ));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Réglages enregistrés')));
  }

  @override
  Widget build(BuildContext context) {
    final id = AppScope.of(context).identity;
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      persistentFooterButtons: [
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
      body: ListView(
        children: [
          ListTile(
            title: const Text('Identité'),
            subtitle: Text(id?.name ?? '—'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SectionLabel('Connexion'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppCard(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    TextField(
                      key: const Key('serverUrlField'),
                      controller: _serverUrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse du serveur relais',
                        hintText: 'ws://host:8080',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Internet'),
                      value: _internet,
                      onChanged: (v) => setState(() => _internet = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bluetooth'),
                      value: _bluetooth,
                      onChanged: (v) => setState(() => _bluetooth = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SectionLabel(
                isMobile ? 'Ma position' : 'Ma position (desktop)'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // Mobile : le vrai GPS est utilisé -> on montre son statut.
            // Desktop : pas de GPS -> on saisit la position à la main.
            child: isMobile
                ? const GpsStatusCard()
                : AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('myLatField'),
                            controller: _lat,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                            decoration: const InputDecoration(
                                labelText: 'Latitude', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('myLonField'),
                            controller: _lon,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                            decoration: const InputDecoration(
                                labelText: 'Longitude', isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SectionLabel('Thème'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppCard(
              child: SegmentedButton<AppThemeChoice>(
                segments: const [
                  ButtonSegment(value: AppThemeChoice.auto, label: Text('Auto')),
                  ButtonSegment(value: AppThemeChoice.light, label: Text('Clair')),
                  ButtonSegment(value: AppThemeChoice.dark, label: Text('Sombre')),
                ],
                selected: {_themeMode},
                onSelectionChanged: (s) {
                  setState(() => _themeMode = s.first);
                  final scope = AppScope.of(context);
                  scope.updateSettings(
                      scope.settings.copyWith(themeMode: s.first));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
