// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '问答故事';

  @override
  String get askQuestion => '提出问题...';

  @override
  String get post => '发布';

  @override
  String get writeAnswer => '写下您的答案...';

  @override
  String get send => '发送';

  @override
  String get answers => '答案';

  @override
  String get noQuestions => '还没有问题\\n发布第一个问题！';

  @override
  String get errorLoading => '加载问题时出错';

  @override
  String get selectLanguage => '选择语言';

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
