import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../screens/auth/login_page.dart';
import '../screens/influencer/dashboard_page.dart';
import '../screens/influencer/session_detail_page.dart';
import '../screens/influencer/session_create_page.dart';
import '../screens/influencer/sessions_list_page.dart';
import '../screens/influencer/question_detail_page.dart';
import '../screens/public/public_session_page.dart';
import '../screens/public/join_audience_page.dart';
import '../screens/shared/splash_page.dart';
import '../screens/influencer/billing_page.dart';
import '../layouts/influencer_shell.dart';
import '../screens/influencer/deleted_sessions_page.dart';
import '../screens/influencer/payment_history_page.dart';
import '../screens/influencer/audience_pool_page.dart';
import 'go_router_refresh_stream.dart';
import '../../core/utils/web_storage_selector.dart';

class AppRouter {
  static GoRouter build(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRoot = state.matchedLocation == '/';
        final isPublic = state.matchedLocation.startsWith('/public/');
        if (authState.status == AuthStatus.unknown) {
          return null;
        }
        if (authState.status == AuthStatus.unauthenticated) {
          if (isPublic || isLoggingIn) return null;
          if (isRoot) return '/login';
          final from = Uri.encodeComponent(state.uri.toString());
          if (kIsWeb) {
            WebStorage.set('post_login_redirect', state.uri.toString());
          }
          return '/login?redirect=$from';
        }
        if (authState.status == AuthStatus.authenticated) {
          if (isRoot) return '/dashboard';
          if (isLoggingIn) {
            final redirectTo = state.uri.queryParameters['redirect'];
            if (redirectTo != null && redirectTo.isNotEmpty) {
              return redirectTo;
            }
            if (kIsWeb) {
              final stored = WebStorage.get('post_login_redirect');
              if (stored != null && stored.isNotEmpty) {
                WebStorage.remove('post_login_redirect');
                return stored;
              }
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
        ShellRoute(
          builder: (context, state, child) => InfluencerShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: InfluencerDashboardPage(),
              ),
            ),
            GoRoute(
              path: '/sessions',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SessionsListPage(),
              ),
            ),
            GoRoute(
              path: '/session/create',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SessionCreatePage(),
              ),
            ),
            GoRoute(
              path: '/session/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                child: SessionDetailPage(
                  sessionId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: '/question/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                child: QuestionDetailPage(
                  questionId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: '/billing',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BillingPage(),
              ),
            ),
            GoRoute(
              path: '/deleted-sessions',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DeletedSessionsPage(),
              ),
            ),
            GoRoute(
              path: '/payments',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PaymentHistoryPage(),
              ),
            ),
            GoRoute(
              path: '/audience-pool',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AudiencePoolPage(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/public/:publicLink',
          builder: (context, state) => PublicSessionPage(
            publicLink: state.pathParameters['publicLink']!,
          ),
        ),
        GoRoute(
          path: '/join/:organizerId',
          builder: (context, state) => JoinAudiencePage(
            organizerId: state.pathParameters['organizerId']!,
          ),
        ),
      ],
    );
  }
}
