import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/api_response.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Typed params class for proper equality
@immutable
class NotificationsParams {
  final bool unreadOnly;
  final int page;

  const NotificationsParams({
    this.unreadOnly = false,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationsParams &&
          unreadOnly == other.unreadOnly &&
          page == other.page;

  @override
  int get hashCode => Object.hash(unreadOnly, page);
}

// Cache for notifications to prevent frequent API calls (1 hour cache)
class _NotificationCache {
  final NotificationListModel data;
  final DateTime timestamp;
  _NotificationCache(this.data, this.timestamp);
}

final _notificationsCache = <String, _NotificationCache>{};
const Duration _cacheDuration = Duration(hours: 1);

final notificationsProvider = FutureProvider.family<NotificationListModel, NotificationsParams>((ref, params) async {
  final cacheKey = '${params.unreadOnly}_${params.page}';
  final cached = _notificationsCache[cacheKey];
  
  // Return cached data if still valid (less than 1 hour old)
  if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheDuration) {
    return cached.data;
  }
  
  // Return empty model instead of throwing
  final emptyData = NotificationListModel(
    notifications: [],
    unreadCount: 0,
    pagination: PaginationModel(
      currentPage: 1,
      totalPages: 1,
      totalRecords: 0,
    ),
  );
  
  return (() async {
    try {
      final repository = NotificationRepository(ref.read(apiClientProvider));
      final response = await repository.getNotifications(
        unreadOnly: params.unreadOnly,
        page: params.page,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Request timeout',
          statusCode: null,
        ),
      );
      
      print('📥 [NOTIFICATIONS] Response received - success: ${response.success}, statusCode: ${response.statusCode}');
      print('📥 [NOTIFICATIONS] Response data is null: ${response.data == null}');
      if (response.data != null) {
        print('📥 [NOTIFICATIONS] Response data keys: ${(response.data as Map).keys.toList()}');
      }
      
      if (response.success && response.data != null) {
        try {
          print('📥 [NOTIFICATIONS] Parsing data...');
          final data = NotificationListModel.fromJson(response.data!);
          print('✅ [NOTIFICATIONS] Parsed successfully - notifications: ${data.notifications.length}');
          // Cache the result
          _notificationsCache[cacheKey] = _NotificationCache(data, DateTime.now());
          return data;
        } catch (e, stack) {
          print('❌ [NOTIFICATIONS] Parse error: $e');
          print('❌ [NOTIFICATIONS] Stack: $stack');
          print('❌ [NOTIFICATIONS] Response data: ${response.data}');
          // Return empty model if parsing fails
        }
      } else {
        print('⚠️ [NOTIFICATIONS] Response not successful or data is null');
        print('⚠️ [NOTIFICATIONS] Message: ${response.message}');
      }
    } catch (e, stack) {
      print('❌ [NOTIFICATIONS] Exception: $e');
      print('❌ [NOTIFICATIONS] Stack: $stack');
      // Silently handle errors
    }
    
    _notificationsCache[cacheKey] = _NotificationCache(emptyData, DateTime.now());
    return emptyData;
  })().timeout(
    const Duration(seconds: 12),
    onTimeout: () {
      _notificationsCache[cacheKey] = _NotificationCache(emptyData, DateTime.now());
      return emptyData;
    },
  );
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;
  int _page = 1;
  DateTime? _lastRefreshTime;
  DateTime? _lastMarkAsReadTime;
  static const Duration _minRefreshInterval = Duration(minutes: 1); // Minimum 1 minute between refreshes
  static const Duration _minMarkAsReadInterval = Duration(seconds: 2); // Minimum 2 seconds between mark as read calls

  @override
  Widget build(BuildContext context) {
    final params = NotificationsParams(
      unreadOnly: _unreadOnly,
      page: _page,
    );
    final notificationsAsync = ref.watch(notificationsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read button (only show if there are unread notifications)
          Builder(
            builder: (context) {
              return notificationsAsync.when(
                data: (notificationList) {
                  final unreadCount = notificationList.unreadCount;
                  if (unreadCount > 0) {
                    return IconButton(
                      icon: const Icon(Icons.done_all),
                      tooltip: 'Mark all as read',
                      onPressed: () async {
                        // Get all unread notification IDs
                        final unreadIds = notificationList.notifications
                            .where((n) => !n.isRead)
                            .map((n) => n.id)
                            .toList();
                        
                        if (unreadIds.isNotEmpty) {
                          // Show loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Marking all as read...'),
                                ],
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          
                          // Mark all as read
                          final repository = NotificationRepository(ref.read(apiClientProvider));
                          final response = await repository.markAsReadMultiple(unreadIds);
                          
                          if (response.success) {
                            // Clear cache to force fresh fetch
                            _notificationsCache.clear();
                            
                            // Invalidate all notification providers (for both list and counter)
                            ref.invalidate(notificationsProvider(
                              NotificationsParams(
                                unreadOnly: _unreadOnly,
                                page: _page,
                              ),
                            ));
                            // Also invalidate the counter provider (unreadOnly: false, page: 1)
                            ref.invalidate(notificationsProvider(
                              NotificationsParams(
                                unreadOnly: false,
                                page: 1,
                              ),
                            ));
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${unreadIds.length} notification(s) marked as read'),
                                  backgroundColor: IntraZeroColors.success,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response.message ?? 'Failed to mark all as read'),
                                  backgroundColor: IntraZeroColors.danger,
                                ),
                              );
                            }
                          }
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
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
              // Throttle refresh - only allow refresh if enough time has passed (1 hour for cache)
              final now = DateTime.now();
              final refreshParams = NotificationsParams(
                unreadOnly: _unreadOnly,
                page: _page,
              );
              final cacheKey = '${_unreadOnly}_$_page';
              final cached = _notificationsCache[cacheKey];
              
              // Clear cache if it's been more than 1 hour, or force refresh
              if (cached == null || now.difference(cached.timestamp) >= _cacheDuration) {
                _lastRefreshTime = now;
                // Clear cache to force fresh fetch
                _notificationsCache.remove(cacheKey);
                ref.refresh(notificationsProvider(refreshParams));
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notificationList) {
          print('🎨 [NOTIFICATIONS] UI rendering with data - notifications: ${notificationList.notifications.length}');
          return notificationList.notifications.isEmpty
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
              );
        },
        loading: () {
          print('⏳ [NOTIFICATIONS] UI showing loading state');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('❌ [NOTIFICATIONS] UI showing error: $error');
          print('❌ [NOTIFICATIONS] Stack: $stack');
          return const Center(child: Text('No notifications'));
        },
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
          // Throttle mark as read calls
          final now = DateTime.now();
          if (_lastMarkAsReadTime == null || 
              now.difference(_lastMarkAsReadTime!) >= _minMarkAsReadInterval) {
            _lastMarkAsReadTime = now;
            final repository = NotificationRepository(ref.read(apiClientProvider));
            final response = await repository.markAsReadSingle(notification.id);
            
            if (response.success) {
              // Clear cache to force fresh fetch
              _notificationsCache.clear();
              
              // Refresh all notification providers (for both list and counter)
              ref.refresh(notificationsProvider(
                NotificationsParams(
                  unreadOnly: _unreadOnly,
                  page: _page,
                ),
              ));
              // Also refresh the counter provider (unreadOnly: false, page: 1)
              ref.refresh(notificationsProvider(
                NotificationsParams(
                  unreadOnly: false,
                  page: 1,
                ),
              ));
            }
          }
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
          // Mark as read if not already read
          if (!notification.isRead) {
            // Throttle mark as read calls
            final now = DateTime.now();
            if (_lastMarkAsReadTime == null || 
                now.difference(_lastMarkAsReadTime!) >= _minMarkAsReadInterval) {
              _lastMarkAsReadTime = now;
              final repository = NotificationRepository(ref.read(apiClientProvider));
              final response = await repository.markAsReadSingle(notification.id);
              
              if (response.success) {
                // Clear cache to force fresh fetch
                _notificationsCache.clear();
                
                // Invalidate all notification providers (for both list and counter)
                ref.invalidate(notificationsProvider(
                  NotificationsParams(
                    unreadOnly: _unreadOnly,
                    page: _page,
                  ),
                ));
                // Also invalidate the counter provider (unreadOnly: false, page: 1)
                ref.invalidate(notificationsProvider(
                  NotificationsParams(
                    unreadOnly: false,
                    page: 1,
                  ),
                ));
              }
            }
          }
          
          // Handle notification link if present
          if (notification.data != null && notification.data!['link'] != null) {
            final link = notification.data!['link']?.toString();
            if (link != null && link.isNotEmpty) {
              try {
                final uri = Uri.parse(link);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cannot open link: $link'),
                        backgroundColor: IntraZeroColors.warning,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening link: ${e.toString()}'),
                      backgroundColor: IntraZeroColors.danger,
                    ),
                  );
                }
              }
            }
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
