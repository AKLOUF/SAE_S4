import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:openminds/services/notification_service.dart';
import 'firebase_options.dart';
import 'screens/benevole/parcours_screen.dart';

// Modèles
import 'models/formation_model.dart';

// Benevole
import 'screens/benevole/login_screen.dart';
import 'screens/benevole/dashboard_screen.dart';
import 'screens/benevole/catalogue_screen.dart';
import 'screens/benevole/formation_detail_screen.dart';
import 'screens/benevole/quiz_screen.dart';

// Formateur
import 'screens/formateur/sessions_screen.dart';

// Admin
import 'screens/admin/stats_screen.dart';
import 'screens/admin/create_formation_screen.dart';
import 'screens/admin/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('fr_FR', null);
  await NotificationService.init();
  runApp(const OpenMindsApp());
}

class OpenMindsApp extends StatelessWidget {
  const OpenMindsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenMinds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/benevole/dashboard': (ctx) => const DashboardScreen(),
        '/benevole/catalogue': (ctx) => const CatalogueScreen(),
        '/benevole/parcours': (ctx) => const ParcoursScreen(),
        '/formateur/sessions': (ctx) => const SessionsScreen(),
        '/admin/stats': (ctx) => const StatsScreen(),
        '/admin/create-formation': (ctx) => const CreateFormationScreen(),
        '/admin/calendar': (ctx) => const CalendarAdminScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/benevole/formation') {
          final formation = settings.arguments as FormationModel;
          return MaterialPageRoute(
            builder: (ctx) => FormationDetailScreen(formation: formation),
          );
        }

        if (settings.name == '/benevole/quiz') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (ctx) => QuizScreen(
              formationId: args['formationId'],
              titrFormation: args['titre'],
            ),
          );
        }

        return null;
      },
    );
  }
}