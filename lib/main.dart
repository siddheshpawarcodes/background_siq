import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/bootstrap.dart';
import 'core/di/repository_providers.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxes = await Bootstrap.init();
  runApp(
    ProviderScope(
      overrides: [appBoxesProvider.overrideWithValue(boxes)],
      child: const EchoBugApp(),
    ),
  );
}
