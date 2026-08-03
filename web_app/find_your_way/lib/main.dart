import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/api_client.dart';
import 'state/auth_controller.dart';

void main() {
  runApp(const RootProviders());
}

class RootProviders extends StatelessWidget {
  const RootProviders({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<ApiClient>()),
        ),
      ],
      child: const FindYourWayApp(),
    );
  }
}
