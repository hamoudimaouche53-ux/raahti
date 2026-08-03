/// `User.diabetic_verified_status` — ERD §3.6, backs FR-USR-03/FR-EMG-03.
///
/// Modeled now because [AppUser] genuinely carries this field and SCR-020's
/// account summary card needs it (the "✓ Diabétique vérifié" badge) — but
/// the *workflow* that changes it ([verified]/[rejected] from a submitted
/// [VerificationDocument]) is US-05.3 scope, deliberately deferred to V1.1
/// per the Release Alignment table (see `docs/phase-3-implementation-log.md`
/// Feature 19's Blockers/Assumptions). No `VerificationDocument` entity or
/// repository port exists yet — there's nothing in this codebase that
/// would use one until US-05.3 is actually implemented.
enum DiabeticVerificationStatus {
  none,
  pending,
  verified,
  rejected;

  static DiabeticVerificationStatus fromWireValue(String value) {
    return DiabeticVerificationStatus.values.firstWhere(
      (v) => v.name == value,
      orElse: () => DiabeticVerificationStatus.none,
    );
  }
}
