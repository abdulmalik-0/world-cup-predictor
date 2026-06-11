/// All match times in the app are shown and compared in Saudi Arabia time
/// (Arabia Standard Time, UTC+3, no daylight saving) regardless of the device's
/// own timezone — so an employee abroad still sees the correct local kickoff.
///
/// [Match.kickoffAt] is stored as Saudi wall-clock (the real instant shifted by
/// +3h and tagged UTC). Any comparison against "now" must therefore use
/// [nowInSaudi] — never `DateTime.now()` — so both sides share the same shift
/// and the difference stays exact.
const Duration saudiOffset = Duration(hours: 3);

/// The current moment expressed as Saudi wall-clock, for comparing against
/// [Match.kickoffAt] (kickoff countdowns, prediction-lock checks).
DateTime nowInSaudi() => DateTime.now().toUtc().add(saudiOffset);
