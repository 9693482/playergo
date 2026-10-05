import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/admin_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _adminService = AdminService();
  late Map<String, dynamic> _user;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN': return AppColors.error;
      case 'TEAM': return AppColors.warning;
      case 'PLAYER': return AppColors.primary;
      default: return AppColors.darkTextSecondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'ADMIN': return Icons.admin_panel_settings;
      case 'TEAM': return Icons.groups;
      case 'PLAYER': return Icons.sports_soccer;
      default: return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN': return 'Administrador';
      case 'TEAM': return 'Equipo';
      case 'PLAYER': return 'Jugador';
      default: return 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VERIFIED': return AppColors.success;
      case 'PENDING': return AppColors.warning;
      case 'REJECTED': return AppColors.error;
      case 'SUSPENDED': return AppColors.darkTextSecondary;
      default: return AppColors.darkTextSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'VERIFIED': return 'Verificado';
      case 'PENDING': return 'En revisión';
      case 'REJECTED': return 'Baneado';
      case 'SUSPENDED': return 'Suspendido';
      default: return 'Sin verificar';
    }
  }

  Future<void> _changeRole(String newRole) async {
    setState(() => _isUpdating = true);
    try {
      await _adminService.updateUserRole(_user['id'], newRole);
      setState(() {
        _user['role'] = newRole;
        _isUpdating = false;
      });
      if (mounted) {
        AppFeedback.showSuccess(context, 'Rol actualizado a ${_getRoleLabel(newRole)}');
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        AppFeedback.showError(context, 'Error al cambiar rol');
      }
    }
  }

  Future<void> _toggleBan() async {
    final isBanned = _user['verification_status'] == 'REJECTED';
    setState(() => _isUpdating = true);
    try {
      if (isBanned) {
        await _adminService.unbanUser(_user['id']);
        setState(() => _user['verification_status'] = 'VERIFIED');
      } else {
        await _adminService.banUser(_user['id']);
        setState(() => _user['verification_status'] = 'REJECTED');
      }
      setState(() => _isUpdating = false);
      if (mounted) {
        AppFeedback.showSuccess(context, isBanned ? 'Usuario desbaneado' : 'Usuario baneado');
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        AppFeedback.showError(context, 'Error al actualizar usuario');
      }
    }
  }

  Future<void> _toggleActive() async {
    final isActive = _user['is_active'] != false;
    setState(() => _isUpdating = true);
    try {
      if (isActive) {
        await _adminService.deactivateUser(_user['id']);
        setState(() => _user['is_active'] = false);
      } else {
        await _adminService.reactivateUser(_user['id']);
        setState(() => _user['is_active'] = true);
      }
      setState(() => _isUpdating = false);
      if (mounted) {
        AppFeedback.showSuccess(context, isActive ? 'Usuario desactivado' : 'Usuario reactivado');
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        AppFeedback.showError(context, 'Error al actualizar usuario');
      }
    }
  }

  void _showRoleDialog() {
    final roles = ['PLAYER', 'TEAM', 'ADMIN'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text('Cambiar rol', style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) {
            final isSelected = _user['role'] == role;
            return ListTile(
              leading: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
              title: Text(_getRoleLabel(role), style: AppTypography.body1.copyWith(
                color: isSelected ? AppColors.primary : AppColors.darkTextPrimary,
              )),
              trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.primary) : null,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              onTap: () {
                Navigator.pop(ctx);
                _changeRole(role);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _user['role'] ?? 'PLAYER';
    final status = _user['verification_status'] ?? 'UNVERIFIED';
    final isActive = _user['is_active'] != false;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildProfileCard(role, status, isActive),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInfoSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActionsSection(isActive, status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedEntrance(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('⚽', style: AppTypography.h2),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Detalle de usuario',
                    style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
                  ),
                ),
                if (_isUpdating)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.success]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String role, String status, bool isActive) {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 100),
      child: GlassCard(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getRoleColor(role),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (_user['full_name'] ?? 'U')[0].toUpperCase(),
                  style: AppTypography.h1.copyWith(color: AppColors.textOnPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _user['full_name'] ?? 'Sin nombre',
              style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _user['email'] ?? '',
              style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _badge(
                  icon: _getRoleIcon(role),
                  label: _getRoleLabel(role),
                  color: _getRoleColor(role),
                ),
                const SizedBox(width: AppSpacing.sm),
                _badge(
                  icon: isActive ? Icons.check_circle : Icons.block,
                  label: isActive ? 'Activo' : 'Inactivo',
                  color: isActive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                _badge(
                  icon: Icons.shield,
                  label: _getStatusLabel(status),
                  color: _getStatusColor(status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final createdAt = _user['created_at'] != null
        ? DateTime.tryParse(_user['created_at']) : null;

    return AnimatedEntrance(
      delay: const Duration(milliseconds: 200),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
            const SizedBox(height: AppSpacing.md),
            _infoRow(Icons.email, 'Email', _user['email'] ?? '-'),
            _infoRow(Icons.phone, 'Teléfono', _user['phone'] ?? 'No registrado'),
            _infoRow(Icons.calendar_today, 'Registro', createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                : '-'),
            _infoRow(Icons.location_on, 'País', _user['country_id'] ?? 'No especificado'),
            _infoRow(Icons.location_city, 'Región', _user['region_id'] ?? 'No especificada'),
            _infoRow(Icons.map, 'Ciudad', _user['city_id'] ?? 'No especificada'),
            _infoRow(Icons.fingerprint, 'ID', _user['id']?.toString().substring(0, 8) ?? '-', copyable: true),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.darkTextSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: AppTypography.caption.copyWith(
            color: AppColors.darkTextSecondary,
          )),
          Expanded(
            child: Text(value, style: AppTypography.body2.copyWith(
              color: AppColors.darkTextPrimary,
            ), overflow: TextOverflow.ellipsis),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 14, color: AppColors.darkTextSecondary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _user['id'] ?? ''));
                AppFeedback.showSuccess(context, 'ID copiado');
              },
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isActive, String status) {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 300),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acciones', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
            const SizedBox(height: AppSpacing.md),
            _actionButton(
              icon: Icons.admin_panel_settings,
              label: 'Cambiar rol',
              subtitle: 'Actual: ${_getRoleLabel(_user['role'] ?? 'PLAYER')}',
              color: AppColors.info,
              onTap: _showRoleDialog,
            ),
            const SizedBox(height: AppSpacing.sm),
            _actionButton(
              icon: status == 'REJECTED' ? Icons.check_circle : Icons.block,
              label: status == 'REJECTED' ? 'Desbanear usuario' : 'Banear usuario',
              subtitle: status == 'REJECTED' ? 'Restaurar acceso' : 'Restringir acceso',
              color: status == 'REJECTED' ? AppColors.success : AppColors.error,
              onTap: _toggleBan,
            ),
            const SizedBox(height: AppSpacing.sm),
            _actionButton(
              icon: isActive ? Icons.visibility_off : Icons.visibility,
              label: isActive ? 'Desactivar cuenta' : 'Reactivar cuenta',
              subtitle: isActive ? 'Ocultar del sistema' : 'Restaurar en sistema',
              color: isActive ? AppColors.warning : AppColors.success,
              onTap: _toggleActive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isUpdating ? null : onTap,
      borderRadius: AppRadius.medium,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: AppRadius.medium,
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: AppRadius.small,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextPrimary)),
                  Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
