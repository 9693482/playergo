import 'package:flutter/material.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/state_view.dart';
import '../data/admin_service.dart';

class AdminPlatformSettingsScreen extends StatefulWidget {
  const AdminPlatformSettingsScreen({super.key});

  @override
  State<AdminPlatformSettingsScreen> createState() => _AdminPlatformSettingsScreenState();
}

class _AdminPlatformSettingsScreenState extends State<AdminPlatformSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  late TabController _tabController;

  List<Map<String, dynamic>> _settings = [];
  List<Map<String, dynamic>> _policies = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  Object? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _adminService.getPlatformSettings(),
        _adminService.getCancellationPolicies(),
        _adminService.getPlatformSummary(),
      ]);
      setState(() {
        _settings = results[0] as List<Map<String, dynamic>>;
        _policies = results[1] as List<Map<String, dynamic>>;
        _summary = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  String _getSettingValue(String key) {
    try {
      return _settings.firstWhere((s) => s['key'] == key)['value'].toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    setState(() => _isSaving = true);
    try {
      await _adminService.updatePlatformSetting(key, value);
      await _loadData();
      if (mounted) {
        AppFeedback.showSuccess(context, 'Configuración actualizada');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error al guardar');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _editSetting(String key, String title, {bool isNumeric = true}) async {
    final controller = TextEditingController(text: _getSettingValue(key));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(title, style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Guardar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _updateSetting(key, result);
    }
  }

  Future<void> _editPolicy(Map<String, dynamic> policy) async {
    final hoursController = TextEditingController(text: policy['hours_before'].toString());
    final refundController = TextEditingController(text: policy['refund_percentage'].toString());
    final descController = TextEditingController(text: policy['description'] ?? '');
    bool isActive = policy['is_active'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text(
            'Editar política',
            style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Horas antes',
                  labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                  filled: true,
                  fillColor: AppColors.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: refundController,
                keyboardType: TextInputType.number,
                style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Reembolso (%)',
                  labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                  filled: true,
                  fillColor: AppColors.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                  filled: true,
                  fillColor: AppColors.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: Text('Activa', style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary)),
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: TextStyle(color: AppColors.darkTextSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Guardar', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => _isSaving = true);
      try {
        await _adminService.updateCancellationPolicy(
          policyId: policy['id'],
          hoursBefore: int.tryParse(hoursController.text) ?? policy['hours_before'],
          refundPercentage: double.tryParse(refundController.text) ?? policy['refund_percentage'],
          description: descController.text,
          isActive: isActive,
        );
        await _loadData();
        if (mounted) {
          AppFeedback.showSuccess(context, 'Política actualizada');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Error al guardar');
        }
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isLoading && _error == null) _buildTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? StateView(
                          isLoading: false,
                          error: _error,
                          onRetry: _loadData,
                          child: const SizedBox(),
                        )
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              Text('⚙️', style: AppTypography.h2),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Configuración de plataforma',
                  style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
                ),
              ),
              if (_isSaving)
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
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Comisiones'),
          Tab(text: 'Cancelaciones'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGeneralTab(),
        _buildFeesTab(),
        _buildCancellationsTab(),
      ],
    );
  }

  Widget _buildGeneralTab() {
    final settingsMap = _summary['settings'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Configuración general', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
          const SizedBox(height: AppSpacing.md),
          _settingTile(
            icon: Icons.attach_money,
            title: 'Moneda',
            value: settingsMap['currency'] ?? _getSettingValue('currency'),
            onTap: () => _editSetting('currency', 'Moneda', isNumeric: false),
          ),
          _settingTile(
            icon: Icons.trending_down,
            title: 'Precio mínimo',
            value: '\$${settingsMap['minimum_service_price'] ?? _getSettingValue('minimum_service_price')}',
            onTap: () => _editSetting('minimum_service_price', 'Precio mínimo del servicio'),
          ),
          _settingTile(
            icon: Icons.trending_up,
            title: 'Precio máximo',
            value: '\$${settingsMap['maximum_service_price'] ?? _getSettingValue('maximum_service_price')}',
            onTap: () => _editSetting('maximum_service_price', 'Precio máximo del servicio'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesTab() {
    final totalRevenue = _summary['totalRevenue'] as double? ?? 0;
    final feeCount = _summary['feeCount'] as int? ?? 0;
    final settingsMap = _summary['settings'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedEntrance(
            child: GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ingresos totales', style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary)),
                            Text(
                              '\$${totalRevenue.toStringAsFixed(0)}',
                              style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _statChip(label: 'Transacciones', value: '$feeCount', color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      _statChip(
                        label: 'Comisión',
                        value: '${settingsMap['platform_fee_percentage'] ?? _getSettingValue('platform_fee_percentage')}%',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Configuración de comisiones', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
          const SizedBox(height: AppSpacing.md),
          _settingTile(
            icon: Icons.percent,
            title: 'Porcentaje de comisión',
            value: '${settingsMap['platform_fee_percentage'] ?? _getSettingValue('platform_fee_percentage')}%',
            onTap: () => _editSetting('platform_fee_percentage', 'Porcentaje de comisión (%)'),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Políticas de cancelación', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Define los porcentajes de reembolso según el tiempo de cancelación.',
            style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...(_policies.asMap().entries.map((entry) {
            final policy = entry.value;
            final refund = policy['refund_percentage'] ?? 0;
            final isActive = policy['is_active'] ?? true;

            return AnimatedEntrance(
              delay: Duration(milliseconds: 80 * entry.key),
              child: GestureDetector(
                onTap: () => _editPolicy(policy),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: isActive ? AppColors.primary.withAlpha(60) : AppColors.darkSurfaceVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getRefundColor(refund).withAlpha(25),
                          borderRadius: AppRadius.small,
                        ),
                        child: Center(
                          child: Text(
                            '${refund.toInt()}%',
                            style: AppTypography.subtitle2.copyWith(
                              color: _getRefundColor(refund),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              policy['name'] ?? '',
                              style: AppTypography.subtitle2.copyWith(color: AppColors.darkTextPrimary),
                            ),
                            Text(
                              policy['description'] ?? '',
                              style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success.withAlpha(25) : AppColors.darkTextSecondary.withAlpha(25),
                          borderRadius: AppRadius.full,
                        ),
                        child: Text(
                          isActive ? 'Activa' : 'Inactiva',
                          style: AppTypography.caption.copyWith(
                            color: isActive ? AppColors.success : AppColors.darkTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalRevenue = _summary['totalRevenue'] as double? ?? 0;
    final feeCount = _summary['feeCount'] as int? ?? 0;

    return AnimatedEntrance(
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen de plataforma', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
                  Text(
                    '$feeCount transacciones • \$${totalRevenue.toStringAsFixed(0)} ingresos',
                    style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return AnimatedEntrance(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: AppRadius.medium,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title, style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary)),
              ),
              Text(
                value,
                style: AppTypography.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.edit, size: 16, color: AppColors.darkTextSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: AppRadius.full,
        ),
        child: Column(
          children: [
            Text(value, style: AppTypography.subtitle2.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Color _getRefundColor(double refund) {
    if (refund >= 80) return AppColors.success;
    if (refund >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
