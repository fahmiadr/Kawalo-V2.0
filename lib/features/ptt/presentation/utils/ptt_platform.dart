import 'package:flutter/foundation.dart';

/// The native PTT engine (`kawalo/ptt_control`) is implemented on Android only.
bool get isPttSupportedPlatform =>
    defaultTargetPlatform == TargetPlatform.android;
