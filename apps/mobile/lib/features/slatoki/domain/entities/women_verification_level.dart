/// Per docs/architecture/domain-model.md#4-bounded-context-slatoki's
/// `WomenVerificationLevel` value object and `docs/api/openapi.yaml`'s
/// `SlatokiPlaceSummary.womenVerificationLevel`. The visual distinction
/// this enables (US-02.1.4 — the "Femmes — section confirmée" chip vs. a
/// neutral note) is a separate, not-yet-implemented story; this story
/// (US-02.1.3) only needs the value itself to exist on [SlatokiPlace].
enum WomenVerificationLevel { verifiedConfirmed, generic }
