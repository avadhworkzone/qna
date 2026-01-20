// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قصص الأسئلة والأجوبة';

  @override
  String get askQuestion => 'اطرح سؤالاً...';

  @override
  String get post => 'نشر';

  @override
  String get writeAnswer => 'اكتب إجابتك...';

  @override
  String get send => 'إرسال';

  @override
  String get answers => 'الإجابات';

  @override
  String get noQuestions => 'لا توجد أسئلة حتى الآن\\nانشر السؤال الأول!';

  @override
  String get errorLoading => 'خطأ في تحميل الأسئلة';

  @override
  String get selectLanguage => 'اختر اللغة';

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
