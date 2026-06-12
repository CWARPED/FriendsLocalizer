import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/app.dart';
import 'ui/app_scope.dart';
import 'ui/festival_mode.dart';
import 'ui/prefs_store.dart';
import 'ui/real_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FestivalMode.init(); // prépare le service avant-plan (mode festival)
  final prefs = await SharedPreferences.getInstance();
  final repo = await RealRepository.load(PrefsStore(prefs));
  runApp(AppScope(repository: repo, child: const FriendsApp()));
}
