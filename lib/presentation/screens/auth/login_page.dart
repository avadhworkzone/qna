import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isLight ? const Color(0xFFF7F8FB) : AppTheme.backgroundColor,
              isLight
                  ? const Color(0xFFFFFFFF)
                  : AppTheme.surfaceColor.withOpacity(0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -120,
              top: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor.withOpacity(isLight ? 0.12 : 0.15),
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryColor.withOpacity(isLight ? 0.1 : 0.12),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 820;
                      final content = [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'QA SaaS Platform',
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Run premium Q&A sessions with live insights, smart ranking, and audience feedback.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: const [
                                    _FeatureChip(label: 'Live Q&A'),
                                    _FeatureChip(label: 'Poll Insights'),
                                    _FeatureChip(label: 'Smart Ranking'),
                                    _FeatureChip(label: 'Winner Picks'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Built for creators who want premium engagement.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Influencer Sign In',
                                        style: Theme.of(context).textTheme.headlineLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Access your dashboard and create live sessions.',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 20),
                                      if (state.errorMessage != null) ...[
                                        Text(
                                          state.errorMessage!,
                                          style: TextStyle(color: AppTheme.errorColor),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      ElevatedButton.icon(
                                        onPressed: state.status == AuthStatus.authenticating
                                            ? null
                                            : () => context
                                                .read<AuthCubit>()
                                                .signInWithGoogle(UserRole.influencer),
                                        icon: const Icon(Icons.login),
                                        label: const Text('Continue with Google'),
                                      ),
                                      if (!kIsWeb) ...[
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: state.status == AuthStatus.authenticating
                                              ? null
                                              : () => context
                                                  .read<AuthCubit>()
                                                  .signInWithApple(UserRole.influencer),
                                          icon: const Icon(Icons.apple),
                                          label: const Text('Continue with Apple'),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Text(
                                        'By continuing, you agree to our Terms and Privacy Policy.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ];

                      return isWide
                          ? Row(children: content)
                          : Column(children: content);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
