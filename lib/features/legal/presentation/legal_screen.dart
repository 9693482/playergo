import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Pantalla legal reutilizable para Términos y Condiciones y Política de
/// Privacidad. El tipo se pasa por parámetro de ruta (`terms` | `privacy`).
class LegalScreen extends StatelessWidget {
  final String type;

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isTerms = type == 'terms';
    final title = isTerms ? 'Términos y Condiciones' : 'Política de Privacidad';
    final lastUpdated = 'Última actualización: 2026';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ResponsiveContainerLegal(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastUpdated,
                style: AppTypography.caption
                    .copyWith(color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ..._buildSections(isTerms),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(bool isTerms) {
    if (isTerms) {
      return [
        _Section(
          '1. Aceptación',
          'Al registrarte en PlayerGO aceptas estos Términos. Si no estás de '
          'acuerdo, no utilices la plataforma.',
        ),
        _Section(
          '2. Uso de la plataforma',
          'PlayerGO conecta equipos con jugadores para la reserva y contratación '
          'de servicios deportivos. Eres responsable de la veracidad de la '
          'información que publicas y de cumplir las normas de juego y convivencia.',
        ),
        _Section(
          '3. Pagos y comisiones',
          'Los pagos se procesan a través de Stripe. PlayerGO retiene una comisión '
          'de plataforma (15%) y el monto restante se transfiere al jugador vía '
          'Stripe Connect. Las disputas se resuelven según la evidencia aportada.',
        ),
        _Section(
          '4. Verificación y KYC',
          'Para reservar y recibir pagos debes verificar tu correo y completar la '
          'verificación de identidad (KYC) subiendo tu documento. Podemos suspender '
          'cuentas con información falsa.',
        ),
        _Section(
          '5. Responsabilidad',
          'PlayerGO actúa como intermediario y no es responsable por daños, lesiones '
          'o conflictos derivados de los encuentros deportivos.',
        ),
      ];
    }
    return [
      _Section(
        '1. Datos que recopilamos',
        'Nombre, correo, teléfono, documento de identidad (KYC), ubicación '
        'aproximada, calificaciones y datos de pago. El documento se usa exclusivamente '
        'para verificación y prevención de fraude.',
      ),
      _Section(
        '2. Base legal (Colombia y GDPR)',
        'Tratamos tus datos según la Ley 1581 de 2012 (Habeas Data) y el Reglamento '
        '(UE) 2016/679 (GDPR). Puedes solicitar acceso, rectificación, portabilidad '
        'o eliminación de tus datos en cualquier momento.',
      ),
      _Section(
        '3. Compartición',
        'Compartimos datos solo con tu contraparte para ejecutar la reserva, con '
        'Stripe para pagos, y con autoridades cuando la ley lo exija.',
      ),
      _Section(
        '4. Conservación y eliminación',
        'Conservamos tus datos mientras tu cuenta esté activa. Puedes eliminar tu '
        'cuenta y todos tus datos personales desde "Mi cuenta y privacidad".',
      ),
      _Section(
        '5. Tus derechos',
        'Tienes derecho al olvido y a la portabilidad. Escríbenos para ejercerlos '
        'y responderemos en los plazos legales.',
      ),
    ];
  }
}

class ResponsiveContainerLegal extends StatelessWidget {
  final Widget child;
  const ResponsiveContainerLegal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.subtitle1
                .copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTypography.body1
                .copyWith(color: AppColors.darkTextSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
