import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// Smallest screen side (logical px) from which an iOS device is an iPad.
const _tabletShortestSide = 600.0;

/// Default name this device shows on the host, by platform.
String deviceNameFor(AppLocalizations l, TargetPlatform platform, double shortestSide) =>
    switch (platform) {
      TargetPlatform.iOS =>
        shortestSide >= _tabletShortestSide ? l.defaultDeviceNameIpad : l.defaultDeviceNameIphone,
      TargetPlatform.macOS => l.defaultDeviceNameMac,
      _ => l.defaultDeviceName,
    };

String defaultDeviceName(BuildContext context) =>
    deviceNameFor(context.l10n, defaultTargetPlatform, MediaQuery.sizeOf(context).shortestSide);
