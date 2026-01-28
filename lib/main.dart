import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'admin_login_screen.dart';
import 'admin_qa_home_page.dart';
import 'super_admin_panel.dart';

// Commented out old imports
// import 'auth/auth_screen.dart';
// import 'qa_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Sign out any existing user to show login screen
  // await FirebaseAuth.instance.signOut();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q&A App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('zh'),
        Locale('ja'),
        Locale('ar'),
        Locale('pt'),
        Locale('ru'),
      ],
      // Admin Authentication System
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData) {
            // User is logged in, check if admin
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('admins')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
                  // Check if super admin
                  Map<String, dynamic> adminData = adminSnapshot.data!.data() as Map<String, dynamic>;
                  bool isSuperAdmin = adminData['isSuperAdmin'] ?? false;
                  
                  if (isSuperAdmin) {
                    // Show super admin panel
                    return SuperAdminPanel(onLanguageChange: _changeLanguage);
                  } else {
                    // Show regular admin Q&A panel
                    return AdminQAHomePage(onLanguageChange: _changeLanguage);
                  }
                } else {
                  // User is not admin, sign out and show login
                  FirebaseAuth.instance.signOut();
                  return const AdminLoginScreen();
                }
              },
            );
          }
          
          // User not logged in, show login screen
          return const AdminLoginScreen();
        },
      ),
      
      // Old code commented out
      /*
      // Temporarily bypassing authentication - directly showing Q&A screen
      home: QAHomePage(onLanguageChange: _changeLanguage),
      
      // Commented out authentication logic - uncomment to restore Google login
      /*
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData) {
            return QAHomePage(onLanguageChange: _changeLanguage);
          }
          
          return AuthScreen(
            onLogin: () {
              // Navigation handled by StreamBuilder
            },
          );
        },
      ),
      */
      */
    );
  }
}
