import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'screens/welcome_screen.dart';
import 'services/app_lifecycle_service.dart';
import 'screens/authentication_screen.dart';
import 'models/receivable_payable.dart';
import 'models/tomorrow_task.dart'; // ✅ Import new TomorrowTask model
import 'package:permission_handler/permission_handler.dart';
import 'services/secure_storage_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with encryption
  await Hive.initFlutter();
  final encryptionKey = await SecureStorageService.getEncryptionKey();

  // Register adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(ReceivablePayableAdapter());
  Hive.registerAdapter(TomorrowTaskAdapter());

  // Open encrypted boxes
  await Hive.openBox<Expense>(
    'expenses',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
  await Hive.openBox(
    'settings',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
  await Hive.openBox<ReceivablePayable>(
    'receivables_payables',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
  await Hive.openBox<TomorrowTask>(
    'tomorrow_tasks',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  // Ask for storage permission at startup (install/update)
  await _requestStoragePermission();

  runApp(const MyApp());
}

Future<void> _requestStoragePermission() async {
  final status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLifecycleService _lifecycleService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleService = AppLifecycleService(() {
      // Navigate to authentication screen when locked
      Navigator.of(context).pushReplacementNamed('/auth');
    });
    _lifecycleService.startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, check if we should lock
      if (_lifecycleService.isLocked) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background, start lock timer
      _lifecycleService.startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Manager',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthenticationScreen(),
      routes: {
        '/home': (context) => const WelcomeScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}