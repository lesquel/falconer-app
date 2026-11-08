import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/uploads/domain/repositories/file_source.dart';
import 'package:openmosh/features/uploads/domain/usecases/upload_file.dart';
import 'package:openmosh/shared/domain/failure.dart';

import '../../support/fakes.dart';

void main() {
  test('uploads under a sanitized random name and returns a quoted path', () async {
    final hosts = FakeHostRepository();
    await hosts.save(testHost());
    final upload = UploadFile(
      HostConnections(hosts: hosts, vault: FakeVault(), connector: FakeConnector(() => FakeConnection((_, _) => ok(null)))),
      prefix: () => 'deadbeef',
    );
    expect(await upload('h1', const PickedFile(path: '/cache/x', name: 'My shot.PNG', size: 10)),
        "'/home/me/.openmosh/uploads/deadbeef-My_shot.png' ");
    await expectLater(upload('h1', const PickedFile(path: '/c', name: 'big', size: 50 * 1024 * 1024 + 1)),
        throwsA(isA<ValidationFailure>()));
  });
}
