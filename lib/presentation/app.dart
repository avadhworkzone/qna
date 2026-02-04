import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/theme/app_theme.dart';
import 'bloc/auth/auth_cubit.dart';
import 'bloc/billing/billing_cubit.dart';
import 'bloc/polls/polls_cubit.dart';
import 'bloc/questions/questions_cubit.dart';
import 'bloc/sessions/sessions_cubit.dart';
import 'routes/app_router.dart';

class QASaaSApp extends StatelessWidget {
  const QASaaSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = AuthCubit(sl());
    final router = AppRouter.build(authCubit);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => authCubit),
        BlocProvider<SessionsCubit>(
          create: (_) => SessionsCubit(sl(), sl(), sl()),
        ),
        BlocProvider<QuestionsCubit>(
          create: (_) => QuestionsCubit(sl(), sl(), sl(), sl()),
        ),
        BlocProvider<PollsCubit>(
          create: (_) => PollsCubit(sl(), sl()),
        ),
        BlocProvider<BillingCubit>(
          create: (_) => BillingCubit(sl()),
        ),
      ],
      child: MaterialApp.router(
        title: 'QA SaaS Platform',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
