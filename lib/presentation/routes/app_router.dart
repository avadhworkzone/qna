import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../screens/auth/login_page.dart';
import '../screens/influencer/dashboard_page.dart';
import '../screens/influencer/session_detail_page.dart';
import '../screens/influencer/session_create_page.dart';
import '../screens/influencer/sessions_list_page.dart';
import '../screens/influencer/question_detail_page.dart';
import '../screens/public/public_session_page.dart';
import '../screens/shared/splash_page.dart';
import '../screens/influencer/billing_page.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static GoRouter build(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final isLoggingIn = state.matchedLocation == '/login';
        final isPublic = state.matchedLocation.startsWith('/public/');
        if (authState.status == AuthStatus.unknown) {
          return null;
        }
        if (authState.status == AuthStatus.unauthenticated) {
          return isPublic || isLoggingIn ? null : '/login';
        }
        if (authState.status == AuthStatus.authenticated) {
          if (isLoggingIn) {
            final redirectTo = state.uri.queryParameters['redirect'];
            if (redirectTo != null && redirectTo.isNotEmpty) {
              return redirectTo;
            }
            return '/dashboard';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const InfluencerDashboardPage(),
        ),
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionsListPage(),
        ),
        GoRoute(
          path: '/session/create',
          builder: (context, state) => const SessionCreatePage(),
        ),
        GoRoute(
          path: '/session/:id',
          builder: (context, state) => SessionDetailPage(
            sessionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/question/:id',
          builder: (context, state) => QuestionDetailPage(
            questionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/billing',
          builder: (context, state) => const BillingPage(),
        ),
        GoRoute(
          path: '/public/:publicLink',
          builder: (context, state) => PublicSessionPage(
            publicLink: state.pathParameters['publicLink']!,
          ),
        ),
      ],
    );
  }
}
