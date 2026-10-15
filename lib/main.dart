import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_detail_screen.dart';
import 'screens/new_conversation_screen.dart';
import 'screens/search_screen.dart';
import 'screens/call_screen.dart';
import 'screens/story_view_screen.dart';
import 'screens/surveillance_screen.dart';
import 'models/conversation.dart';
import 'models/story.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Di',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF075E54),
            primary: const Color(0xFF075E54),
            secondary: const Color(0xFF25D366),
          ),
          primaryColor: const Color(0xFF075E54),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF075E54),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/profile':
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            case '/chat':
              final conversation = settings.arguments as Conversation;
              return MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  conversationId: conversation.id,
                  conversation: conversation,
                ),
              );
            case '/new-conversation':
              return MaterialPageRoute(
                builder: (_) => const NewConversationScreen(),
              );
            case '/search':
              return MaterialPageRoute(builder: (_) => const SearchScreen());
            case '/surveillance':
              return MaterialPageRoute(
                builder: (_) => const SurveillanceScreen(),
              );
            case '/story-view':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => StoryViewScreen(
                  stories: args['stories'] as List<Story>,
                  initialIndex: args['initialIndex'] as int? ?? 0,
                ),
              );
            case '/call':
              final args = settings.arguments as Map<String, dynamic>;
              final conversation = args['conversation'] as Conversation;
              return MaterialPageRoute(
                builder: (_) => CallScreen(
                  conversationId: conversation.id,
                  callType: args['callType'] as String,
                  conversation: conversation,
                  isIncoming: args['isIncoming'] as bool? ?? false,
                  callId: args['callId'] as int?,
                ),
              );
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    );
  }
}
