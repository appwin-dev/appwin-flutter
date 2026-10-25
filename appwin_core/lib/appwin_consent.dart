/// What a user answered for a consent purpose.
///
/// `granted` is the default posture: a studio without a consent banner has
/// nothing to do. `unknown` keeps the events on the device until the user
/// answers; `denied` drops them.
enum AppwinConsentState { granted, denied, unknown }

/// What an event stream may be used for. Each purpose has its own
/// [AppwinConsentState].
///
/// `advertising` only sorts the events sent by the stream: the IDFA and the
/// ad networks stay behind the Attribution opt-in.
enum AppwinConsentPurpose { analytics, marketing, advertising }
