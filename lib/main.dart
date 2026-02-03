import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart'; // Uncomment this after running flutterfire configure
import 'widgets/common/carousel_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Run 'flutterfire configure' to generate firebase_options.dart
  // and uncomment the options parameter below.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LedgerApp());
}

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ledger Book',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          
          // Initializes the provider with the user (safe to call multiple times)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<TransactionProvider>(context, listen: false).init(user);
          });

          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen(); // Loading/Loading transactions happen inside main/provider
        }
        return Scaffold(
          body: CarouselLoader(
            message: 'Connecting to your account...',
          ),
        );
      },
    );
  }
}
