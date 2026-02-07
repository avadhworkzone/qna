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

  Future<void> _openFilterDialog() async {
    var tempStatus = _statusFilter;
    var tempDate = _dateFilter;
    var tempRange = _customRange;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Filters'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _StatusFilter.values.map((value) {
                        final label = _statusLabel(value);
                        return ChoiceChip(
                          selected: tempStatus == value,
                          label: Text(label),
                          onSelected: (_) =>
                              setDialogState(() => tempStatus = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Date', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _DateFilter.values.map((value) {
                        final label = _dateLabel(value);
                        return ChoiceChip(
                          selected: tempDate == value,
                          label: Text(label),
                          onSelected: (_) => setDialogState(() {
                            tempDate = value;
                          }),
                        );
                      }).toList(),
                    ),
                    if (tempDate == _DateFilter.custom) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tempRange == null
                                  ? 'No range selected'
                                  : '${tempRange!.start.month}/${tempRange!.start.day}/${tempRange!.start.year}'
                                      ' - ${tempRange!.end.month}/${tempRange!.end.day}/${tempRange!.end.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(DateTime.now().year - 2),
                                lastDate: DateTime(DateTime.now().year + 2),
                              );
                              if (picked != null) {
                                setDialogState(() => tempRange = picked);
                              }
                            },
                            child: const Text('Select'),
                          ),
                          if (tempRange != null)
                            IconButton(
                              onPressed: () =>
                                  setDialogState(() => tempRange = null),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _statusFilter = tempStatus;
                  _dateFilter = tempDate;
                  _customRange = tempRange;
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  String _statusLabel(_StatusFilter value) {
    switch (value) {
      case _StatusFilter.active:
        return 'Active';
      case _StatusFilter.paused:
        return 'Paused';
      case _StatusFilter.expired:
        return 'Expired';
      case _StatusFilter.all:
      default:
        return 'All';
    }
  }

  String _dateLabel(_DateFilter value) {
    switch (value) {
      case _DateFilter.thisWeek:
        return 'This Week';
      case _DateFilter.thisMonth:
        return 'This Month';
      case _DateFilter.thisYear:
        return 'This Year';
      case _DateFilter.custom:
        return 'Custom';
      case _DateFilter.all:
      default:
        return 'All';
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
    final isNarrow = MediaQuery.of(context).size.width < 720;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (user.role != UserRole.influencer) {
          return Center(
            child: Text(
              'Respondents should access sessions via public links.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(user: user, isNarrow: isNarrow),
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
            SizedBox(height: isNarrow ? 12 : 24),
            if (isNarrow) ...[
              Row(
                children: [
                  Text('Sessions',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: IconButton(
                      onPressed: _openFilterDialog,
                      icon: const Icon(Icons.tune),
                      tooltip: 'Filters',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: IconButton(
                      onPressed: () => context.go('/sessions'),
                      icon: const Icon(Icons.list),
                      tooltip: 'View all',
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Text('Your Sessions',
                      style: Theme.of(context).textTheme.headlineMedium),
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
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
                onDateChanged: (value) =>
                    setState(() => _dateFilter = value),
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
            ],
            SizedBox(height: isNarrow ? 8 : 16),
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
                      final isMobile = width < 520;
                      final aspectRatio = isMobile
                          ? 3.2
                          : width > 1100
                              ? 1.9
                              : width > 900
                                  ? 1.9
                                  : width > 620
                                      ? 2.2
                                      : 2.6;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: aspectRatio,
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
  const _DashboardHeader({required this.user, required this.isNarrow});

  final User user;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final headerRow = [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isNarrow ? 20 : 26,
                  backgroundImage:
                      user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Icon(Icons.person, size: isNarrow ? 20 : 26)
                      : null,
                ),
                SizedBox(width: isNarrow ? 8 : 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      user.name,
                      style: isNarrow
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.displaySmall,
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
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Credits', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${user.sessionCredits}',
                              style: Theme.of(context).textTheme.titleMedium),
                          if (user.freeCreditsRemaining > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.teal.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.card_giftcard, size: 14),
                                  const SizedBox(width: 6),
                                  Text('${user.freeCreditsRemaining} free'),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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
    final isNarrow = MediaQuery.of(context).size.width < 520;
    final statusColor =
        session.isActive ? AppTheme.successColor : AppTheme.warningColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: EdgeInsets.all(isNarrow ? 12 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: isNarrow
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 8 : 10,
                    vertical: isNarrow ? 4 : 6,
                  ),
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
            SizedBox(height: isNarrow ? 6 : 8),
            Text(
              session.description,
              maxLines: isNarrow ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              _formatDateTime(session.startTime),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isNarrow ? 4 : 6),
            Text(
              _formatDateTime(session.expiryTime),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
