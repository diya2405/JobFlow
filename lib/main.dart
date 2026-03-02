import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:job_flow_project/WelcomePages/SplashScreen.dart';
import 'UserSide/NotificationPage.dart';
import 'firebasenotifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init(); // this
  runApp(MyApp());
}

// Initialize notifications

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('notification'),
            ),
          ),
        );
      }
    });

    // Listen for notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'status_update') {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NotificationsPage(
            userId: message.data['userId'],
          ),
        ));
      }
    });

    // You can also call `requestPermission()` here if needed
    _requestNotificationPermission();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }

  Future<void> saveDeviceTokenToFirestore() async {
    try {
      // Get current user ID
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User not logged in. Can't save device token.");
        return;
      }

      String uid = currentUser.uid;

      // Get device token
      String? deviceToken = await FirebaseMessaging.instance.getToken();

      if (deviceToken != null) {
        // Save to Firestore under collection 'user_data' document with userId
        await FirebaseFirestore.instance.collection('user_data').doc(uid).set({
          'deviceToken': deviceToken,
        }, SetOptions(merge: true)); // merge true to avoid overwriting other data

        print('Device token saved successfully for user: $uid');
      } else {
        print('Failed to get device token');
      }
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permissions: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await saveDeviceTokenToFirestore();
    }


  }
}