import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/shared/models/enums/enums.dart';

void main() {
  group('UserRole', () {
    test('has all expected values', () {
      expect(UserRole.values.length, 3);
      expect(UserRole.player.name, 'player');
      expect(UserRole.team.name, 'team');
      expect(UserRole.admin.name, 'admin');
    });
  });

  group('VerificationStatus', () {
    test('has all expected values', () {
      expect(VerificationStatus.values.length, 5);
      expect(VerificationStatus.unverified.name, 'unverified');
      expect(VerificationStatus.pending.name, 'pending');
      expect(VerificationStatus.verified.name, 'verified');
      expect(VerificationStatus.rejected.name, 'rejected');
      expect(VerificationStatus.suspended.name, 'suspended');
    });
  });

  group('ReservationStatus', () {
    test('has all expected values', () {
      expect(ReservationStatus.values.length, 11);
      expect(ReservationStatus.pending.name, 'pending');
      expect(ReservationStatus.accepted.name, 'accepted');
      expect(ReservationStatus.rejected.name, 'rejected');
      expect(ReservationStatus.paymentPending.name, 'paymentPending');
      expect(ReservationStatus.paid.name, 'paid');
      expect(ReservationStatus.confirmed.name, 'confirmed');
      expect(ReservationStatus.arrived.name, 'arrived');
      expect(ReservationStatus.completed.name, 'completed');
      expect(ReservationStatus.cancelled.name, 'cancelled');
      expect(ReservationStatus.disputed.name, 'disputed');
      expect(ReservationStatus.refunded.name, 'refunded');
    });
  });

  group('PaymentStatus', () {
    test('has all expected values', () {
      expect(PaymentStatus.values.length, 4);
      expect(PaymentStatus.pending.name, 'pending');
      expect(PaymentStatus.succeeded.name, 'succeeded');
      expect(PaymentStatus.failed.name, 'failed');
      expect(PaymentStatus.refunded.name, 'refunded');
    });
  });

  group('DisputeStatus', () {
    test('has all expected values', () {
      expect(DisputeStatus.values.length, 5);
      expect(DisputeStatus.open.name, 'open');
      expect(DisputeStatus.underReview.name, 'underReview');
      expect(DisputeStatus.resolved.name, 'resolved');
      expect(DisputeStatus.rejected.name, 'rejected');
      expect(DisputeStatus.refunded.name, 'refunded');
    });
  });

  group('PayoutStatus', () {
    test('has all expected values', () {
      expect(PayoutStatus.values.length, 4);
      expect(PayoutStatus.pending.name, 'pending');
      expect(PayoutStatus.processing.name, 'processing');
      expect(PayoutStatus.completed.name, 'completed');
      expect(PayoutStatus.failed.name, 'failed');
    });
  });
}
