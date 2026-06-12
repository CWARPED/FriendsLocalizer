import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import '../widgets/festival_mode_card.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_detail_screen.dart';
import 'settings_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool _refreshed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refreshed) return;
    _refreshed = true;
    // Met à jour le nombre de membres dès l'affichage de la liste, sans
    // attendre l'écran Localiser. Échoue silencieusement hors-ligne.
    AppScope.of(context).refreshGroups();
  }

  void _openCreateJoin(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Créer un groupe'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CreateGroupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Rejoindre un groupe'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const JoinGroupScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes groupes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final groups = repo.groups;
          if (groups.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                FestivalModeCard(),
                SizedBox(height: 24),
                Center(child: Text('Aucun groupe pour l\'instant')),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: FestivalModeCard(),
              ),
              for (final g in groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Builder(builder: (context) {
                    final p = Theme.of(context).extension<AppPalette>()!;
                    return AppCard(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(groupId: g.id))),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: p.raised,
                                borderRadius: BorderRadius.circular(11)),
                            child: Icon(Icons.group,
                                size: 20, color: p.accentSoft),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name,
                                    style: TextStyle(
                                        color: p.textPrimary, fontSize: 15)),
                                Text('${g.memberCount} membres',
                                    style: TextStyle(
                                        color: p.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: p.textMuted),
                        ],
                      ),
                    );
                  }),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateJoin(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
