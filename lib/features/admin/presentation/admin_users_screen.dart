import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getAllUsers(role: _filterRole);
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _toggleBan(Map<String, dynamic> user) async {
    final isBanned = user['verification_status'] == 'REJECTED';
    if (isBanned) {
      await _adminService.unbanUser(user['id']);
    } else {
      await _adminService.banUser(user['id']);
    }
    await _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBanned ? 'Usuario desbaneado' : 'Usuario baneado'),
          backgroundColor: isBanned ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Gestionar Usuarios',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list, color: AppColors.darkTextPrimary),
            onSelected: (value) {
              setState(() => _filterRole = value);
              _loadUsers();
            },
            color: AppColors.darkSurface,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos'),
              ),
              const PopupMenuItem(value: 'PLAYER', child: Text('Jugadores')),
              const PopupMenuItem(value: 'TEAM', child: Text('Equipos')),
              const PopupMenuItem(value: 'ADMIN', child: Text('Admins')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _users.isEmpty
              ? Center(
                  child: Text(
                    'No hay usuarios',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isBanned = user['verification_status'] == 'REJECTED';
                      final role = user['role'] ?? 'UNKNOWN';

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: AppRadius.medium,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isBanned ? AppColors.error : AppColors.primary,
                            child: Text(
                              (user['full_name'] ?? 'U')[0].toUpperCase(),
                              style: AppTypography.subtitle2.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                          title: Text(
                            user['full_name'] ?? 'Sin nombre',
                            style: AppTypography.subtitle2.copyWith(
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${user['email'] ?? '-'} • $role',
                            style: AppTypography.caption.copyWith(
                              color: isBanned
                                  ? AppColors.error
                                  : AppColors.darkTextSecondary,
                            ),
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppColors.darkTextSecondary,
                            ),
                            color: AppColors.darkSurface,
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(
                                    isBanned ? Icons.check_circle : Icons.block,
                                    color: isBanned
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  title: Text(
                                    isBanned ? 'Desbanear' : 'Banear',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onTap: () => _toggleBan(user),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
