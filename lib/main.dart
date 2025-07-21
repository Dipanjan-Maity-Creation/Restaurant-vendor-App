import 'package:flutter/material.dart';
import 'login.dart'; // Assuming this contains LoginPage
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.notification?.title}");
}

/// Request notification permissions, subscribe to a topic, and set up messaging.
Future<void> _initializeFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (required on iOS, optional on Android)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Subscribe to a topic for new order notifications
  await messaging.subscribeToTopic("restaurantNotifications");

  // Get the FCM token
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    if (message.notification != null) {
      _showSnackBar(message.notification!.body ?? 'New order appears');
    }
  });

  // Handle messages when the app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
  });
}

// GlobalKey to access ScaffoldMessenger from anywhere
final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void _showSnackBar(String message) {
  _scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase App Check with Play Integrity
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // For iOS (if needed), uncomment and add your Apple App Attest provider
    // appleProvider: AppleProvider.appAttest,
  );

  // Initialize FCM
  await _initializeFCM();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaammy Splash Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: LoginPage(), // Assuming LoginPage is defined in login.dart
    );
  }
}