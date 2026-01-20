// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Истории вопросов и ответов';

  @override
  String get askQuestion => 'Задайте вопрос...';

  @override
  String get post => 'Опубликовать';

  @override
  String get writeAnswer => 'Напишите свой ответ...';

  @override
  String get send => 'Отправить';

  @override
  String get answers => 'Ответы';

  @override
  String get noQuestions => 'Пока нет вопросов\\nОпубликуйте первый вопрос!';

  @override
  String get errorLoading => 'Ошибка загрузки вопросов';

  @override
  String get selectLanguage => 'Выберите язык';

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
