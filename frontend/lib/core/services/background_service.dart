import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'background_keyword_channel', // id
        'Keyword Spotting Notifications', // name
        description:
            'Notifications for detected keywords in background', // description
        importance: Importance.high,
      ));

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: false, // We rely on the native Foreground Service created in MainActivity/SpeechService for the microphone
      notificationChannelId: 'background_keyword_channel',
      initialNotificationTitle: 'Background Service',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Keyword Spotting Logic
  const eventChannel = EventChannel('dev.genai.mlkit_speech/text_stream');
  
  String currentTranscript = "";

  eventChannel.receiveBroadcastStream().listen((data) {
    if (data is String) {
      currentTranscript = data;
      debugPrint("[Background Service] Transcript updated: $currentTranscript");
      checkKeywordsAndNotify(currentTranscript, flutterLocalNotificationsPlugin);
    }
  }, onError: (e) {
    debugPrint("[Background Service] stream error: $e");
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

// Ensure we don't spam notifications
DateTime? lastNotificationTime;

void checkKeywordsAndNotify(String text, FlutterLocalNotificationsPlugin plugin) {
  final lowerText = text.toLowerCase();
  
  final keywords = ['health', 'finance'];
  String? detectedKeyword;

  for (var kw in keywords) {
    if (lowerText.contains(kw)) {
      detectedKeyword = kw;
      break;
    }
  }

  if (detectedKeyword != null) {
    final now = DateTime.now();
    // Throttle notifications to max 1 every 30 seconds
    if (lastNotificationTime == null || 
        now.difference(lastNotificationTime!).inSeconds > 30) {
      
      lastNotificationTime = now;

      plugin.show(
        id: 999,
        title: 'Keyword Detected!',
        body: 'We heard the keyword: "$detectedKeyword"',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'background_keyword_channel',
            'Keyword Spotting Notifications',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}
