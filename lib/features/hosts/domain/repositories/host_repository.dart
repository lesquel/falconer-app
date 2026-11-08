import '../entities/host.dart';

abstract interface class HostRepository {
  Stream<List<Host>> watchAll();
  Future<List<Host>> all();
  Future<Host?> byId(String id);
  Future<Host?> byDeviceId(String deviceId);
  Future<void> save(Host host);
  Future<void> delete(String id);
}
