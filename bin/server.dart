// FriendsLocalizer relay — Copyright (C) 2026 CWARP
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option) any
// later version. See the LICENSE file for details.

import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:friends_localizer/mesh/real_scheduler.dart';
import 'package:friends_localizer/server/server.dart';
import 'package:friends_localizer/server/relay_hub.dart';
import 'package:friends_localizer/server/key_directory.dart';

Future<void> main(List<String> args) async {
  final hub = RelayHub(scheduler: RealScheduler());
  final directory = KeyDirectory();
  final handler = buildServer(hub: hub, directory: directory);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print('FriendsLocalizer relay on ${server.address.host}:${server.port}');
}
