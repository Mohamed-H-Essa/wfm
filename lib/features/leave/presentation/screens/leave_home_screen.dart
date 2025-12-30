import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/leave_provider.dart';
import '../../data/models/leave_request_model.dart';
import 'leave_request_screen.dart';

class LeaveHomeScreen extends ConsumerStatefulWidget {
  const LeaveHomeScreen({super.key});

  @override
  ConsumerState<LeaveHomeScreen> createState() => _LeaveHomeScreenState();
}

class _LeaveHomeScreenState extends ConsumerState<LeaveHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(leaveBalanceProvider);
    final requestsAsync = ref.watch(leaveRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
              ).then((_) {
                ref.refresh(leaveBalanceProvider);
                ref.refresh(leaveRequestsProvider);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            balanceAsync.when(
              data: (balance) => _buildBalanceCard(balance),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('Unable to load leave balance')),
            ),
            const SizedBox(height: 20),
            requestsAsync.when(
              data: (requests) => _buildRequestsList(requests),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('No leave requests')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(balance) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave Balance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: IntraZeroColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildLeaveTypeCard('Annual Leave', balance.annualLeave, IntraZeroColors.info),
          const SizedBox(height: 12),
          _buildLeaveTypeCard('Accidental Leave', balance.accidentalLeave, IntraZeroColors.warning),
          const SizedBox(height: 12),
          _buildLeaveTypeCard('Marriage Leave', balance.marriageLeave, IntraZeroColors.success),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard(String title, typeBalance, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBalanceItem('Total', typeBalance.total.toString(), IntraZeroColors.textPrimary),
                    const SizedBox(width: 16),
                    _buildBalanceItem('Used', typeBalance.used.toString(), IntraZeroColors.danger),
                    const SizedBox(width: 16),
                    _buildBalanceItem('Remaining', typeBalance.remaining.toString(), IntraZeroColors.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: IntraZeroColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(List<LeaveRequestModel> requests) {
    if (requests.isEmpty) {
      return GlassmorphismCard(
        child: const Center(
          child: Text('No leave requests'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: IntraZeroColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...requests.map((request) => _buildRequestCard(request)),
      ],
    );
  }

  Widget _buildRequestCard(LeaveRequestModel request) {
    Color statusColor;
    switch (request.status) {
      case 'APPROVED':
        statusColor = IntraZeroColors.success;
        break;
      case 'REJECTED':
        statusColor = IntraZeroColors.danger;
        break;
      default:
        statusColor = IntraZeroColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IntraZeroColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IntraZeroColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.leaveType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IntraZeroColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${request.startDate} to ${request.endDate} (${request.numberOfDays} days)',
            style: TextStyle(
              fontSize: 14,
              color: IntraZeroColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.reason,
            style: TextStyle(
              fontSize: 14,
              color: IntraZeroColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
