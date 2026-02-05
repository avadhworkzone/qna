import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/billing_remote_data_source.dart';
import '../../data/datasources/poll_remote_data_source.dart';
import '../../data/datasources/question_remote_data_source.dart';
import '../../data/datasources/session_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../data/repositories/poll_repository_impl.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/poll_repository.dart';
import '../../domain/repositories/question_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/billing/start_subscription_checkout.dart';
import '../../domain/usecases/polls/submit_poll_response.dart';
import '../../domain/usecases/questions/create_question.dart';
import '../../domain/usecases/questions/like_question.dart';
import '../../domain/usecases/questions/update_question_text.dart';
import '../../domain/usecases/sessions/create_session.dart';
import '../../domain/usecases/sessions/load_sessions.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instanceFor(region: 'us-central1'),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<FirebaseAuth>(), sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<SessionRemoteDataSource>(
    () => SessionRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<QuestionRemoteDataSource>(
    () => QuestionRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<PollRemoteDataSource>(
    () => PollRemoteDataSource(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<BillingRemoteDataSource>(
    () => BillingRemoteDataSource(sl<FirebaseFunctions>(), sl<FirebaseAuth>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(sl<SessionRemoteDataSource>()),
  );
  sl.registerLazySingleton<QuestionRepository>(
    () => QuestionRepositoryImpl(sl<QuestionRemoteDataSource>()),
  );
  sl.registerLazySingleton<PollRepository>(
    () => PollRepositoryImpl(sl<PollRemoteDataSource>()),
  );
  sl.registerLazySingleton<BillingRepository>(
    () => BillingRepositoryImpl(sl<BillingRemoteDataSource>()),
  );

  // Use cases
  sl.registerFactory(() => CreateSession(sl<SessionRepository>()));
  sl.registerFactory(() => LoadSessions(sl<SessionRepository>()));
  sl.registerFactory(() => CreateQuestion(sl<QuestionRepository>()));
  sl.registerFactory(() => LikeQuestion(sl<QuestionRepository>()));
  sl.registerFactory(() => UpdateQuestionText(sl<QuestionRepository>()));
  sl.registerFactory(() => SubmitPollResponse(sl<PollRepository>()));
  sl.registerFactory(() => StartSubscriptionCheckout(sl<BillingRepository>()));
  sl.registerFactory(() => ConfirmCheckout(sl<BillingRepository>()));
}
