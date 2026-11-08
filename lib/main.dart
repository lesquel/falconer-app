import 'package:flutter/material.dart';

import 'shared/bridge/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('OpenMosh')))));
}
