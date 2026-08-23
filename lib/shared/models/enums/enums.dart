enum UserRole { player, team, admin }

enum VerificationStatus { unverified, pending, verified, rejected, suspended }

enum ReservationStatus {
  pending,
  accepted,
  rejected,
  paymentPending,
  paid,
  confirmed,
  arrived,
  completed,
  cancelled,
  disputed,
  refunded,
}

enum PaymentStatus { pending, succeeded, failed, refunded }

enum PayoutStatus { pending, processing, completed, failed }

enum DisputeStatus { open, underReview, resolved, rejected, refunded }
