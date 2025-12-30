import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassmorphismCard(
                child: Column(
                  children: [
                    if (user.profileImage != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(user.profileImage!),
                      )
                    else
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: IntraZeroColors.primaryGradient.colors.first,
                        child: Text(
                          user.firstname[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: IntraZeroColors.textSecondary,
                      ),
                    ),
                    if (user.department != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        user.department!,
                        style: TextStyle(
                          fontSize: 14,
                          color: IntraZeroColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final authNotifier = ref.read(currentUserProvider.notifier);
                        await authNotifier.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IntraZeroColors.danger,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
