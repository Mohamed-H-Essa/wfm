import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/forgot_request_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Typed params class for proper equality
@immutable
class ForgotRequestsParams {
  final String? status;
  final int page;
  final int perPage;
  
  const ForgotRequestsParams({
    this.status,
    this.page = 1,
    this.perPage = 10,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotRequestsParams &&
          status == other.status &&
          page == other.page &&
          perPage == other.perPage;
  
  @override
  int get hashCode => Object.hash(status, page, perPage);
}

final forgotRequestsProvider = FutureProvider.family<ForgotRequestsListModel, ForgotRequestsParams>((ref, params) async {
  final repository = AttendanceRepository(ref.read(apiClientProvider));
  final response = await repository.getForgotRequests(
    status: params.status,
    page: params.page,
    perPage: params.perPage,
  );
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    // Return empty model on error
    return ForgotRequestsListModel(
      requests: [],
      pagination: PaginationModel(
        currentPage: 1,
        totalPages: 1,
        totalRecords: 0,
      ),
    );
  }
});

class ForgotRequestsScreen extends ConsumerStatefulWidget {
  const ForgotRequestsScreen({super.key});

  @override
  ConsumerState<ForgotRequestsScreen> createState() => _ForgotRequestsScreenState();
}

class _ForgotRequestsScreenState extends ConsumerState<ForgotRequestsScreen> {
  String? _selectedStatus;
  int _currentPage = 1;
  
  @override
  Widget build(BuildContext context) {
    final params = ForgotRequestsParams(
      status: _selectedStatus,
      page: _currentPage,
      perPage: 10,
    );
    
    final requestsAsync = ref.watch(forgotRequestsProvider(params));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Check-in/out Requests'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'ALL' ? null : value;
                _currentPage = 1;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('All')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pending')),
              const PopupMenuItem(value: 'APPROVED', child: Text('Approved')),
              const PopupMenuItem(value: 'REJECTED', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: requestsAsync.when(
        data: (requestsList) {
          if (requestsList.requests.isEmpty) {
            return const Center(
              child: Text('No forgot requests found'),
            );
          }
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requestsList.requests.length,
                  itemBuilder: (context, index) {
                    final request = requestsList.requests[index];
                    return _buildRequestCard(request);
                  },
                ),
              ),
              if (requestsList.pagination.totalPages > 1)
                _buildPaginationControls(requestsList.pagination),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(forgotRequestsProvider(params));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRequestCard(ForgotRequestModel request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case 'APPROVED':
        statusColor = IntraZeroColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = IntraZeroColors.danger;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = IntraZeroColors.warning;
        statusIcon = Icons.pending;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, y').format(DateTime.parse(request.date)),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${request.type.replaceAll('_', ' ')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: IntraZeroColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        request.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (request.status == 'PENDING')
                  IconButton(
                    icon: const Icon(Icons.cancel, color: IntraZeroColors.danger),
                    onPressed: () => _cancelRequest(request.id),
                    tooltip: 'Cancel Request',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (request.requestedCheckInTime != null)
              Text(
                'Check-in: ${request.requestedCheckInTime}',
                style: TextStyle(
                  fontSize: 14,
                  color: IntraZeroColors.textSecondary,
                ),
              ),
            if (request.requestedCheckOutTime != null)
              Text(
                'Check-out: ${request.requestedCheckOutTime}',
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
                color: IntraZeroColors.textPrimary,
              ),
            ),
            if (request.approvedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Approved: ${DateFormat('MMM d, y • h:mm a').format(request.approvedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: IntraZeroColors.textSecondary,
                ),
              ),
            ],
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: IntraZeroColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: IntraZeroColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejected: ${request.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: IntraZeroColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaginationControls(PaginationModel pagination) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IntraZeroColors.surface,
        border: Border(
          top: BorderSide(color: IntraZeroColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          Text(
            'Page ${pagination.currentPage} of ${pagination.totalPages}',
            style: TextStyle(color: IntraZeroColors.textSecondary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < pagination.totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
  
  Future<void> _cancelRequest(int requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final repository = AttendanceRepository(ref.read(apiClientProvider));
      final response = await repository.cancelForgotRequest(requestId);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: IntraZeroColors.success,
            ),
          );
          // Refresh the list
          ref.invalidate(forgotRequestsProvider(ForgotRequestsParams(
            status: _selectedStatus,
            page: _currentPage,
            perPage: 10,
          )));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to cancel request'),
              backgroundColor: IntraZeroColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }
}

