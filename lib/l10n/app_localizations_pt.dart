// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Histórias de P&R';

  @override
  String get askQuestion => 'Faça uma pergunta...';

  @override
  String get post => 'Publicar';

  @override
  String get writeAnswer => 'Escreva sua resposta...';

  @override
  String get send => 'Enviar';

  @override
  String get answers => 'Respostas';

  @override
  String get noQuestions =>
      'Ainda não há perguntas\\nPublique a primeira pergunta!';

  @override
  String get errorLoading => 'Erro ao carregar perguntas';

  @override
  String get selectLanguage => 'Selecionar idioma';

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
