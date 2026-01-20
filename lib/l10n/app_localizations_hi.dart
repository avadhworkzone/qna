// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Q&A Stories';

  @override
  String get askQuestion => 'Koi question puchiye...';

  @override
  String get post => 'Post';

  @override
  String get writeAnswer => 'Apna answer likhen...';

  @override
  String get send => 'Send';

  @override
  String get answers => 'Answers';

  @override
  String get noQuestions =>
      'Koi questions nahi hain\\nPehla question post kariye!';

  @override
  String get errorLoading => 'Questions load karne mein error';

  @override
  String get selectLanguage => 'Language Select Kariye';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Password Confirm Kariye';

  @override
  String get alreadyHaveAccount => 'Pehle se account hai?';

  @override
  String get dontHaveAccount => 'Account nahi hai?';

  @override
  String get signOut => 'Sign Out';
}
