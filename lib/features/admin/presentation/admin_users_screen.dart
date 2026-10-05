import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/state_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/admin_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String? _filterRole;

  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadUsers(reset: true);
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _users = [];
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final offset = reset ? 0 : _users.length;
      final users = await _adminService.getAllUsers(
        role: _filterRole,
        limit: _pageSize,
        offset: offset,
      );
      setState(() {
        if (reset) {
          _users = users;
        } else {
          _users.addAll(users);
        }
        _hasMore = users.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      AppLogger.error('Error cargando usuarios (admin)', e);
      setState(() {
        _error = e;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(animate),
            Expanded(
              child: ResponsiveContainer(
                maxWidth: 960,
                child: StateView(
                  isLoading: _isLoading,
                  error: _error,
                  onRetry: () => _loadUsers(reset: true),
                  child: _users.isEmpty
                      ? EmptyState(
                          illustration: Icons.people_outline,
                          title: 'No hay usuarios',
                          message:
                              'Cuando los jugadores y equipos se registren aparecerán aquí.',
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadUsers(reset: true),
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _users.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _users.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg),
                                  child: Center(
                                    child: _isLoadingMore
                                        ? const CircularProgressIndicator(
                                            color: AppColors.primary,
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () => _loadUsers(),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Cargar mas'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.darkSurface,
                                              foregroundColor:
                                                  AppColors.darkTextPrimary,
                                            ),
                                          ),
                                  ),
                                );
                              }

                              final user = _users[index];
                              final isBanned =
                                  user['verification_status'] == 'REJECTED';
                              final role = user['role'] ?? 'UNKNOWN';

                              return AnimatedEntrance(
                                delay: Duration(milliseconds: 60 * index),
                                animate: animate,
                                child: GlassCard(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isBanned
                                            ? AppColors.error
                                            : AppColors.primary,
                                        borderRadius: AppRadius.medium,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (user['full_name'] ?? 'U')[0]
                                              .toUpperCase(),
                                          style:
                                              AppTypography.subtitle2.copyWith(
                                            color: AppColors.textOnPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['full_name'] ?? 'Sin nombre',
                                      style:
                                          AppTypography.subtitle2.copyWith(
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
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.darkTextSecondary,
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminUserDetailScreen(user: user),
                                        ),
                                      );
                                      _loadUsers(reset: true);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool animate) {
    return AnimatedEntrance(
      animate: animate,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.darkTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  '⚽',
                  style: AppTypography.h2,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Gestionar Usuarios',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list,
                      color: AppColors.darkTextPrimary),
                  onSelected: (value) {
                    setState(() => _filterRole = value);
                    _loadUsers(reset: true);
                  },
                  color: AppColors.darkSurface,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Todos')),
                    const PopupMenuItem(
                        value: 'PLAYER', child: Text('Jugadores')),
                    const PopupMenuItem(
                        value: 'TEAM', child: Text('Equipos')),
                    const PopupMenuItem(
                        value: 'ADMIN', child: Text('Admins')),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.success,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
