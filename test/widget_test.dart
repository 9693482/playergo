import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/core/theme/app_colors.dart';
import 'package:playergo/core/theme/app_typography.dart';
import 'package:playergo/core/widgets/glass_card.dart';
import 'package:playergo/core/widgets/empty_state.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: const Text('Hello'),
            ),
          ),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('applies custom padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              padding: const EdgeInsets.all(32),
              child: const Text('Padded'),
            ),
          ),
        ),
      );
      expect(find.text('Padded'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('renders illustration and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              illustration: Icons.inbox,
              title: 'No data',
              message: 'Nothing to show',
            ),
          ),
        ),
      );
      expect(find.text('No data'), findsOneWidget);
      expect(find.text('Nothing to show'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });
  });

  group('AppTypography', () {
    test('h2 has correct properties', () {
      final style = AppTypography.h2;
      expect(style.fontFamily, 'Poppins');
      expect(style.fontWeight, FontWeight.bold);
    });

    test('body2 has correct properties', () {
      final style = AppTypography.body2;
      expect(style.fontFamily, 'Poppins');
    });
  });

  group('AppColors', () {
    test('primary color exists', () {
      expect(AppColors.primary, isA<Color>());
    });

    test('dark theme colors exist', () {
      expect(AppColors.darkBackground, isA<Color>());
      expect(AppColors.darkSurface, isA<Color>());
      expect(AppColors.darkSurfaceVariant, isA<Color>());
      expect(AppColors.darkTextPrimary, isA<Color>());
      expect(AppColors.darkTextSecondary, isA<Color>());
    });

    test('semantic colors exist', () {
      expect(AppColors.success, isA<Color>());
      expect(AppColors.error, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.info, isA<Color>());
    });
  });
}
