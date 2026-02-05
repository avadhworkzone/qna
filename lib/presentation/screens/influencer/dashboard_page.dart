import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/session.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/sessions/sessions_cubit.dart';
import '../../bloc/sessions/sessions_state.dart';
import '../../widgets/glass_card.dart';

class InfluencerDashboardPage extends StatefulWidget {
  const InfluencerDashboardPage({super.key});

  @override
  State<InfluencerDashboardPage> createState() => _InfluencerDashboardPageState();
}

class _InfluencerDashboardPageState extends State<InfluencerDashboardPage> {
  _StatusFilter _statusFilter = _StatusFilter.all;
  _DateFilter _dateFilter = _DateFilter.all;
  DateTimeRange? _customRange;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthCubit>().state;
    if (authState.user != null) {
      context.read<SessionsCubit>().watchSessions(authState.user!.id);
    }
  }

  List<Session> _applyFilters(List<Session> sessions) {
    final now = DateTime.now();
    final filteredByStatus = sessions
        .where((session) => session.deletedAt == null)
        .where((session) {
      switch (_statusFilter) {
        case _StatusFilter.active:
          return session.isActive;
        case _StatusFilter.paused:
          return session.status == SessionStatus.paused;
        case _StatusFilter.expired:
          final expiry = session.expiryTime;
          return expiry != null && expiry.isBefore(now);
        case _StatusFilter.all:
        default:
          return true;
      }
    }).toList();

    return filteredByStatus.where((session) {
      final created = session.createdAt;
      switch (_dateFilter) {
        case _DateFilter.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return created.isAfter(
            DateTime(weekStart.year, weekStart.month, weekStart.day),
          );
        case _DateFilter.thisMonth:
          return created.year == now.year && created.month == now.month;
        case _DateFilter.thisYear:
          return created.year == now.year;
        case _DateFilter.custom:
          if (_customRange == null) return true;
          return created.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
              created.isBefore(_customRange!.end.add(const Duration(seconds: 1)));
        case _DateFilter.all:
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (user.role != UserRole.influencer) {
          return Center(
            child: Text(
              'Audience users should access sessions via public links.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(user: user),
        if (user.sessionCredits <= 0) ...[
          const SizedBox(height: 12),
          GlassCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded),
                const Text(
                  'You have no session credits left. Purchase a plan to create more sessions.',
                ),
                TextButton(
                  onPressed: () => context.go('/billing'),
                  child: const Text('View Plans'),
                ),
              ],
            ),
          ),
        ],
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Your Sessions', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/sessions'),
                  icon: const Icon(Icons.list),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FiltersRow(
              statusFilter: _statusFilter,
              dateFilter: _dateFilter,
              customRange: _customRange,
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onDateChanged: (value) => setState(() => _dateFilter = value),
              onCustomRangeTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(DateTime.now().year - 2),
                  lastDate: DateTime(DateTime.now().year + 2),
                );
                if (picked != null) {
                  setState(() {
                    _customRange = picked;
                    _dateFilter = _DateFilter.custom;
                  });
                }
              },
              onClearCustomRange: () => setState(() => _customRange = null),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<SessionsCubit, SessionsState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filteredSessions = _applyFilters(state.sessions);
                  if (filteredSessions.isEmpty) {
                    return Center(
                      child: GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No sessions match your filters.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 1100
                          ? 4
                          : width > 900
                              ? 3
                              : width > 620
                                  ? 2
                                  : 1;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.9,
                        ),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          return _SessionCard(
                            session: session,
                            onTap: () => context.go('/session/${session.id}'),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final headerRow = [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 26)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ],
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 8),
                  Text('Credits: ${user.sessionCredits}'),
                ],
              ),
            ),
          ];

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerRow.first,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [headerRow[1]],
                ),
              ],
            );
          }

          return Row(
            children: [
              headerRow.first,
              const Spacer(),
              headerRow[1],
            ],
          );
        },
      );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.statusFilter,
    required this.dateFilter,
    required this.customRange,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onCustomRangeTap,
    required this.onClearCustomRange,
  });

  final _StatusFilter statusFilter;
  final _DateFilter dateFilter;
  final DateTimeRange? customRange;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<_DateFilter> onDateChanged;
  final VoidCallback onCustomRangeTap;
  final VoidCallback onClearCustomRange;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _FilterChipGroup<_StatusFilter>(
          label: 'Status',
          value: statusFilter,
          items: const [
            _FilterItem(_StatusFilter.all, 'All'),
            _FilterItem(_StatusFilter.active, 'Active'),
            _FilterItem(_StatusFilter.paused, 'Paused'),
            _FilterItem(_StatusFilter.expired, 'Expired'),
          ],
          onChanged: onStatusChanged,
        ),
        _FilterChipGroup<_DateFilter>(
          label: 'Date',
          value: dateFilter,
          items: const [
            _FilterItem(_DateFilter.all, 'All'),
            _FilterItem(_DateFilter.thisWeek, 'This Week'),
            _FilterItem(_DateFilter.thisMonth, 'This Month'),
            _FilterItem(_DateFilter.thisYear, 'This Year'),
            _FilterItem(_DateFilter.custom, 'Custom'),
          ],
          onChanged: onDateChanged,
        ),
        if (dateFilter == _DateFilter.custom)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customRange == null
                      ? 'Pick range'
                      : '${customRange!.start.month}/${customRange!.start.day}/${customRange!.start.year}'
                          ' - ${customRange!.end.month}/${customRange!.end.day}/${customRange!.end.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCustomRangeTap,
                  child: const Text('Select'),
                ),
                if (customRange != null)
                  IconButton(
                    onPressed: onClearCustomRange,
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterChipGroup<T> extends StatelessWidget {
  const _FilterChipGroup({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_FilterItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          ...items.map((item) {
            final isSelected = item.value == value;
            return ChoiceChip(
              selected: isSelected,
              label: Text(item.label),
              onSelected: (_) => onChanged(item.value),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterItem<T> {
  const _FilterItem(this.value, this.label);
  final T value;
  final String label;
}

enum _StatusFilter { all, active, paused, expired }

enum _DateFilter { all, thisWeek, thisMonth, thisYear, custom }

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Not set';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year.toString();
    var hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final amPm = isPm ? 'PM' : 'AM';
    return '$day / $month / $year  $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        session.isActive ? AppTheme.successColor : AppTheme.warningColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    session.isActive ? 'LIVE' : 'PAUSED',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  _formatDateTime(session.startTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _formatDateTime(session.expiryTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
