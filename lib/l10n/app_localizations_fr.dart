// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Histoires Q&R';

  @override
  String get askQuestion => 'Posez une question...';

  @override
  String get post => 'Publier';

  @override
  String get writeAnswer => 'Écrivez votre réponse...';

  @override
  String get send => 'Envoyer';

  @override
  String get answers => 'Réponses';

  @override
  String get noQuestions =>
      'Aucune question pour le moment\\nPostez la première question !';

  @override
  String get errorLoading => 'Erreur lors du chargement des questions';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signIn => 'Se connecter';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte?';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte?';

  @override
  String get signOut => 'Se déconnecter';
}
