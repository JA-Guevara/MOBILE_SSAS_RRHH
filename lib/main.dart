import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppProviders(child: App()));
}
