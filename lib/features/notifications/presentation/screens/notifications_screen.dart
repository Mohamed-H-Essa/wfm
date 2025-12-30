import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final notificationsProvider = FutureProvider.family<NotificationListModel, Map<String, dynamic>>((ref, params) async {
  final repository = NotificationRepository(ref.watch(apiClientProvider));
  final response = await repository.getNotifications(
    unreadOnly: params['unread_only'] as bool? ?? false,
    page: params['page'] as int? ?? 1,
  );
  
  if (response.success && response.data != null) {
    return NotificationListModel.fromJson(response.data!);
  }
  throw Exception(response.message ?? 'Failed to load notifications');
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider({
      'unread_only': _unreadOnly,
      'page': _page,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _unreadOnly = !_unreadOnly;
              });
            },
            tooltip: _unreadOnly ? 'Show all' : 'Show unread only',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(notificationsProvider({
                'unread_only': _unreadOnly,
                'page': _page,
              }));
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notificationList) => notificationList.notifications.isEmpty
            ? const Center(
                child: Text('No notifications'),
              )
            : Column(
                children: [
                  if (notificationList.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: IntraZeroColors.info.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: IntraZeroColors.info),
                          const SizedBox(width: 8),
                          Text(
                            '${notificationList.unreadCount} unread notification${notificationList.unreadCount > 1 ? 's' : ''}',
                            style: TextStyle(color: IntraZeroColors.info),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: notificationList.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notificationList.notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(notificationsProvider({
                  'unread_only': _unreadOnly,
                  'page': _page,
                })),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case 'LEAVE_APPROVED':
      case 'LEAVE_REJECTED':
        iconData = Icons.event;
        iconColor = IntraZeroColors.info;
        break;
      case 'ATTENDANCE':
        iconData = Icons.access_time;
        iconColor = IntraZeroColors.success;
        break;
      case 'EXCUSE_APPROVED':
      case 'EXCUSE_REJECTED':
        iconData = Icons.info;
        iconColor = IntraZeroColors.warning;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = IntraZeroColors.textSecondary;
    }

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        if (!notification.isRead) {
          final repository = NotificationRepository(ref.read(apiClientProvider));
          await repository.markAsRead(notification.id);
          ref.refresh(notificationsProvider({
            'unread_only': _unreadOnly,
            'page': _page,
          }));
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: IntraZeroColors.success,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            final repository = NotificationRepository(ref.read(apiClientProvider));
            await repository.markAsRead(notification.id);
            ref.refresh(notificationsProvider({
              'unread_only': _unreadOnly,
              'page': _page,
            }));
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? IntraZeroColors.surface
                : IntraZeroColors.primaryGradient.colors.first.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? IntraZeroColors.borderLight
                  : IntraZeroColors.primaryGradient.colors.first,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: IntraZeroColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(
                        DateTime.parse(notification.createdAt),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: IntraZeroColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: IntraZeroColors.info,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
