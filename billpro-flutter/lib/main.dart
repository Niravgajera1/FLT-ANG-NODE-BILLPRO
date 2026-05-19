import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/providers/common_provider.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/presentation/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  final dioClient = DioClient(prefs: prefs);
  final authRepository = AuthRepository(
    dioClient: dioClient,
    prefs: prefs,
  );
  final profileRepository = ProfileRepository(dioClient: dioClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(repository: profileRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CommonProvider(dioClient: dioClient),
        ),
      ],
      child: const BillProApp(),
    ),
  );
}
