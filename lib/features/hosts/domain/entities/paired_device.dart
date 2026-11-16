/// One device paired with a host, as `falconer-hook devices list` shows it.
/// The push endpoint URL is not kept: the app only needs its stale flag.
library;

import '../../../../shared/domain/display_text.dart';

final class PairedDevice {
  const PairedDevice({
    required this.id,
    required this.name,
    required this.pairedAt,
    required this.endpointStale,
    required this.isThisPhone,
  });

  final String id;
  final String name;
  final DateTime pairedAt;
  final bool endpointStale;

  /// The device id this phone got at pairing ([Host.deviceId]).
  final bool isThisPhone;

  /// Returns null on missing or mistyped fields; never throws.
  static PairedDevice? fromJson(Object? raw, {required String? thisDeviceId}) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final at = raw['paired_at'];
    if (!isWireId(id)) return null;
    if (at is! int || at < 0 || at > 253402300799) return null;
    final label = name is String ? sanitizeText(name, max: 64) : '';
    return PairedDevice(
      id: id as String,
      name: label.isEmpty ? 'Unnamed device' : label,
      pairedAt: DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true),
      endpointStale: raw['endpoint_stale'] == true,
      isThisPhone: thisDeviceId != null && id == thisDeviceId,
    );
  }
}
