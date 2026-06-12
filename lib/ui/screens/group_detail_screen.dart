import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../models.dart';
import 'invite_screen.dart';
import 'radar_screen.dart';
import '../widgets/friend_dot.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _refreshed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refreshed) return;
    _refreshed = true;
    // Récupère le roster à jour depuis l'annuaire dès l'ouverture du groupe
    // (et publie ma propre présence). Met aussi à jour le compteur de la liste.
    AppScope.of(context).refreshGroups();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final repo = AppScope.of(context);
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        GroupSummary? group;
        for (final g in repo.groups) {
          if (g.id == groupId) {
            group = g;
            break;
          }
        }
        final members = repo.members(groupId);
        return Scaffold(
          appBar: AppBar(
            title: Text(group?.name ?? 'Groupe'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'invite') {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => InviteScreen(
                            groupId: groupId,
                            groupName: group?.name ?? 'Groupe')));
                  } else if (value == 'leave') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Quitter le groupe ?'),
                        content: const Text(
                            'Tu ne recevras plus les demandes de ce groupe.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('Quitter'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await AppScope.of(context).leaveGroup(groupId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'invite', child: Text('Voir l\'invitation')),
                  PopupMenuItem(
                      value: 'leave', child: Text('Quitter le groupe')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Membres'),
                    ),
                    for (final m in members)
                      ListTile(
                        leading: FriendDot(m.memberId),
                        title: Text(m.name),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.radar),
                      label: const Text('Localiser'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RadarScreen(
                            groupId: groupId,
                            groupName: group?.name ?? 'Groupe',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Ajouter des membres'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InviteScreen(
                            groupId: groupId,
                            groupName: group?.name ?? 'Groupe',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
