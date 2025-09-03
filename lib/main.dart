import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:trashifier_app/pages/home_page.dart';
import 'package:trashifier_app/services/notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  tz.initializeTimeZones();

  // await StorageService.instance.clearDates(TrashType.plastic);
  // await StorageService.instance.clearDates(TrashType.paper);
  // await StorageService.instance.clearDates(TrashType.garbage);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}
