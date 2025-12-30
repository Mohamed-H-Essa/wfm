import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../app/themes/typography.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    // Give time for the user to be loaded from token
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      // Try to refresh user if null
      final user = ref.read(currentUserProvider);
      if (user == null) {
        await ref.read(currentUserProvider.notifier).refreshUser();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _isLoading = true);
              await ref.read(currentUserProvider.notifier).refreshUser();
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Session expired'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header Card
                      GlassmorphismCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Profile Image
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: IntraZeroColors.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: IntraZeroColors.primaryGradient.colors.first.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: user.profileImage != null
                                  ? CircleAvatar(
                                      radius: 60,
                                      backgroundImage: NetworkImage(user.profileImage!),
                                    )
                                  : CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        user.firstname.isNotEmpty ? user.firstname[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: IntraZeroColors.primaryGradient.colors.first,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            // Name
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: IntraZeroColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Email
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.email, size: 16, color: IntraZeroColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: IntraZeroColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Information Cards
                      if (user.department != null || user.position != null) ...[
                        GlassmorphismCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.business, color: IntraZeroColors.primaryGradient.colors.first),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Work Information',
                                    style: IntraZeroTypography.label,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (user.department != null) ...[
                                _buildInfoRow(Icons.business_center, 'Department', user.department!),
                                if (user.position != null) const SizedBox(height: 12),
                              ],
                              if (user.position != null)
                                _buildInfoRow(Icons.work, 'Position', user.position!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Account Information
                      GlassmorphismCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_circle, color: IntraZeroColors.primaryGradient.colors.first),
                                const SizedBox(width: 12),
                                Text(
                                  'Account',
                                  style: IntraZeroTypography.label,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.person, 'Role', user.role.toUpperCase()),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.tag, 'User ID', '#${user.id}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Actions
                      GlassmorphismCard(
                        child: Column(
                          children: [
                            GradientButton(
                              text: 'Settings',
                              gradient: IntraZeroColors.primaryGradient,
                              icon: Icons.settings,
                              isFullWidth: true,
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.settings);
                              },
                            ),
                            const SizedBox(height: 12),
                            GradientButton(
                              text: 'Logout',
                              gradient: LinearGradient(
                                colors: [IntraZeroColors.danger, IntraZeroColors.danger.withOpacity(0.8)],
                              ),
                              icon: Icons.logout,
                              isFullWidth: true,
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: IntraZeroColors.danger,
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true && mounted) {
                                  final authNotifier = ref.read(currentUserProvider.notifier);
                                  await authNotifier.logout();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: IntraZeroColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: IntraZeroColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: IntraZeroColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
