// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Q&A Stories';

  @override
  String get askQuestion => 'Ask a question...';

  @override
  String get post => 'Post';

  @override
  String get writeAnswer => 'Write your answer...';

  @override
  String get send => 'Send';

  @override
  String get answers => 'Answers';

  @override
  String get noQuestions => 'No questions yet\nPost the first question!';

  @override
  String get errorLoading => 'Error loading questions';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signOut => 'Sign Out';
}
