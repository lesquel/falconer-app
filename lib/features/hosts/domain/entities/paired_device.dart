/// One device paired with a host, as `openmosh-hook devices list` shows it.
/// The push endpoint URL is not kept: the app only needs its stale flag.
library;

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

  static final _control = RegExp(r'[\x00-\x1f\x7f]');

  /// Returns null on missing or mistyped fields; never throws.
  static PairedDevice? fromJson(Object? raw, {required String? thisDeviceId}) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final at = raw['paired_at'];
    if (id is! String || id.isEmpty || id.length > 128 || _control.hasMatch(id)) return null;
    if (at is! int || at < 0 || at > 253402300799) return null;
    final label = name is String ? name.replaceAll(_control, '') : '';
    return PairedDevice(
      id: id,
      name: label.isEmpty ? 'Unnamed device' : (label.length > 64 ? label.substring(0, 64) : label),
      pairedAt: DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true),
      endpointStale: raw['endpoint_stale'] == true,
      isThisPhone: thisDeviceId != null && id == thisDeviceId,
    );
  }
}
