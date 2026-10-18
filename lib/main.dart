import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const HawkamaApp());
}
// client@gcmc.sa
// Password@123