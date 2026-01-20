// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Historias de P&R';

  @override
  String get askQuestion => 'Haz una pregunta...';

  @override
  String get post => 'Publicar';

  @override
  String get writeAnswer => 'Escribe tu respuesta...';

  @override
  String get send => 'Enviar';

  @override
  String get answers => 'Respuestas';

  @override
  String get noQuestions =>
      'No hay preguntas aún\\n¡Publica la primera pregunta!';

  @override
  String get errorLoading => 'Error al cargar preguntas';

  @override
  String get selectLanguage => 'Seleccionar idioma';

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
