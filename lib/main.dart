import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:kcs_engineer/app_config.dart';
import 'package:kcs_engineer/model/user/user.dart';
import 'package:kcs_engineer/router.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/key.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:kcs_engineer/util/navigationService.dart';
import 'package:kcs_engineer/util/repositories.dart';

// Future<void> _firebaseMessagingBackgroundHandler(
//     RemoteMessage remoteMessage) async {
// //print('Handling a background message ${message.messageId}');
//   await Firebase.initializeApp();
//   print("Message recieve $remoteMessage");

//   Map<String, dynamic> message = remoteMessage.data;

//   var bigPicture = message["big_picture"] ?? "";
//   var largePicture = message["image_url"] ?? "";
//   var body = message["body"] ?? "";
//   var title = message["title"] ?? "";

//   await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//           id: 1,
//           channelKey: 'key',
//           title: title,
//           displayOnBackground: true,
//           displayOnForeground: true,
//           body: body,
//           notificationLayout: bigPicture.toString().isNotEmpty
//               ? NotificationLayout.BigPicture
//               : NotificationLayout.Default,
//           icon: 'resource://drawable/ic_notification',
//           largeIcon: largePicture,
//           bigPicture: bigPicture));
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig appConfig = AppConfig(appName: "MMPL", flavor: "prod");
  Widget app = await initializeApp(appConfig);
  await dotenv.load(fileName: ".env");

  GetIt locator = GetIt.instance;
  locator.registerLazySingleton<NavigationService>(() => NavigationService());

  // var res = await Firebase.initializeApp();
  // await _registerOnFirebase();
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // AwesomeNotifications().initialize('resource://drawable/ic_notification', [
  //   NotificationChannel(import 'package:get_it/get_it.dart';

  //       channelKey: 'key',
  //       channelName: 'inbox notification',
  //       channelDescription: 'main notification channel',
  //       defaultColor: Colors.white,
  //       enableVibration: true,
  //       icon: 'resource://drawable/ic_notification',
  //       playSound: true,
  //       enableLights: true,
  //       ledColor: Colors.white)
  // ]);

  // AwesomeNotifications().actionStream.listen((event) {
  //   print(event.payload!);
  // });
  // await FlutterDownloader.initialize();
  await FlutterConfig.loadEnvVariables();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(app);
  });
}

// _registerOnFirebase() async {
//   FirebaseMessaging _fcm = FirebaseMessaging.instance;

//   var userStorage = await storage.read(key: USER);

//   if (userStorage != null) {
//     User userJson = User.fromJson(jsonDecode(userStorage!));
//     var email = userJson.email?.toLowerCase();

//     if (email != null) {
//       _fcm.subscribeToTopic('all');
//       _fcm.getToken().then((value) async => {
//             value.toString(),
//             await handleNewRegistrationToken(
//                 value.toString(), email.toString()),
//           });
//     }
//   }
// }

handleNewRegistrationToken(String token, String email) async {
  final Map<String, dynamic> map = {
    'email': email,
    'token': token,
    'device_id': 'deviceID',
    'platform': 'Android'
  };
  var baseUrl = FlutterConfig.get("API_URL");

  var response = await http.post(
      Uri.parse((baseUrl ?? "https://cm.khind.com.my") +
          "/provider/fcm/register.php"),
      body: map,
      headers: null);

  var g = response.toString();
}

Future<Widget> initializeApp(AppConfig appConfig) async {
  WidgetsFlutterBinding.ensureInitialized();
  return MyApp(appConfig);
}

class MyApp extends StatelessWidget {
  final AppConfig appConfig;
  const MyApp(this.appConfig);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      title: 'Khind',
      localizationsDelegates: [
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('en', 'SG'),
      ],
      // locale: Locale('en'),
      theme: ThemeData(
          fontFamily: 'Roboto',
          textTheme: TextTheme(
              bodyText1: TextStyle(fontSize: 12.0),
              bodyText2: TextStyle(fontSize: 12.0),
              button:
                  TextStyle(fontSize: 12.0) // and so on for every text style
              )),
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
