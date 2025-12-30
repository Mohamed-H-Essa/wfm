import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/repositories/excuse_repository.dart';
import '../../data/models/excuse_request_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'excuse_request_screen.dart';

final excuseRequestsProvider = FutureProvider<List<ExcuseRequestModel>>((ref) async {
  final repository = ExcuseRepository(ref.watch(apiClientProvider));
  final response = await repository.getRequests();
  if (response.success && response.data != null) {
    return (response.data as List<dynamic>)
        .map((r) => ExcuseRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
  throw Exception(response.message ?? 'Failed to load excuse requests');
});

class ExcuseHomeScreen extends ConsumerStatefulWidget {
  const ExcuseHomeScreen({super.key});

  @override
  ConsumerState<ExcuseHomeScreen> createState() => _ExcuseHomeScreenState();
}

class _ExcuseHomeScreenState extends ConsumerState<ExcuseHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(excuseRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excuse Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExcuseRequestScreen()),
              ).then((_) {
                ref.refresh(excuseRequestsProvider);
              });
            },
          ),
        ],
      ),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? const Center(
                child: Text('No excuse requests'),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(excuseRequestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(ExcuseRequestModel request) {
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
                  request.type,
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
            DateFormat('MMM d, y').format(DateTime.parse(request.date)),
            style: TextStyle(
              fontSize: 14,
              color: IntraZeroColors.textSecondary,
            ),
          ),
          if (request.fromTime != null && request.toTime != null) ...[
            const SizedBox(height: 4),
            Text(
              '${request.fromTime} - ${request.toTime}',
              style: TextStyle(
                fontSize: 14,
                color: IntraZeroColors.textSecondary,
              ),
            ),
          ],
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
