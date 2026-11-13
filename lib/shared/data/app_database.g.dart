// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HostRowsTable extends HostRows with TableInfo<$HostRowsTable, HostRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HostRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<String> keyId = GeneratedColumn<String>(
    'key_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hookPathMeta = const VerificationMeta('hookPath');
  @override
  late final GeneratedColumn<String> hookPath = GeneratedColumn<String>(
    'hook_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hostPushKeyMeta = const VerificationMeta('hostPushKey');
  @override
  late final GeneratedColumn<String> hostPushKey = GeneratedColumn<String>(
    'host_push_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pairedViaMeta = const VerificationMeta('pairedVia');
  @override
  late final GeneratedColumn<String> pairedVia = GeneratedColumn<String>(
    'paired_via',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointSentMeta = const VerificationMeta('endpointSent');
  @override
  late final GeneratedColumn<String> endpointSent = GeneratedColumn<String>(
    'endpoint_sent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttachMeta = const VerificationMeta('lastAttach');
  @override
  late final GeneratedColumn<String> lastAttach = GeneratedColumn<String>(
    'last_attach',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    alias,
    address,
    port,
    username,
    keyId,
    fingerprint,
    hookPath,
    deviceId,
    hostPushKey,
    pairedVia,
    endpointSent,
    lastAttach,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hosts';
  @override
  VerificationContext validateIntegrity(Insertable<HostRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(_aliasMeta, alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta));
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta, address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('port')) {
      context.handle(_portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('key_id')) {
      context.handle(_keyIdMeta, keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta));
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(data['fingerprint']!, _fingerprintMeta),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('hook_path')) {
      context.handle(
        _hookPathMeta,
        hookPath.isAcceptableOrUnknown(data['hook_path']!, _hookPathMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('host_push_key')) {
      context.handle(
        _hostPushKeyMeta,
        hostPushKey.isAcceptableOrUnknown(data['host_push_key']!, _hostPushKeyMeta),
      );
    }
    if (data.containsKey('paired_via')) {
      context.handle(
        _pairedViaMeta,
        pairedVia.isAcceptableOrUnknown(data['paired_via']!, _pairedViaMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedViaMeta);
    }
    if (data.containsKey('endpoint_sent')) {
      context.handle(
        _endpointSentMeta,
        endpointSent.isAcceptableOrUnknown(data['endpoint_sent']!, _endpointSentMeta),
      );
    }
    if (data.containsKey('last_attach')) {
      context.handle(
        _lastAttachMeta,
        lastAttach.isAcceptableOrUnknown(data['last_attach']!, _lastAttachMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HostRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HostRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      port: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}port'])!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_id'],
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      hookPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hook_path'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      hostPushKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_push_key'],
      ),
      pairedVia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paired_via'],
      )!,
      endpointSent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint_sent'],
      ),
      lastAttach: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_attach'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HostRowsTable createAlias(String alias) {
    return $HostRowsTable(attachedDatabase, alias);
  }
}

class HostRow extends DataClass implements Insertable<HostRow> {
  final String id;
  final String alias;
  final String address;
  final int port;
  final String username;
  final String? keyId;
  final String fingerprint;
  final String? hookPath;
  final String? deviceId;
  final String? hostPushKey;
  final String pairedVia;
  final String? endpointSent;
  final String? lastAttach;
  final int createdAt;
  const HostRow({
    required this.id,
    required this.alias,
    required this.address,
    required this.port,
    required this.username,
    this.keyId,
    required this.fingerprint,
    this.hookPath,
    this.deviceId,
    this.hostPushKey,
    required this.pairedVia,
    this.endpointSent,
    this.lastAttach,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alias'] = Variable<String>(alias);
    map['address'] = Variable<String>(address);
    map['port'] = Variable<int>(port);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || keyId != null) {
      map['key_id'] = Variable<String>(keyId);
    }
    map['fingerprint'] = Variable<String>(fingerprint);
    if (!nullToAbsent || hookPath != null) {
      map['hook_path'] = Variable<String>(hookPath);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || hostPushKey != null) {
      map['host_push_key'] = Variable<String>(hostPushKey);
    }
    map['paired_via'] = Variable<String>(pairedVia);
    if (!nullToAbsent || endpointSent != null) {
      map['endpoint_sent'] = Variable<String>(endpointSent);
    }
    if (!nullToAbsent || lastAttach != null) {
      map['last_attach'] = Variable<String>(lastAttach);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  HostRowsCompanion toCompanion(bool nullToAbsent) {
    return HostRowsCompanion(
      id: Value(id),
      alias: Value(alias),
      address: Value(address),
      port: Value(port),
      username: Value(username),
      keyId: keyId == null && nullToAbsent ? const Value.absent() : Value(keyId),
      fingerprint: Value(fingerprint),
      hookPath: hookPath == null && nullToAbsent ? const Value.absent() : Value(hookPath),
      deviceId: deviceId == null && nullToAbsent ? const Value.absent() : Value(deviceId),
      hostPushKey: hostPushKey == null && nullToAbsent ? const Value.absent() : Value(hostPushKey),
      pairedVia: Value(pairedVia),
      endpointSent: endpointSent == null && nullToAbsent
          ? const Value.absent()
          : Value(endpointSent),
      lastAttach: lastAttach == null && nullToAbsent ? const Value.absent() : Value(lastAttach),
      createdAt: Value(createdAt),
    );
  }

  factory HostRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HostRow(
      id: serializer.fromJson<String>(json['id']),
      alias: serializer.fromJson<String>(json['alias']),
      address: serializer.fromJson<String>(json['address']),
      port: serializer.fromJson<int>(json['port']),
      username: serializer.fromJson<String>(json['username']),
      keyId: serializer.fromJson<String?>(json['keyId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      hookPath: serializer.fromJson<String?>(json['hookPath']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      hostPushKey: serializer.fromJson<String?>(json['hostPushKey']),
      pairedVia: serializer.fromJson<String>(json['pairedVia']),
      endpointSent: serializer.fromJson<String?>(json['endpointSent']),
      lastAttach: serializer.fromJson<String?>(json['lastAttach']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'alias': serializer.toJson<String>(alias),
      'address': serializer.toJson<String>(address),
      'port': serializer.toJson<int>(port),
      'username': serializer.toJson<String>(username),
      'keyId': serializer.toJson<String?>(keyId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'hookPath': serializer.toJson<String?>(hookPath),
      'deviceId': serializer.toJson<String?>(deviceId),
      'hostPushKey': serializer.toJson<String?>(hostPushKey),
      'pairedVia': serializer.toJson<String>(pairedVia),
      'endpointSent': serializer.toJson<String?>(endpointSent),
      'lastAttach': serializer.toJson<String?>(lastAttach),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  HostRow copyWith({
    String? id,
    String? alias,
    String? address,
    int? port,
    String? username,
    Value<String?> keyId = const Value.absent(),
    String? fingerprint,
    Value<String?> hookPath = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> hostPushKey = const Value.absent(),
    String? pairedVia,
    Value<String?> endpointSent = const Value.absent(),
    Value<String?> lastAttach = const Value.absent(),
    int? createdAt,
  }) => HostRow(
    id: id ?? this.id,
    alias: alias ?? this.alias,
    address: address ?? this.address,
    port: port ?? this.port,
    username: username ?? this.username,
    keyId: keyId.present ? keyId.value : this.keyId,
    fingerprint: fingerprint ?? this.fingerprint,
    hookPath: hookPath.present ? hookPath.value : this.hookPath,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    hostPushKey: hostPushKey.present ? hostPushKey.value : this.hostPushKey,
    pairedVia: pairedVia ?? this.pairedVia,
    endpointSent: endpointSent.present ? endpointSent.value : this.endpointSent,
    lastAttach: lastAttach.present ? lastAttach.value : this.lastAttach,
    createdAt: createdAt ?? this.createdAt,
  );
  HostRow copyWithCompanion(HostRowsCompanion data) {
    return HostRow(
      id: data.id.present ? data.id.value : this.id,
      alias: data.alias.present ? data.alias.value : this.alias,
      address: data.address.present ? data.address.value : this.address,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      fingerprint: data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      hookPath: data.hookPath.present ? data.hookPath.value : this.hookPath,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      hostPushKey: data.hostPushKey.present ? data.hostPushKey.value : this.hostPushKey,
      pairedVia: data.pairedVia.present ? data.pairedVia.value : this.pairedVia,
      endpointSent: data.endpointSent.present ? data.endpointSent.value : this.endpointSent,
      lastAttach: data.lastAttach.present ? data.lastAttach.value : this.lastAttach,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HostRow(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('address: $address, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('keyId: $keyId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('hookPath: $hookPath, ')
          ..write('deviceId: $deviceId, ')
          ..write('hostPushKey: $hostPushKey, ')
          ..write('pairedVia: $pairedVia, ')
          ..write('endpointSent: $endpointSent, ')
          ..write('lastAttach: $lastAttach, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    alias,
    address,
    port,
    username,
    keyId,
    fingerprint,
    hookPath,
    deviceId,
    hostPushKey,
    pairedVia,
    endpointSent,
    lastAttach,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HostRow &&
          other.id == this.id &&
          other.alias == this.alias &&
          other.address == this.address &&
          other.port == this.port &&
          other.username == this.username &&
          other.keyId == this.keyId &&
          other.fingerprint == this.fingerprint &&
          other.hookPath == this.hookPath &&
          other.deviceId == this.deviceId &&
          other.hostPushKey == this.hostPushKey &&
          other.pairedVia == this.pairedVia &&
          other.endpointSent == this.endpointSent &&
          other.lastAttach == this.lastAttach &&
          other.createdAt == this.createdAt);
}

class HostRowsCompanion extends UpdateCompanion<HostRow> {
  final Value<String> id;
  final Value<String> alias;
  final Value<String> address;
  final Value<int> port;
  final Value<String> username;
  final Value<String?> keyId;
  final Value<String> fingerprint;
  final Value<String?> hookPath;
  final Value<String?> deviceId;
  final Value<String?> hostPushKey;
  final Value<String> pairedVia;
  final Value<String?> endpointSent;
  final Value<String?> lastAttach;
  final Value<int> createdAt;
  final Value<int> rowid;
  const HostRowsCompanion({
    this.id = const Value.absent(),
    this.alias = const Value.absent(),
    this.address = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.keyId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.hookPath = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.hostPushKey = const Value.absent(),
    this.pairedVia = const Value.absent(),
    this.endpointSent = const Value.absent(),
    this.lastAttach = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HostRowsCompanion.insert({
    required String id,
    required String alias,
    required String address,
    required int port,
    required String username,
    this.keyId = const Value.absent(),
    required String fingerprint,
    this.hookPath = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.hostPushKey = const Value.absent(),
    required String pairedVia,
    this.endpointSent = const Value.absent(),
    this.lastAttach = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       alias = Value(alias),
       address = Value(address),
       port = Value(port),
       username = Value(username),
       fingerprint = Value(fingerprint),
       pairedVia = Value(pairedVia),
       createdAt = Value(createdAt);
  static Insertable<HostRow> custom({
    Expression<String>? id,
    Expression<String>? alias,
    Expression<String>? address,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? keyId,
    Expression<String>? fingerprint,
    Expression<String>? hookPath,
    Expression<String>? deviceId,
    Expression<String>? hostPushKey,
    Expression<String>? pairedVia,
    Expression<String>? endpointSent,
    Expression<String>? lastAttach,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alias != null) 'alias': alias,
      if (address != null) 'address': address,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (keyId != null) 'key_id': keyId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (hookPath != null) 'hook_path': hookPath,
      if (deviceId != null) 'device_id': deviceId,
      if (hostPushKey != null) 'host_push_key': hostPushKey,
      if (pairedVia != null) 'paired_via': pairedVia,
      if (endpointSent != null) 'endpoint_sent': endpointSent,
      if (lastAttach != null) 'last_attach': lastAttach,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HostRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? alias,
    Value<String>? address,
    Value<int>? port,
    Value<String>? username,
    Value<String?>? keyId,
    Value<String>? fingerprint,
    Value<String?>? hookPath,
    Value<String?>? deviceId,
    Value<String?>? hostPushKey,
    Value<String>? pairedVia,
    Value<String?>? endpointSent,
    Value<String?>? lastAttach,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return HostRowsCompanion(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      address: address ?? this.address,
      port: port ?? this.port,
      username: username ?? this.username,
      keyId: keyId ?? this.keyId,
      fingerprint: fingerprint ?? this.fingerprint,
      hookPath: hookPath ?? this.hookPath,
      deviceId: deviceId ?? this.deviceId,
      hostPushKey: hostPushKey ?? this.hostPushKey,
      pairedVia: pairedVia ?? this.pairedVia,
      endpointSent: endpointSent ?? this.endpointSent,
      lastAttach: lastAttach ?? this.lastAttach,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<String>(keyId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (hookPath.present) {
      map['hook_path'] = Variable<String>(hookPath.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (hostPushKey.present) {
      map['host_push_key'] = Variable<String>(hostPushKey.value);
    }
    if (pairedVia.present) {
      map['paired_via'] = Variable<String>(pairedVia.value);
    }
    if (endpointSent.present) {
      map['endpoint_sent'] = Variable<String>(endpointSent.value);
    }
    if (lastAttach.present) {
      map['last_attach'] = Variable<String>(lastAttach.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HostRowsCompanion(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('address: $address, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('keyId: $keyId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('hookPath: $hookPath, ')
          ..write('deviceId: $deviceId, ')
          ..write('hostPushKey: $hostPushKey, ')
          ..write('pairedVia: $pairedVia, ')
          ..write('endpointSent: $endpointSent, ')
          ..write('lastAttach: $lastAttach, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyRowsTable extends KeyRows with TableInfo<$KeyRowsTable, KeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedMeta = const VerificationMeta('imported');
  @override
  late final GeneratedColumn<bool> imported = GeneratedColumn<bool>(
    'imported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("imported" IN (0, 1))'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, publicKey, fingerprint, imported, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ssh_keys';
  @override
  VerificationContext validateIntegrity(Insertable<KeyRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(_labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(data['fingerprint']!, _fingerprintMeta),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('imported')) {
      context.handle(
        _importedMeta,
        imported.isAcceptableOrUnknown(data['imported']!, _importedMeta),
      );
    } else if (isInserting) {
      context.missing(_importedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      imported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}imported'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $KeyRowsTable createAlias(String alias) {
    return $KeyRowsTable(attachedDatabase, alias);
  }
}

class KeyRow extends DataClass implements Insertable<KeyRow> {
  final String id;
  final String label;
  final String publicKey;
  final String fingerprint;
  final bool imported;
  final int createdAt;
  const KeyRow({
    required this.id,
    required this.label,
    required this.publicKey,
    required this.fingerprint,
    required this.imported,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['public_key'] = Variable<String>(publicKey);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['imported'] = Variable<bool>(imported);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  KeyRowsCompanion toCompanion(bool nullToAbsent) {
    return KeyRowsCompanion(
      id: Value(id),
      label: Value(label),
      publicKey: Value(publicKey),
      fingerprint: Value(fingerprint),
      imported: Value(imported),
      createdAt: Value(createdAt),
    );
  }

  factory KeyRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      imported: serializer.fromJson<bool>(json['imported']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'publicKey': serializer.toJson<String>(publicKey),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'imported': serializer.toJson<bool>(imported),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  KeyRow copyWith({
    String? id,
    String? label,
    String? publicKey,
    String? fingerprint,
    bool? imported,
    int? createdAt,
  }) => KeyRow(
    id: id ?? this.id,
    label: label ?? this.label,
    publicKey: publicKey ?? this.publicKey,
    fingerprint: fingerprint ?? this.fingerprint,
    imported: imported ?? this.imported,
    createdAt: createdAt ?? this.createdAt,
  );
  KeyRow copyWithCompanion(KeyRowsCompanion data) {
    return KeyRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      fingerprint: data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      imported: data.imported.present ? data.imported.value : this.imported,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('publicKey: $publicKey, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('imported: $imported, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, publicKey, fingerprint, imported, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.publicKey == this.publicKey &&
          other.fingerprint == this.fingerprint &&
          other.imported == this.imported &&
          other.createdAt == this.createdAt);
}

class KeyRowsCompanion extends UpdateCompanion<KeyRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> publicKey;
  final Value<String> fingerprint;
  final Value<bool> imported;
  final Value<int> createdAt;
  final Value<int> rowid;
  const KeyRowsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.imported = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyRowsCompanion.insert({
    required String id,
    required String label,
    required String publicKey,
    required String fingerprint,
    required bool imported,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       publicKey = Value(publicKey),
       fingerprint = Value(fingerprint),
       imported = Value(imported),
       createdAt = Value(createdAt);
  static Insertable<KeyRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? publicKey,
    Expression<String>? fingerprint,
    Expression<bool>? imported,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (publicKey != null) 'public_key': publicKey,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (imported != null) 'imported': imported,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? publicKey,
    Value<String>? fingerprint,
    Value<bool>? imported,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return KeyRowsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      publicKey: publicKey ?? this.publicKey,
      fingerprint: fingerprint ?? this.fingerprint,
      imported: imported ?? this.imported,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (imported.present) {
      map['imported'] = Variable<bool>(imported.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyRowsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('publicKey: $publicKey, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('imported: $imported, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventRowsTable extends EventRows with TableInfo<$EventRowsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hostIdMeta = const VerificationMeta('hostId');
  @override
  late final GeneratedColumn<String> hostId = GeneratedColumn<String>(
    'host_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paneMeta = const VerificationMeta('pane');
  @override
  late final GeneratedColumn<String> pane = GeneratedColumn<String>(
    'pane',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta('response');
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    hostId,
    id,
    seq,
    agent,
    kind,
    title,
    summary,
    pane,
    at,
    status,
    response,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_events';
  @override
  VerificationContext validateIntegrity(Insertable<EventRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('host_id')) {
      context.handle(_hostIdMeta, hostId.isAcceptableOrUnknown(data['host_id']!, _hostIdMeta));
    } else if (isInserting) {
      context.missing(_hostIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(_seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('agent')) {
      context.handle(_agentMeta, agent.isAcceptableOrUnknown(data['agent']!, _agentMeta));
    } else if (isInserting) {
      context.missing(_agentMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta, summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('pane')) {
      context.handle(_paneMeta, pane.isAcceptableOrUnknown(data['pane']!, _paneMeta));
    } else if (isInserting) {
      context.missing(_paneMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hostId, id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      hostId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_id'],
      )!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      seq: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      )!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      pane: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pane'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}at'])!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      ),
    );
  }

  @override
  $EventRowsTable createAlias(String alias) {
    return $EventRowsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String hostId;
  final String id;
  final int seq;
  final String agent;
  final String kind;
  final String title;
  final String summary;
  final String pane;
  final int at;
  final String status;
  final String? response;
  const EventRow({
    required this.hostId,
    required this.id,
    required this.seq,
    required this.agent,
    required this.kind,
    required this.title,
    required this.summary,
    required this.pane,
    required this.at,
    required this.status,
    this.response,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['host_id'] = Variable<String>(hostId);
    map['id'] = Variable<String>(id);
    map['seq'] = Variable<int>(seq);
    map['agent'] = Variable<String>(agent);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['pane'] = Variable<String>(pane);
    map['at'] = Variable<int>(at);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || response != null) {
      map['response'] = Variable<String>(response);
    }
    return map;
  }

  EventRowsCompanion toCompanion(bool nullToAbsent) {
    return EventRowsCompanion(
      hostId: Value(hostId),
      id: Value(id),
      seq: Value(seq),
      agent: Value(agent),
      kind: Value(kind),
      title: Value(title),
      summary: Value(summary),
      pane: Value(pane),
      at: Value(at),
      status: Value(status),
      response: response == null && nullToAbsent ? const Value.absent() : Value(response),
    );
  }

  factory EventRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      hostId: serializer.fromJson<String>(json['hostId']),
      id: serializer.fromJson<String>(json['id']),
      seq: serializer.fromJson<int>(json['seq']),
      agent: serializer.fromJson<String>(json['agent']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      pane: serializer.fromJson<String>(json['pane']),
      at: serializer.fromJson<int>(json['at']),
      status: serializer.fromJson<String>(json['status']),
      response: serializer.fromJson<String?>(json['response']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hostId': serializer.toJson<String>(hostId),
      'id': serializer.toJson<String>(id),
      'seq': serializer.toJson<int>(seq),
      'agent': serializer.toJson<String>(agent),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'pane': serializer.toJson<String>(pane),
      'at': serializer.toJson<int>(at),
      'status': serializer.toJson<String>(status),
      'response': serializer.toJson<String?>(response),
    };
  }

  EventRow copyWith({
    String? hostId,
    String? id,
    int? seq,
    String? agent,
    String? kind,
    String? title,
    String? summary,
    String? pane,
    int? at,
    String? status,
    Value<String?> response = const Value.absent(),
  }) => EventRow(
    hostId: hostId ?? this.hostId,
    id: id ?? this.id,
    seq: seq ?? this.seq,
    agent: agent ?? this.agent,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    pane: pane ?? this.pane,
    at: at ?? this.at,
    status: status ?? this.status,
    response: response.present ? response.value : this.response,
  );
  EventRow copyWithCompanion(EventRowsCompanion data) {
    return EventRow(
      hostId: data.hostId.present ? data.hostId.value : this.hostId,
      id: data.id.present ? data.id.value : this.id,
      seq: data.seq.present ? data.seq.value : this.seq,
      agent: data.agent.present ? data.agent.value : this.agent,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      pane: data.pane.present ? data.pane.value : this.pane,
      at: data.at.present ? data.at.value : this.at,
      status: data.status.present ? data.status.value : this.status,
      response: data.response.present ? data.response.value : this.response,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('hostId: $hostId, ')
          ..write('id: $id, ')
          ..write('seq: $seq, ')
          ..write('agent: $agent, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('pane: $pane, ')
          ..write('at: $at, ')
          ..write('status: $status, ')
          ..write('response: $response')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(hostId, id, seq, agent, kind, title, summary, pane, at, status, response);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.hostId == this.hostId &&
          other.id == this.id &&
          other.seq == this.seq &&
          other.agent == this.agent &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.pane == this.pane &&
          other.at == this.at &&
          other.status == this.status &&
          other.response == this.response);
}

class EventRowsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> hostId;
  final Value<String> id;
  final Value<int> seq;
  final Value<String> agent;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> pane;
  final Value<int> at;
  final Value<String> status;
  final Value<String?> response;
  final Value<int> rowid;
  const EventRowsCompanion({
    this.hostId = const Value.absent(),
    this.id = const Value.absent(),
    this.seq = const Value.absent(),
    this.agent = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.pane = const Value.absent(),
    this.at = const Value.absent(),
    this.status = const Value.absent(),
    this.response = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventRowsCompanion.insert({
    required String hostId,
    required String id,
    required int seq,
    required String agent,
    required String kind,
    required String title,
    required String summary,
    required String pane,
    required int at,
    required String status,
    this.response = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hostId = Value(hostId),
       id = Value(id),
       seq = Value(seq),
       agent = Value(agent),
       kind = Value(kind),
       title = Value(title),
       summary = Value(summary),
       pane = Value(pane),
       at = Value(at),
       status = Value(status);
  static Insertable<EventRow> custom({
    Expression<String>? hostId,
    Expression<String>? id,
    Expression<int>? seq,
    Expression<String>? agent,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? pane,
    Expression<int>? at,
    Expression<String>? status,
    Expression<String>? response,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hostId != null) 'host_id': hostId,
      if (id != null) 'id': id,
      if (seq != null) 'seq': seq,
      if (agent != null) 'agent': agent,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (pane != null) 'pane': pane,
      if (at != null) 'at': at,
      if (status != null) 'status': status,
      if (response != null) 'response': response,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventRowsCompanion copyWith({
    Value<String>? hostId,
    Value<String>? id,
    Value<int>? seq,
    Value<String>? agent,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? pane,
    Value<int>? at,
    Value<String>? status,
    Value<String?>? response,
    Value<int>? rowid,
  }) {
    return EventRowsCompanion(
      hostId: hostId ?? this.hostId,
      id: id ?? this.id,
      seq: seq ?? this.seq,
      agent: agent ?? this.agent,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      pane: pane ?? this.pane,
      at: at ?? this.at,
      status: status ?? this.status,
      response: response ?? this.response,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hostId.present) {
      map['host_id'] = Variable<String>(hostId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (pane.present) {
      map['pane'] = Variable<String>(pane.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventRowsCompanion(')
          ..write('hostId: $hostId, ')
          ..write('id: $id, ')
          ..write('seq: $seq, ')
          ..write('agent: $agent, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('pane: $pane, ')
          ..write('at: $at, ')
          ..write('status: $status, ')
          ..write('response: $response, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow && other.key == this.key && other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HostRowsTable hostRows = $HostRowsTable(this);
  late final $KeyRowsTable keyRows = $KeyRowsTable(this);
  late final $EventRowsTable eventRows = $EventRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [hostRows, keyRows, eventRows, settingRows];
}

typedef $$HostRowsTableCreateCompanionBuilder = HostRowsCompanion Function({
  required String id,
  required String alias,
  required String address,
  required int port,
  required String username,
  Value<String?> keyId,
  required String fingerprint,
  Value<String?> hookPath,
  Value<String?> deviceId,
  Value<String?> hostPushKey,
  required String pairedVia,
  Value<String?> endpointSent,
  Value<String?> lastAttach,
  required int createdAt,
  Value<int> rowid,
});
typedef $$HostRowsTableUpdateCompanionBuilder = HostRowsCompanion Function({
  Value<String> id,
  Value<String> alias,
  Value<String> address,
  Value<int> port,
  Value<String> username,
  Value<String?> keyId,
  Value<String> fingerprint,
  Value<String?> hookPath,
  Value<String?> deviceId,
  Value<String?> hostPushKey,
  Value<String> pairedVia,
  Value<String?> endpointSent,
  Value<String?> lastAttach,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$HostRowsTableFilterComposer extends Composer<_$AppDatabase, $HostRowsTable> {
  $$HostRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hookPath =>
      $composableBuilder(column: $table.hookPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hostPushKey =>
      $composableBuilder(column: $table.hostPushKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pairedVia =>
      $composableBuilder(column: $table.pairedVia, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpointSent =>
      $composableBuilder(column: $table.endpointSent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastAttach =>
      $composableBuilder(column: $table.lastAttach, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$HostRowsTableOrderingComposer extends Composer<_$AppDatabase, $HostRowsTable> {
  $$HostRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hookPath =>
      $composableBuilder(column: $table.hookPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hostPushKey =>
      $composableBuilder(column: $table.hostPushKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pairedVia =>
      $composableBuilder(column: $table.pairedVia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpointSent =>
      $composableBuilder(column: $table.endpointSent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastAttach =>
      $composableBuilder(column: $table.lastAttach, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$HostRowsTableAnnotationComposer extends Composer<_$AppDatabase, $HostRowsTable> {
  $$HostRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => column);

  GeneratedColumn<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<String> get hookPath =>
      $composableBuilder(column: $table.hookPath, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get hostPushKey =>
      $composableBuilder(column: $table.hostPushKey, builder: (column) => column);

  GeneratedColumn<String> get pairedVia =>
      $composableBuilder(column: $table.pairedVia, builder: (column) => column);

  GeneratedColumn<String> get endpointSent =>
      $composableBuilder(column: $table.endpointSent, builder: (column) => column);

  GeneratedColumn<String> get lastAttach =>
      $composableBuilder(column: $table.lastAttach, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HostRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HostRowsTable,
          HostRow,
          $$HostRowsTableFilterComposer,
          $$HostRowsTableOrderingComposer,
          $$HostRowsTableAnnotationComposer,
          $$HostRowsTableCreateCompanionBuilder,
          $$HostRowsTableUpdateCompanionBuilder,
          (HostRow, BaseReferences<_$AppDatabase, $HostRowsTable, HostRow>),
          HostRow,
          PrefetchHooks Function()
        > {
  $$HostRowsTableTableManager(_$AppDatabase db, $HostRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HostRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HostRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HostRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> keyId = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String?> hookPath = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> hostPushKey = const Value.absent(),
                Value<String> pairedVia = const Value.absent(),
                Value<String?> endpointSent = const Value.absent(),
                Value<String?> lastAttach = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HostRowsCompanion(
                id: id,
                alias: alias,
                address: address,
                port: port,
                username: username,
                keyId: keyId,
                fingerprint: fingerprint,
                hookPath: hookPath,
                deviceId: deviceId,
                hostPushKey: hostPushKey,
                pairedVia: pairedVia,
                endpointSent: endpointSent,
                lastAttach: lastAttach,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String alias,
                required String address,
                required int port,
                required String username,
                Value<String?> keyId = const Value.absent(),
                required String fingerprint,
                Value<String?> hookPath = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> hostPushKey = const Value.absent(),
                required String pairedVia,
                Value<String?> endpointSent = const Value.absent(),
                Value<String?> lastAttach = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => HostRowsCompanion.insert(
                id: id,
                alias: alias,
                address: address,
                port: port,
                username: username,
                keyId: keyId,
                fingerprint: fingerprint,
                hookPath: hookPath,
                deviceId: deviceId,
                hostPushKey: hostPushKey,
                pairedVia: pairedVia,
                endpointSent: endpointSent,
                lastAttach: lastAttach,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HostRowsTable, HostRow>(table),
                  BaseReferences<_$AppDatabase, $HostRowsTable, HostRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HostRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HostRowsTable,
      HostRow,
      $$HostRowsTableFilterComposer,
      $$HostRowsTableOrderingComposer,
      $$HostRowsTableAnnotationComposer,
      $$HostRowsTableCreateCompanionBuilder,
      $$HostRowsTableUpdateCompanionBuilder,
      (HostRow, BaseReferences<_$AppDatabase, $HostRowsTable, HostRow>),
      HostRow,
      PrefetchHooks Function()
    >;
typedef $$KeyRowsTableCreateCompanionBuilder = KeyRowsCompanion Function({
  required String id,
  required String label,
  required String publicKey,
  required String fingerprint,
  required bool imported,
  required int createdAt,
  Value<int> rowid,
});
typedef $$KeyRowsTableUpdateCompanionBuilder = KeyRowsCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> publicKey,
  Value<String> fingerprint,
  Value<bool> imported,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$KeyRowsTableFilterComposer extends Composer<_$AppDatabase, $KeyRowsTable> {
  $$KeyRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get imported =>
      $composableBuilder(column: $table.imported, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$KeyRowsTableOrderingComposer extends Composer<_$AppDatabase, $KeyRowsTable> {
  $$KeyRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get imported =>
      $composableBuilder(column: $table.imported, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$KeyRowsTableAnnotationComposer extends Composer<_$AppDatabase, $KeyRowsTable> {
  $$KeyRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get fingerprint =>
      $composableBuilder(column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<bool> get imported =>
      $composableBuilder(column: $table.imported, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$KeyRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyRowsTable,
          KeyRow,
          $$KeyRowsTableFilterComposer,
          $$KeyRowsTableOrderingComposer,
          $$KeyRowsTableAnnotationComposer,
          $$KeyRowsTableCreateCompanionBuilder,
          $$KeyRowsTableUpdateCompanionBuilder,
          (KeyRow, BaseReferences<_$AppDatabase, $KeyRowsTable, KeyRow>),
          KeyRow,
          PrefetchHooks Function()
        > {
  $$KeyRowsTableTableManager(_$AppDatabase db, $KeyRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KeyRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KeyRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<bool> imported = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyRowsCompanion(
                id: id,
                label: label,
                publicKey: publicKey,
                fingerprint: fingerprint,
                imported: imported,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String publicKey,
                required String fingerprint,
                required bool imported,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => KeyRowsCompanion.insert(
                id: id,
                label: label,
                publicKey: publicKey,
                fingerprint: fingerprint,
                imported: imported,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyRowsTable, KeyRow>(table),
                  BaseReferences<_$AppDatabase, $KeyRowsTable, KeyRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyRowsTable,
      KeyRow,
      $$KeyRowsTableFilterComposer,
      $$KeyRowsTableOrderingComposer,
      $$KeyRowsTableAnnotationComposer,
      $$KeyRowsTableCreateCompanionBuilder,
      $$KeyRowsTableUpdateCompanionBuilder,
      (KeyRow, BaseReferences<_$AppDatabase, $KeyRowsTable, KeyRow>),
      KeyRow,
      PrefetchHooks Function()
    >;
typedef $$EventRowsTableCreateCompanionBuilder = EventRowsCompanion Function({
  required String hostId,
  required String id,
  required int seq,
  required String agent,
  required String kind,
  required String title,
  required String summary,
  required String pane,
  required int at,
  required String status,
  Value<String?> response,
  Value<int> rowid,
});
typedef $$EventRowsTableUpdateCompanionBuilder = EventRowsCompanion Function({
  Value<String> hostId,
  Value<String> id,
  Value<int> seq,
  Value<String> agent,
  Value<String> kind,
  Value<String> title,
  Value<String> summary,
  Value<String> pane,
  Value<int> at,
  Value<String> status,
  Value<String?> response,
  Value<int> rowid,
});

class $$EventRowsTableFilterComposer extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hostId =>
      $composableBuilder(column: $table.hostId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pane =>
      $composableBuilder(column: $table.pane, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => ColumnFilters(column));
}

class $$EventRowsTableOrderingComposer extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hostId =>
      $composableBuilder(column: $table.hostId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pane =>
      $composableBuilder(column: $table.pane, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => ColumnOrderings(column));
}

class $$EventRowsTableAnnotationComposer extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hostId =>
      $composableBuilder(column: $table.hostId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get pane =>
      $composableBuilder(column: $table.pane, builder: (column) => column);

  GeneratedColumn<int> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);
}

class $$EventRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventRowsTable,
          EventRow,
          $$EventRowsTableFilterComposer,
          $$EventRowsTableOrderingComposer,
          $$EventRowsTableAnnotationComposer,
          $$EventRowsTableCreateCompanionBuilder,
          $$EventRowsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventRowsTableTableManager(_$AppDatabase db, $EventRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EventRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EventRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> hostId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> pane = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> response = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventRowsCompanion(
                hostId: hostId,
                id: id,
                seq: seq,
                agent: agent,
                kind: kind,
                title: title,
                summary: summary,
                pane: pane,
                at: at,
                status: status,
                response: response,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hostId,
                required String id,
                required int seq,
                required String agent,
                required String kind,
                required String title,
                required String summary,
                required String pane,
                required int at,
                required String status,
                Value<String?> response = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventRowsCompanion.insert(
                hostId: hostId,
                id: id,
                seq: seq,
                agent: agent,
                kind: kind,
                title: title,
                summary: summary,
                pane: pane,
                at: at,
                status: status,
                response: response,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventRowsTable, EventRow>(table),
                  BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventRowsTable,
      EventRow,
      $$EventRowsTableFilterComposer,
      $$EventRowsTableOrderingComposer,
      $$EventRowsTableAnnotationComposer,
      $$EventRowsTableCreateCompanionBuilder,
      $$EventRowsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder = SettingRowsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingRowsTableUpdateCompanionBuilder = SettingRowsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingRowsTableFilterComposer extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingRowsTableOrderingComposer extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingRowsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (SettingRow, BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingRowsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingRowsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HostRowsTableTableManager get hostRows => $$HostRowsTableTableManager(_db, _db.hostRows);
  $$KeyRowsTableTableManager get keyRows => $$KeyRowsTableTableManager(_db, _db.keyRows);
  $$EventRowsTableTableManager get eventRows => $$EventRowsTableTableManager(_db, _db.eventRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
}
