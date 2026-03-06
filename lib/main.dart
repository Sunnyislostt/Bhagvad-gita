import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/feed_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await NotificationService().initialize();

  runApp(const BhagvadGitaApp());
}

class BhagvadGitaApp extends StatefulWidget {
  const BhagvadGitaApp({super.key});

  @override
  State<BhagvadGitaApp> createState() => _BhagvadGitaAppState();
}

class _BhagvadGitaAppState extends State<BhagvadGitaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _queuedNotificationVerseId;

  @override
  void initState() {
    super.initState();
    NotificationService().setVerseOpenHandler(_openNotificationVerse);
  }

  @override
  void dispose() {
    NotificationService().clearVerseOpenHandler();
    super.dispose();
  }

  Future<void> _openNotificationVerse(String verseId) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _queuedNotificationVerseId = verseId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flushQueuedNotificationVerse();
      });
      return;
    }

    navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => FeedScreen(
          initialVerseId: verseId,
          persistReadingState: false,
          enableWidgetLaunchHandling: false,
          entryContextLabel: 'Notification Verse',
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  void _flushQueuedNotificationVerse() {
    final queuedVerseId = _queuedNotificationVerseId;
    if (queuedVerseId == null || queuedVerseId.isEmpty) {
      return;
    }

    _queuedNotificationVerseId = null;
    _openNotificationVerse(queuedVerseId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Bhagvad Gita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const FeedScreen(),
    );
  }
}
