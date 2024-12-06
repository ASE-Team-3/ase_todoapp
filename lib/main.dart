import 'package:app/initialize_timezones.dart';
import 'package:app/providers/task_provider.dart';
import 'package:app/services/openai_service.dart';
import 'package:app/services/research_service.dart';
import 'package:app/services/task_firestore_service.dart';  // Import TaskFirestoreService
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/views/home/home_view.dart';
import 'package:app/views/home/login_page.dart';
import 'package:app/views/home/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize timezone database
  initializeTimeZones();

  // Initialize FlutterLocalNotificationsPlugin
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env: $e");
  }

  // Initialize ResearchService with environment variables
  final researchService = ResearchService(
    apiUrl: dotenv.env['SCOPUS_BASE_URL'] ?? '',
    apiKey: dotenv.env['SCOPUS_API_KEY'] ?? '',
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<OpenAIService>(create: (_) => OpenAIService()),
        Provider<ResearchService>.value(value: researchService),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(
            flutterLocalNotificationsPlugin,
            researchService: researchService,
          ),
        ),
        Provider<TaskFirestoreService>(
          create: (_) => TaskFirestoreService(),  // Provide TaskFirestoreService here
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ASE Todo App',
      theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.black,
            fontSize: 45,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
          displayMedium: TextStyle(
            color: Colors.white,
            fontSize: 21,
          ),
          displaySmall: TextStyle(
            color: Color.fromARGB(255, 234, 234, 234),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          headlineMedium: TextStyle(
            color: Colors.grey,
            fontSize: 17,
          ),
          headlineSmall: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          titleSmall: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          titleLarge: TextStyle(
            fontSize: 40,
            color: Colors.black,
            fontWeight: FontWeight.w300,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Check if the user is authenticated and set the initial route
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomeView(),
      },
    );
  }
}
