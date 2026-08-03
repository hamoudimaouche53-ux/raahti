/// FR-SLK-03 — the 3 filter modes, per
/// docs/architecture/domain-model.md#4-bounded-context-slatoki's
/// `PrayerFacilityFilter` value object. Mapped to an M3 Primary `TabBar`
/// (docs/design/component-library.md §5: "Tabs (Primary)"), which — unlike
/// the Map's [PlaceCategory] filter chips — always has exactly one
/// selection; there is no "all" state.
enum PrayerFacilityFilter { prayerOnly, wuduOnly, prayerAndWudu }
