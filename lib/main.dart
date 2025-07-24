import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/routing/bottom_tab_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/utils/http_overrides.dart';
import 'src/constants/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool get isLoggedIn => _user != null;
  String? get firstName {
    if (_user?.displayName == null) return null;
    final nameParts = _user!.displayName!.split(' ');
    return nameParts.isNotEmpty ? nameParts.first : null;
  }

  String? get lastName {
    if (_user?.displayName == null) return null;
    final nameParts = _user!.displayName!.split(' ');
    return nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;
  }

  String? get profileImageUrl => _user?.photoURL;

  AuthProvider() {
    // Listen to auth changes (user signing in/out)
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  bool isAccountBottomTabEnabled = false;
  bool isNotificationsEnabled = false;

  String get sdLogoAsset => themeMode == ThemeMode.dark
      ? 'assets/icons/sd-logo-dark.svg'
      : 'assets/icons/sd-logo.svg';

  String get sdIconAsset => themeMode == ThemeMode.dark
      ? 'assets/icons/sd-icon-dark.svg'
      : 'assets/icons/sd-icon-light.svg';

  String get sfLogoAsset => themeMode == ThemeMode.dark
      ? 'assets/icons/sf-logo-dark.svg'
      : 'assets/icons/sf-logo-light.svg';

  String get sfIconAsset => 'assets/icons/sf-icon.svg';

  Future<void> _loadThemeMode() async {
    const storage = FlutterSecureStorage();
    String? darkModeEnabled = await storage.read(key: 'darkModeEnabled');
    themeMode = (darkModeEnabled == 'true') ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _loadAccountBottomTab() async {
    const storage = FlutterSecureStorage();
    String? isEnabled = await storage.read(key: 'accountTabEnabled');
    isAccountBottomTabEnabled = isEnabled == 'true';
    notifyListeners();
  }

  Future<void> _loadNotificationsEnabled() async {
    const storage = FlutterSecureStorage();
    String? isEnabled = await storage.read(key: 'notificationsEnabled');
    isNotificationsEnabled = isEnabled == 'true';
    notifyListeners();
  }

  ThemeProvider() {
    _loadThemeMode();
    _loadAccountBottomTab();
    _loadNotificationsEnabled();
  }

  void toggleTheme(bool isOn) async {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    const storage = FlutterSecureStorage();
    await storage.write(key: 'darkModeEnabled', value: isOn ? 'true' : 'false');
    notifyListeners();
  }

  // method to toggle Account Bottom Tab
  void toggleAccountBottomTab(bool isEnabled) async {
    isAccountBottomTabEnabled = isEnabled;
    const storage = FlutterSecureStorage();
    await storage.write(
        key: 'accountTabEnabled', value: isEnabled ? 'true' : 'false');
    notifyListeners();
  }

  // method to toggle Notifications
  void toggleNotifications(bool isEnabled) async {
    isNotificationsEnabled = isEnabled;
    const storage = FlutterSecureStorage();
    await storage.write(
        key: 'notificationsEnabled', value: isEnabled ? 'true' : 'false');
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme colorScheme = themeProvider.themeMode == ThemeMode.dark
        ? darkColorScheme
        : lightColorScheme;
    final TextTheme textTheme = buildTextTheme(colorScheme);

    return MaterialApp(
      title: 'Sleep Doctor',
      theme: ThemeData(
          colorScheme: lightColorScheme,
          textTheme: textTheme,
          useMaterial3: true),
      darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          textTheme: textTheme,
          useMaterial3: true),
      themeMode: themeProvider.themeMode,
      home: const BottomTabRouter(),
    );
  }
}
