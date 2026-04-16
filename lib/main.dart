import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/user_provider.dart';
import 'providers/product_provider.dart';
import 'providers/vendor_provider.dart';
import 'providers/order_provider.dart';
import 'providers/custom_request_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/category_provider.dart';
import 'providers/review_provider.dart';
import 'providers/quote_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const KarsaaziApp());
}

class KarsaaziApp extends StatefulWidget {
  const KarsaaziApp({super.key});

  @override
  State<KarsaaziApp> createState() => _KarsaaziAppState();
}

class _KarsaaziAppState extends State<KarsaaziApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMNavigation();
  }

  void _setupFCMNavigation() {
    // Handle notification tap when app was in background
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTap(message);
    });

    // Handle notification tap when app is in foreground/background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';

    // Quote-related notifications → navigate to Quotes tab
    if (type == 'quote_ready' || type == 'onCommissionApplied' || type == 'quote_sent_to_customer') {
      // Use a short delay to ensure the widget tree is built
      Future.delayed(const Duration(milliseconds: 500), () {
        appRouter.push('/my-orders', extra: {'initialTab': 2});
      });
    } else if (data['route'] != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        appRouter.push(data['route']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomRequestProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        // Add ProxyProvider for GoRouter to manage its lifecycle reactively
        ProxyProvider<UserProvider, GoRouter>(
          lazy: false,
          update: (context, userProvider, previous) => previous ?? AppRouter.createRouter(userProvider),
        ),
      ],
      child: Consumer2<AppProvider, GoRouter>(
        builder: (context, appProvider, router, _) {
          return MaterialApp.router(
            title: 'KARSAAZI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
