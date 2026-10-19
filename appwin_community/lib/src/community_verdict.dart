import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';

/// Dart-side copy of the native `lastResult`, shared by the facade (which
/// writes it) and `AppwinCommunityView` (which rebuilds on it). Not exported.
final communityVerdict = ValueNotifier<AppwinInitResult?>(null);
