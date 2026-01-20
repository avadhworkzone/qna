// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Q&Aストーリー';

  @override
  String get askQuestion => '質問をしてください...';

  @override
  String get post => '投稿';

  @override
  String get writeAnswer => '回答を書いてください...';

  @override
  String get send => '送信';

  @override
  String get answers => '回答';

  @override
  String get noQuestions => 'まだ質問がありません\\n最初の質問を投稿してください！';

  @override
  String get errorLoading => '質問の読み込みエラー';

  @override
  String get selectLanguage => '言語を選択';

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
