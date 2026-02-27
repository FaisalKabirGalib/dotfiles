---
name: flutter-local-notifications
description: Expert guidance on using flutter_local_notifications for local push notifications in Flutter. Covers Android/iOS setup, permissions, scheduled notifications, notification actions, channels, and handling foreground/background taps. Use when implementing local notifications, reminders, or alarm functionality.
license: MIT
compatibility: opencode
---

# flutter_local_notifications

Cross-platform local notifications for Flutter (Android & iOS).

## Setup

```yaml
dependencies:
  flutter_local_notifications: ^19.0.0
  timezone: ^0.9.0
```

---

## Android Setup

### Gradle (build.gradle)

```gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    compileSdk 36
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

### AndroidManifest.xml

```xml
<manifest>
    <!-- For scheduled notifications -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    
    <!-- For full-screen notifications (optional) -->
    <!-- <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/> -->
    
    <application>
        <receiver android:exported="false" 
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" 
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            </intent-filter>
        </receiver>
        
        <!-- For notification actions -->
        <receiver android:exported="false" 
            android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
    </application>
</manifest>
```

---

## iOS Setup

### AppDelegate.swift

```swift
import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## Initialization

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz_data.initializeTimeZones();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await notifications.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
    },
  );
}
```

---

## Request Permissions

### Android 13+

```dart
Future<bool> requestAndroidPermission() async {
  final android = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  return await android?.requestNotificationsPermission() ?? false;
}
```

### iOS

```dart
Future<bool> requestIOSPermission() async {
  final ios = notifications.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  return await ios?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  ) ?? false;
}
```

---

## Show Notification

```dart
Future<void> showNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default Channel',
    channelDescription: 'Default notification channel',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  const iosDetails = DarwinNotificationDetails();
  
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  await notifications.show(id, title, body, details, payload: payload);
}
```

---

## Scheduled Notification

```dart
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? payload,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'scheduled_channel',
    'Scheduled',
    channelDescription: 'Scheduled notifications',
  );
  
  const iosDetails = DarwinNotificationDetails();
  
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  await notifications.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledDate, tz.local),
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: payload,
  );
}
```

### Daily/Weekly Repeat

```dart
await notifications.zonedSchedule(
  id,
  title,
  body,
  tz.TZDateTime.now(tz.local).add(Duration(days: 1)),
  details,
  matchDateTimeComponents: DateTimeComponents.time, // Daily
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
);

// Weekly
matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
```

---

## Periodic Notification

```dart
await notifications.periodicallyShow(
  id: 0,
  title: 'Reminder',
  body: 'Check the app',
  repeatInterval: RepeatInterval.everyMinute,
  notificationDetails: details,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
);
```

---

## Notification Channels (Android)

```dart
Future<void> createChannel() async {
  final android = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'high_priority',
      'High Priority',
      description: 'Important notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
  );
}
```

---

## Notification Actions

### iOS Categories (in init)

```dart
final iosSettings = DarwinInitializationSettings(
  notificationCategories: [
    DarwinNotificationCategory(
      'message_category',
      actions: [
        DarwinNotificationAction.plain('reply', 'Reply'),
        DarwinNotificationAction.plain('dismiss', 'Dismiss',
          options: {DarwinNotificationActionOption.destructive}),
      ],
    ),
  ],
);
```

### Background Handler

```dart
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  final payload = response.payload;
}

await notifications.initialize(
  settings: settings,
  onDidReceiveNotificationResponse: onForegroundResponse,
  onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
);
```

### Android Actions

```dart
final androidDetails = AndroidNotificationDetails(
  'channel_id',
  'Channel',
  actions: [
    const AndroidNotificationAction('reply', 'Reply'),
    const AndroidNotificationAction('dismiss', 'Dismiss'),
  ],
);
```

---

## Group Notifications

### iOS

```dart
const iosDetails = DarwinNotificationDetails(
  threadIdentifier: 'group_1',
);
```

### Android

```dart
const androidDetails = AndroidNotificationDetails(
  'channel',
  'Channel',
  groupKey: 'com.example.group',
  setAsGroupSummary: true,
);
```

---

## Big Picture / Big Text Styles

```dart
final androidDetails = AndroidNotificationDetails(
  'channel',
  'Channel',
  styleInformation: BigPictureStyleInformation(
    FilePathAndroidBitmap('/path/to/image.png'),
    contentTitle: 'Title',
    summaryText: 'Summary',
  ),
);

// Big Text
styleInformation: BigTextStyleInformation(
  'Long text content...',
  contentTitle: 'Title',
),
```

---

## Full-Screen Intent (Android)

```xml
<activity android:showWhenLocked="true" android:turnScreenOn="true">
```

```dart
final androidDetails = AndroidNotificationDetails(
  'full_screen',
  'Full Screen',
  fullScreenIntent: true,
  category: AndroidNotificationCategory.call,
  priority: Priority.max,
);
```

---

## Cancel Notifications

```dart
await notifications.cancel(id);
await notifications.cancelAll();
```

---

## Get Pending/Active

```dart
final pending = await notifications.pendingNotificationRequests();
final active = await notifications.getActiveNotifications();
```

---

## Check App Launch from Notification

```dart
final launchDetails = await notifications.getNotificationAppLaunchDetails();
if (launchDetails?.didNotificationLaunchApp ?? false) {
  final payload = launchDetails!.notificationResponse?.payload;
}
```

---

## Custom Sound

### Android: `android/app/src/main/res/raw/sound.mp3`

```dart
const androidDetails = AndroidNotificationDetails(
  'channel',
  'Channel',
  sound: RawResourceAndroidNotificationSound('sound'),
);
```

### iOS: `ios/Runner/sound.caf`

```dart
const iosDetails = DarwinNotificationDetails(sound: 'sound.caf');
```

---

## Best Practices

1. Request permissions before showing notifications
2. Use meaningful channel IDs grouped by type
3. Handle payload for deep linking
4. Request exact alarm permission on Android 14+
5. Test on real devices (OEMs may block background notifications)
6. Use unique IDs (same ID overwrites)
7. Initialize timezone for scheduled notifications
8. Handle foreground and background callbacks

---

## Common Issues

### Android scheduled notifications not firing
- OEM battery optimization (Xiaomi, Huawei, Samsung)
- User must whitelist app in battery settings
- Check exact alarm permission on Android 14+

### iOS 64 notification limit
- iOS keeps only 64 pending notifications
- Cancel old before scheduling new

### Android 13+ no notifications
- Must request POST_NOTIFICATIONS permission

---

## Reference

- Package: https://pub.dev/packages/flutter_local_notifications
- GitHub: https://github.com/MaikuB/flutter_local_notifications
