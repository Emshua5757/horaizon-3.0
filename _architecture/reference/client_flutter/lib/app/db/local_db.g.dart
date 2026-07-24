// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $ShuaSyncQueueTable extends ShuaSyncQueue
    with TableInfo<$ShuaSyncQueueTable, ShuaSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShuaSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<int> tableId = GeneratedColumn<int>(
    'table_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<int> actionType = GeneratedColumn<int>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logicalClockMeta = const VerificationMeta(
    'logicalClock',
  );
  @override
  late final GeneratedColumn<int> logicalClock = GeneratedColumn<int>(
    'logical_clock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
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
    tableId,
    recordId,
    actionType,
    payload,
    logicalClock,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shua_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShuaSyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tableIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('logical_clock')) {
      context.handle(
        _logicalClockMeta,
        logicalClock.isAcceptableOrUnknown(
          data['logical_clock']!,
          _logicalClockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_logicalClockMeta);
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
  ShuaSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShuaSyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}table_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      logicalClock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}logical_clock'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ShuaSyncQueueTable createAlias(String alias) {
    return $ShuaSyncQueueTable(attachedDatabase, alias);
  }
}

class ShuaSyncQueueData extends DataClass
    implements Insertable<ShuaSyncQueueData> {
  final int id;
  final int tableId;
  final String recordId;
  final int actionType;
  final Uint8List payload;
  final int logicalClock;
  final int createdAt;
  const ShuaSyncQueueData({
    required this.id,
    required this.tableId,
    required this.recordId,
    required this.actionType,
    required this.payload,
    required this.logicalClock,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_id'] = Variable<int>(tableId);
    map['record_id'] = Variable<String>(recordId);
    map['action_type'] = Variable<int>(actionType);
    map['payload'] = Variable<Uint8List>(payload);
    map['logical_clock'] = Variable<int>(logicalClock);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ShuaSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return ShuaSyncQueueCompanion(
      id: Value(id),
      tableId: Value(tableId),
      recordId: Value(recordId),
      actionType: Value(actionType),
      payload: Value(payload),
      logicalClock: Value(logicalClock),
      createdAt: Value(createdAt),
    );
  }

  factory ShuaSyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShuaSyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      tableId: serializer.fromJson<int>(json['tableId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      actionType: serializer.fromJson<int>(json['actionType']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      logicalClock: serializer.fromJson<int>(json['logicalClock']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tableId': serializer.toJson<int>(tableId),
      'recordId': serializer.toJson<String>(recordId),
      'actionType': serializer.toJson<int>(actionType),
      'payload': serializer.toJson<Uint8List>(payload),
      'logicalClock': serializer.toJson<int>(logicalClock),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ShuaSyncQueueData copyWith({
    int? id,
    int? tableId,
    String? recordId,
    int? actionType,
    Uint8List? payload,
    int? logicalClock,
    int? createdAt,
  }) => ShuaSyncQueueData(
    id: id ?? this.id,
    tableId: tableId ?? this.tableId,
    recordId: recordId ?? this.recordId,
    actionType: actionType ?? this.actionType,
    payload: payload ?? this.payload,
    logicalClock: logicalClock ?? this.logicalClock,
    createdAt: createdAt ?? this.createdAt,
  );
  ShuaSyncQueueData copyWithCompanion(ShuaSyncQueueCompanion data) {
    return ShuaSyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      payload: data.payload.present ? data.payload.value : this.payload,
      logicalClock: data.logicalClock.present
          ? data.logicalClock.value
          : this.logicalClock,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShuaSyncQueueData(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('recordId: $recordId, ')
          ..write('actionType: $actionType, ')
          ..write('payload: $payload, ')
          ..write('logicalClock: $logicalClock, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tableId,
    recordId,
    actionType,
    $driftBlobEquality.hash(payload),
    logicalClock,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShuaSyncQueueData &&
          other.id == this.id &&
          other.tableId == this.tableId &&
          other.recordId == this.recordId &&
          other.actionType == this.actionType &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.logicalClock == this.logicalClock &&
          other.createdAt == this.createdAt);
}

class ShuaSyncQueueCompanion extends UpdateCompanion<ShuaSyncQueueData> {
  final Value<int> id;
  final Value<int> tableId;
  final Value<String> recordId;
  final Value<int> actionType;
  final Value<Uint8List> payload;
  final Value<int> logicalClock;
  final Value<int> createdAt;
  const ShuaSyncQueueCompanion({
    this.id = const Value.absent(),
    this.tableId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.payload = const Value.absent(),
    this.logicalClock = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ShuaSyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required int tableId,
    required String recordId,
    required int actionType,
    required Uint8List payload,
    required int logicalClock,
    required int createdAt,
  }) : tableId = Value(tableId),
       recordId = Value(recordId),
       actionType = Value(actionType),
       payload = Value(payload),
       logicalClock = Value(logicalClock),
       createdAt = Value(createdAt);
  static Insertable<ShuaSyncQueueData> custom({
    Expression<int>? id,
    Expression<int>? tableId,
    Expression<String>? recordId,
    Expression<int>? actionType,
    Expression<Uint8List>? payload,
    Expression<int>? logicalClock,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableId != null) 'table_id': tableId,
      if (recordId != null) 'record_id': recordId,
      if (actionType != null) 'action_type': actionType,
      if (payload != null) 'payload': payload,
      if (logicalClock != null) 'logical_clock': logicalClock,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ShuaSyncQueueCompanion copyWith({
    Value<int>? id,
    Value<int>? tableId,
    Value<String>? recordId,
    Value<int>? actionType,
    Value<Uint8List>? payload,
    Value<int>? logicalClock,
    Value<int>? createdAt,
  }) {
    return ShuaSyncQueueCompanion(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      recordId: recordId ?? this.recordId,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      logicalClock: logicalClock ?? this.logicalClock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<int>(tableId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<int>(actionType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (logicalClock.present) {
      map['logical_clock'] = Variable<int>(logicalClock.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShuaSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('tableId: $tableId, ')
          ..write('recordId: $recordId, ')
          ..write('actionType: $actionType, ')
          ..write('payload: $payload, ')
          ..write('logicalClock: $logicalClock, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodicMemoriesTable extends EpisodicMemories
    with TableInfo<$EpisodicMemoriesTable, EpisodicMemory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodicMemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoryContentMeta = const VerificationMeta(
    'memoryContent',
  );
  @override
  late final GeneratedColumn<String> memoryContent = GeneratedColumn<String>(
    'memory_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityTierMeta = const VerificationMeta(
    'priorityTier',
  );
  @override
  late final GeneratedColumn<int> priorityTier = GeneratedColumn<int>(
    'priority_tier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _moodTagMeta = const VerificationMeta(
    'moodTag',
  );
  @override
  late final GeneratedColumn<String> moodTag = GeneratedColumn<String>(
    'mood_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('neutral'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _suggestedTagsMeta = const VerificationMeta(
    'suggestedTags',
  );
  @override
  late final GeneratedColumn<String> suggestedTags = GeneratedColumn<String>(
    'suggested_tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    memoryContent,
    priorityTier,
    moodTag,
    createdAt,
    suggestedTags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodic_memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodicMemory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('memory_content')) {
      context.handle(
        _memoryContentMeta,
        memoryContent.isAcceptableOrUnknown(
          data['memory_content']!,
          _memoryContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memoryContentMeta);
    }
    if (data.containsKey('priority_tier')) {
      context.handle(
        _priorityTierMeta,
        priorityTier.isAcceptableOrUnknown(
          data['priority_tier']!,
          _priorityTierMeta,
        ),
      );
    }
    if (data.containsKey('mood_tag')) {
      context.handle(
        _moodTagMeta,
        moodTag.isAcceptableOrUnknown(data['mood_tag']!, _moodTagMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('suggested_tags')) {
      context.handle(
        _suggestedTagsMeta,
        suggestedTags.isAcceptableOrUnknown(
          data['suggested_tags']!,
          _suggestedTagsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpisodicMemory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodicMemory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      memoryContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_content'],
      )!,
      priorityTier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority_tier'],
      )!,
      moodTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood_tag'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      suggestedTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggested_tags'],
      ),
    );
  }

  @override
  $EpisodicMemoriesTable createAlias(String alias) {
    return $EpisodicMemoriesTable(attachedDatabase, alias);
  }
}

class EpisodicMemory extends DataClass implements Insertable<EpisodicMemory> {
  final String id;
  final String userId;
  final String memoryContent;
  final int priorityTier;
  final String moodTag;
  final DateTime createdAt;
  final String? suggestedTags;
  const EpisodicMemory({
    required this.id,
    required this.userId,
    required this.memoryContent,
    required this.priorityTier,
    required this.moodTag,
    required this.createdAt,
    this.suggestedTags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['memory_content'] = Variable<String>(memoryContent);
    map['priority_tier'] = Variable<int>(priorityTier);
    map['mood_tag'] = Variable<String>(moodTag);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || suggestedTags != null) {
      map['suggested_tags'] = Variable<String>(suggestedTags);
    }
    return map;
  }

  EpisodicMemoriesCompanion toCompanion(bool nullToAbsent) {
    return EpisodicMemoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      memoryContent: Value(memoryContent),
      priorityTier: Value(priorityTier),
      moodTag: Value(moodTag),
      createdAt: Value(createdAt),
      suggestedTags: suggestedTags == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedTags),
    );
  }

  factory EpisodicMemory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodicMemory(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      memoryContent: serializer.fromJson<String>(json['memoryContent']),
      priorityTier: serializer.fromJson<int>(json['priorityTier']),
      moodTag: serializer.fromJson<String>(json['moodTag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      suggestedTags: serializer.fromJson<String?>(json['suggestedTags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'memoryContent': serializer.toJson<String>(memoryContent),
      'priorityTier': serializer.toJson<int>(priorityTier),
      'moodTag': serializer.toJson<String>(moodTag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'suggestedTags': serializer.toJson<String?>(suggestedTags),
    };
  }

  EpisodicMemory copyWith({
    String? id,
    String? userId,
    String? memoryContent,
    int? priorityTier,
    String? moodTag,
    DateTime? createdAt,
    Value<String?> suggestedTags = const Value.absent(),
  }) => EpisodicMemory(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    memoryContent: memoryContent ?? this.memoryContent,
    priorityTier: priorityTier ?? this.priorityTier,
    moodTag: moodTag ?? this.moodTag,
    createdAt: createdAt ?? this.createdAt,
    suggestedTags: suggestedTags.present
        ? suggestedTags.value
        : this.suggestedTags,
  );
  EpisodicMemory copyWithCompanion(EpisodicMemoriesCompanion data) {
    return EpisodicMemory(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      memoryContent: data.memoryContent.present
          ? data.memoryContent.value
          : this.memoryContent,
      priorityTier: data.priorityTier.present
          ? data.priorityTier.value
          : this.priorityTier,
      moodTag: data.moodTag.present ? data.moodTag.value : this.moodTag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      suggestedTags: data.suggestedTags.present
          ? data.suggestedTags.value
          : this.suggestedTags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodicMemory(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('memoryContent: $memoryContent, ')
          ..write('priorityTier: $priorityTier, ')
          ..write('moodTag: $moodTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('suggestedTags: $suggestedTags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    memoryContent,
    priorityTier,
    moodTag,
    createdAt,
    suggestedTags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodicMemory &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.memoryContent == this.memoryContent &&
          other.priorityTier == this.priorityTier &&
          other.moodTag == this.moodTag &&
          other.createdAt == this.createdAt &&
          other.suggestedTags == this.suggestedTags);
}

class EpisodicMemoriesCompanion extends UpdateCompanion<EpisodicMemory> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> memoryContent;
  final Value<int> priorityTier;
  final Value<String> moodTag;
  final Value<DateTime> createdAt;
  final Value<String?> suggestedTags;
  final Value<int> rowid;
  const EpisodicMemoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.memoryContent = const Value.absent(),
    this.priorityTier = const Value.absent(),
    this.moodTag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.suggestedTags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodicMemoriesCompanion.insert({
    required String id,
    required String userId,
    required String memoryContent,
    this.priorityTier = const Value.absent(),
    this.moodTag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.suggestedTags = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       memoryContent = Value(memoryContent);
  static Insertable<EpisodicMemory> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? memoryContent,
    Expression<int>? priorityTier,
    Expression<String>? moodTag,
    Expression<DateTime>? createdAt,
    Expression<String>? suggestedTags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (memoryContent != null) 'memory_content': memoryContent,
      if (priorityTier != null) 'priority_tier': priorityTier,
      if (moodTag != null) 'mood_tag': moodTag,
      if (createdAt != null) 'created_at': createdAt,
      if (suggestedTags != null) 'suggested_tags': suggestedTags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodicMemoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? memoryContent,
    Value<int>? priorityTier,
    Value<String>? moodTag,
    Value<DateTime>? createdAt,
    Value<String?>? suggestedTags,
    Value<int>? rowid,
  }) {
    return EpisodicMemoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memoryContent: memoryContent ?? this.memoryContent,
      priorityTier: priorityTier ?? this.priorityTier,
      moodTag: moodTag ?? this.moodTag,
      createdAt: createdAt ?? this.createdAt,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (memoryContent.present) {
      map['memory_content'] = Variable<String>(memoryContent.value);
    }
    if (priorityTier.present) {
      map['priority_tier'] = Variable<int>(priorityTier.value);
    }
    if (moodTag.present) {
      map['mood_tag'] = Variable<String>(moodTag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (suggestedTags.present) {
      map['suggested_tags'] = Variable<String>(suggestedTags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodicMemoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('memoryContent: $memoryContent, ')
          ..write('priorityTier: $priorityTier, ')
          ..write('moodTag: $moodTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('suggestedTags: $suggestedTags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShuaDiaryEntriesTable extends ShuaDiaryEntries
    with TableInfo<$ShuaDiaryEntriesTable, ShuaDiaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShuaDiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('Untitled'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lamportClockMeta = const VerificationMeta(
    'lamportClock',
  );
  @override
  late final GeneratedColumn<int> lamportClock = GeneratedColumn<int>(
    'lamport_clock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _privacyTagMeta = const VerificationMeta(
    'privacyTag',
  );
  @override
  late final GeneratedColumn<String> privacyTag = GeneratedColumn<String>(
    'privacy_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sfw'),
  );
  static const VerificationMeta _analysisStateMeta = const VerificationMeta(
    'analysisState',
  );
  @override
  late final GeneratedColumn<String> analysisState = GeneratedColumn<String>(
    'analysis_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  static const VerificationMeta _sentimentScoreMeta = const VerificationMeta(
    'sentimentScore',
  );
  @override
  late final GeneratedColumn<double> sentimentScore = GeneratedColumn<double>(
    'sentiment_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _milestoneTagMeta = const VerificationMeta(
    'milestoneTag',
  );
  @override
  late final GeneratedColumn<String> milestoneTag = GeneratedColumn<String>(
    'milestone_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createdAt,
    lamportClock,
    privacyTag,
    analysisState,
    sentimentScore,
    milestoneTag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shua_diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShuaDiaryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('lamport_clock')) {
      context.handle(
        _lamportClockMeta,
        lamportClock.isAcceptableOrUnknown(
          data['lamport_clock']!,
          _lamportClockMeta,
        ),
      );
    }
    if (data.containsKey('privacy_tag')) {
      context.handle(
        _privacyTagMeta,
        privacyTag.isAcceptableOrUnknown(data['privacy_tag']!, _privacyTagMeta),
      );
    }
    if (data.containsKey('analysis_state')) {
      context.handle(
        _analysisStateMeta,
        analysisState.isAcceptableOrUnknown(
          data['analysis_state']!,
          _analysisStateMeta,
        ),
      );
    }
    if (data.containsKey('sentiment_score')) {
      context.handle(
        _sentimentScoreMeta,
        sentimentScore.isAcceptableOrUnknown(
          data['sentiment_score']!,
          _sentimentScoreMeta,
        ),
      );
    }
    if (data.containsKey('milestone_tag')) {
      context.handle(
        _milestoneTagMeta,
        milestoneTag.isAcceptableOrUnknown(
          data['milestone_tag']!,
          _milestoneTagMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShuaDiaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShuaDiaryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lamportClock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport_clock'],
      )!,
      privacyTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy_tag'],
      )!,
      analysisState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analysis_state'],
      )!,
      sentimentScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sentiment_score'],
      ),
      milestoneTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestone_tag'],
      ),
    );
  }

  @override
  $ShuaDiaryEntriesTable createAlias(String alias) {
    return $ShuaDiaryEntriesTable(attachedDatabase, alias);
  }
}

class ShuaDiaryEntry extends DataClass implements Insertable<ShuaDiaryEntry> {
  final String id;
  final String title;
  final DateTime createdAt;
  final int lamportClock;
  final String privacyTag;
  final String analysisState;
  final double? sentimentScore;
  final String? milestoneTag;
  const ShuaDiaryEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lamportClock,
    required this.privacyTag,
    required this.analysisState,
    this.sentimentScore,
    this.milestoneTag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['lamport_clock'] = Variable<int>(lamportClock);
    map['privacy_tag'] = Variable<String>(privacyTag);
    map['analysis_state'] = Variable<String>(analysisState);
    if (!nullToAbsent || sentimentScore != null) {
      map['sentiment_score'] = Variable<double>(sentimentScore);
    }
    if (!nullToAbsent || milestoneTag != null) {
      map['milestone_tag'] = Variable<String>(milestoneTag);
    }
    return map;
  }

  ShuaDiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return ShuaDiaryEntriesCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      lamportClock: Value(lamportClock),
      privacyTag: Value(privacyTag),
      analysisState: Value(analysisState),
      sentimentScore: sentimentScore == null && nullToAbsent
          ? const Value.absent()
          : Value(sentimentScore),
      milestoneTag: milestoneTag == null && nullToAbsent
          ? const Value.absent()
          : Value(milestoneTag),
    );
  }

  factory ShuaDiaryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShuaDiaryEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lamportClock: serializer.fromJson<int>(json['lamportClock']),
      privacyTag: serializer.fromJson<String>(json['privacyTag']),
      analysisState: serializer.fromJson<String>(json['analysisState']),
      sentimentScore: serializer.fromJson<double?>(json['sentimentScore']),
      milestoneTag: serializer.fromJson<String?>(json['milestoneTag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lamportClock': serializer.toJson<int>(lamportClock),
      'privacyTag': serializer.toJson<String>(privacyTag),
      'analysisState': serializer.toJson<String>(analysisState),
      'sentimentScore': serializer.toJson<double?>(sentimentScore),
      'milestoneTag': serializer.toJson<String?>(milestoneTag),
    };
  }

  ShuaDiaryEntry copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    int? lamportClock,
    String? privacyTag,
    String? analysisState,
    Value<double?> sentimentScore = const Value.absent(),
    Value<String?> milestoneTag = const Value.absent(),
  }) => ShuaDiaryEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    lamportClock: lamportClock ?? this.lamportClock,
    privacyTag: privacyTag ?? this.privacyTag,
    analysisState: analysisState ?? this.analysisState,
    sentimentScore: sentimentScore.present
        ? sentimentScore.value
        : this.sentimentScore,
    milestoneTag: milestoneTag.present ? milestoneTag.value : this.milestoneTag,
  );
  ShuaDiaryEntry copyWithCompanion(ShuaDiaryEntriesCompanion data) {
    return ShuaDiaryEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lamportClock: data.lamportClock.present
          ? data.lamportClock.value
          : this.lamportClock,
      privacyTag: data.privacyTag.present
          ? data.privacyTag.value
          : this.privacyTag,
      analysisState: data.analysisState.present
          ? data.analysisState.value
          : this.analysisState,
      sentimentScore: data.sentimentScore.present
          ? data.sentimentScore.value
          : this.sentimentScore,
      milestoneTag: data.milestoneTag.present
          ? data.milestoneTag.value
          : this.milestoneTag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShuaDiaryEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('lamportClock: $lamportClock, ')
          ..write('privacyTag: $privacyTag, ')
          ..write('analysisState: $analysisState, ')
          ..write('sentimentScore: $sentimentScore, ')
          ..write('milestoneTag: $milestoneTag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createdAt,
    lamportClock,
    privacyTag,
    analysisState,
    sentimentScore,
    milestoneTag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShuaDiaryEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.lamportClock == this.lamportClock &&
          other.privacyTag == this.privacyTag &&
          other.analysisState == this.analysisState &&
          other.sentimentScore == this.sentimentScore &&
          other.milestoneTag == this.milestoneTag);
}

class ShuaDiaryEntriesCompanion extends UpdateCompanion<ShuaDiaryEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<int> lamportClock;
  final Value<String> privacyTag;
  final Value<String> analysisState;
  final Value<double?> sentimentScore;
  final Value<String?> milestoneTag;
  final Value<int> rowid;
  const ShuaDiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lamportClock = const Value.absent(),
    this.privacyTag = const Value.absent(),
    this.analysisState = const Value.absent(),
    this.sentimentScore = const Value.absent(),
    this.milestoneTag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShuaDiaryEntriesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lamportClock = const Value.absent(),
    this.privacyTag = const Value.absent(),
    this.analysisState = const Value.absent(),
    this.sentimentScore = const Value.absent(),
    this.milestoneTag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ShuaDiaryEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<int>? lamportClock,
    Expression<String>? privacyTag,
    Expression<String>? analysisState,
    Expression<double>? sentimentScore,
    Expression<String>? milestoneTag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (lamportClock != null) 'lamport_clock': lamportClock,
      if (privacyTag != null) 'privacy_tag': privacyTag,
      if (analysisState != null) 'analysis_state': analysisState,
      if (sentimentScore != null) 'sentiment_score': sentimentScore,
      if (milestoneTag != null) 'milestone_tag': milestoneTag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShuaDiaryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<int>? lamportClock,
    Value<String>? privacyTag,
    Value<String>? analysisState,
    Value<double?>? sentimentScore,
    Value<String?>? milestoneTag,
    Value<int>? rowid,
  }) {
    return ShuaDiaryEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lamportClock: lamportClock ?? this.lamportClock,
      privacyTag: privacyTag ?? this.privacyTag,
      analysisState: analysisState ?? this.analysisState,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      milestoneTag: milestoneTag ?? this.milestoneTag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lamportClock.present) {
      map['lamport_clock'] = Variable<int>(lamportClock.value);
    }
    if (privacyTag.present) {
      map['privacy_tag'] = Variable<String>(privacyTag.value);
    }
    if (analysisState.present) {
      map['analysis_state'] = Variable<String>(analysisState.value);
    }
    if (sentimentScore.present) {
      map['sentiment_score'] = Variable<double>(sentimentScore.value);
    }
    if (milestoneTag.present) {
      map['milestone_tag'] = Variable<String>(milestoneTag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShuaDiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('lamportClock: $lamportClock, ')
          ..write('privacyTag: $privacyTag, ')
          ..write('analysisState: $analysisState, ')
          ..write('sentimentScore: $sentimentScore, ')
          ..write('milestoneTag: $milestoneTag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShuaDiaryBlocksTable extends ShuaDiaryBlocks
    with TableInfo<$ShuaDiaryBlocksTable, ShuaDiaryBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShuaDiaryBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockTypeMeta = const VerificationMeta(
    'blockType',
  );
  @override
  late final GeneratedColumn<String> blockType = GeneratedColumn<String>(
    'block_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<Uint8List> sortKey = GeneratedColumn<Uint8List>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportClockMeta = const VerificationMeta(
    'lamportClock',
  );
  @override
  late final GeneratedColumn<int> lamportClock = GeneratedColumn<int>(
    'lamport_clock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    blockType,
    content,
    metadata,
    sortKey,
    lamportClock,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shua_diary_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShuaDiaryBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('block_type')) {
      context.handle(
        _blockTypeMeta,
        blockType.isAcceptableOrUnknown(data['block_type']!, _blockTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_blockTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sortKeyMeta);
    }
    if (data.containsKey('lamport_clock')) {
      context.handle(
        _lamportClockMeta,
        lamportClock.isAcceptableOrUnknown(
          data['lamport_clock']!,
          _lamportClockMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShuaDiaryBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShuaDiaryBlock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      blockType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sort_key'],
      )!,
      lamportClock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport_clock'],
      )!,
    );
  }

  @override
  $ShuaDiaryBlocksTable createAlias(String alias) {
    return $ShuaDiaryBlocksTable(attachedDatabase, alias);
  }
}

class ShuaDiaryBlock extends DataClass implements Insertable<ShuaDiaryBlock> {
  final String id;
  final String entryId;
  final String blockType;
  final String content;
  final String? metadata;
  final Uint8List sortKey;
  final int lamportClock;
  const ShuaDiaryBlock({
    required this.id,
    required this.entryId,
    required this.blockType,
    required this.content,
    this.metadata,
    required this.sortKey,
    required this.lamportClock,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['block_type'] = Variable<String>(blockType);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['sort_key'] = Variable<Uint8List>(sortKey);
    map['lamport_clock'] = Variable<int>(lamportClock);
    return map;
  }

  ShuaDiaryBlocksCompanion toCompanion(bool nullToAbsent) {
    return ShuaDiaryBlocksCompanion(
      id: Value(id),
      entryId: Value(entryId),
      blockType: Value(blockType),
      content: Value(content),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      sortKey: Value(sortKey),
      lamportClock: Value(lamportClock),
    );
  }

  factory ShuaDiaryBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShuaDiaryBlock(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      blockType: serializer.fromJson<String>(json['blockType']),
      content: serializer.fromJson<String>(json['content']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      sortKey: serializer.fromJson<Uint8List>(json['sortKey']),
      lamportClock: serializer.fromJson<int>(json['lamportClock']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'blockType': serializer.toJson<String>(blockType),
      'content': serializer.toJson<String>(content),
      'metadata': serializer.toJson<String?>(metadata),
      'sortKey': serializer.toJson<Uint8List>(sortKey),
      'lamportClock': serializer.toJson<int>(lamportClock),
    };
  }

  ShuaDiaryBlock copyWith({
    String? id,
    String? entryId,
    String? blockType,
    String? content,
    Value<String?> metadata = const Value.absent(),
    Uint8List? sortKey,
    int? lamportClock,
  }) => ShuaDiaryBlock(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    blockType: blockType ?? this.blockType,
    content: content ?? this.content,
    metadata: metadata.present ? metadata.value : this.metadata,
    sortKey: sortKey ?? this.sortKey,
    lamportClock: lamportClock ?? this.lamportClock,
  );
  ShuaDiaryBlock copyWithCompanion(ShuaDiaryBlocksCompanion data) {
    return ShuaDiaryBlock(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      blockType: data.blockType.present ? data.blockType.value : this.blockType,
      content: data.content.present ? data.content.value : this.content,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      lamportClock: data.lamportClock.present
          ? data.lamportClock.value
          : this.lamportClock,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShuaDiaryBlock(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('blockType: $blockType, ')
          ..write('content: $content, ')
          ..write('metadata: $metadata, ')
          ..write('sortKey: $sortKey, ')
          ..write('lamportClock: $lamportClock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    blockType,
    content,
    metadata,
    $driftBlobEquality.hash(sortKey),
    lamportClock,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShuaDiaryBlock &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.blockType == this.blockType &&
          other.content == this.content &&
          other.metadata == this.metadata &&
          $driftBlobEquality.equals(other.sortKey, this.sortKey) &&
          other.lamportClock == this.lamportClock);
}

class ShuaDiaryBlocksCompanion extends UpdateCompanion<ShuaDiaryBlock> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> blockType;
  final Value<String> content;
  final Value<String?> metadata;
  final Value<Uint8List> sortKey;
  final Value<int> lamportClock;
  final Value<int> rowid;
  const ShuaDiaryBlocksCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.blockType = const Value.absent(),
    this.content = const Value.absent(),
    this.metadata = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.lamportClock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShuaDiaryBlocksCompanion.insert({
    required String id,
    required String entryId,
    required String blockType,
    required String content,
    this.metadata = const Value.absent(),
    required Uint8List sortKey,
    this.lamportClock = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       blockType = Value(blockType),
       content = Value(content),
       sortKey = Value(sortKey);
  static Insertable<ShuaDiaryBlock> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? blockType,
    Expression<String>? content,
    Expression<String>? metadata,
    Expression<Uint8List>? sortKey,
    Expression<int>? lamportClock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (blockType != null) 'block_type': blockType,
      if (content != null) 'content': content,
      if (metadata != null) 'metadata': metadata,
      if (sortKey != null) 'sort_key': sortKey,
      if (lamportClock != null) 'lamport_clock': lamportClock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShuaDiaryBlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? blockType,
    Value<String>? content,
    Value<String?>? metadata,
    Value<Uint8List>? sortKey,
    Value<int>? lamportClock,
    Value<int>? rowid,
  }) {
    return ShuaDiaryBlocksCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      blockType: blockType ?? this.blockType,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      sortKey: sortKey ?? this.sortKey,
      lamportClock: lamportClock ?? this.lamportClock,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (blockType.present) {
      map['block_type'] = Variable<String>(blockType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<Uint8List>(sortKey.value);
    }
    if (lamportClock.present) {
      map['lamport_clock'] = Variable<int>(lamportClock.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShuaDiaryBlocksCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('blockType: $blockType, ')
          ..write('content: $content, ')
          ..write('metadata: $metadata, ')
          ..write('sortKey: $sortKey, ')
          ..write('lamportClock: $lamportClock, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $ShuaSyncQueueTable shuaSyncQueue = $ShuaSyncQueueTable(this);
  late final $EpisodicMemoriesTable episodicMemories = $EpisodicMemoriesTable(
    this,
  );
  late final $ShuaDiaryEntriesTable shuaDiaryEntries = $ShuaDiaryEntriesTable(
    this,
  );
  late final $ShuaDiaryBlocksTable shuaDiaryBlocks = $ShuaDiaryBlocksTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    shuaSyncQueue,
    episodicMemories,
    shuaDiaryEntries,
    shuaDiaryBlocks,
  ];
}

typedef $$ShuaSyncQueueTableCreateCompanionBuilder =
    ShuaSyncQueueCompanion Function({
      Value<int> id,
      required int tableId,
      required String recordId,
      required int actionType,
      required Uint8List payload,
      required int logicalClock,
      required int createdAt,
    });
typedef $$ShuaSyncQueueTableUpdateCompanionBuilder =
    ShuaSyncQueueCompanion Function({
      Value<int> id,
      Value<int> tableId,
      Value<String> recordId,
      Value<int> actionType,
      Value<Uint8List> payload,
      Value<int> logicalClock,
      Value<int> createdAt,
    });

class $$ShuaSyncQueueTableFilterComposer
    extends Composer<_$LocalDatabase, $ShuaSyncQueueTable> {
  $$ShuaSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get logicalClock => $composableBuilder(
    column: $table.logicalClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShuaSyncQueueTableOrderingComposer
    extends Composer<_$LocalDatabase, $ShuaSyncQueueTable> {
  $$ShuaSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get logicalClock => $composableBuilder(
    column: $table.logicalClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShuaSyncQueueTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ShuaSyncQueueTable> {
  $$ShuaSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get logicalClock => $composableBuilder(
    column: $table.logicalClock,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ShuaSyncQueueTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ShuaSyncQueueTable,
          ShuaSyncQueueData,
          $$ShuaSyncQueueTableFilterComposer,
          $$ShuaSyncQueueTableOrderingComposer,
          $$ShuaSyncQueueTableAnnotationComposer,
          $$ShuaSyncQueueTableCreateCompanionBuilder,
          $$ShuaSyncQueueTableUpdateCompanionBuilder,
          (
            ShuaSyncQueueData,
            BaseReferences<
              _$LocalDatabase,
              $ShuaSyncQueueTable,
              ShuaSyncQueueData
            >,
          ),
          ShuaSyncQueueData,
          PrefetchHooks Function()
        > {
  $$ShuaSyncQueueTableTableManager(
    _$LocalDatabase db,
    $ShuaSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShuaSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShuaSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShuaSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tableId = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> actionType = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<int> logicalClock = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ShuaSyncQueueCompanion(
                id: id,
                tableId: tableId,
                recordId: recordId,
                actionType: actionType,
                payload: payload,
                logicalClock: logicalClock,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tableId,
                required String recordId,
                required int actionType,
                required Uint8List payload,
                required int logicalClock,
                required int createdAt,
              }) => ShuaSyncQueueCompanion.insert(
                id: id,
                tableId: tableId,
                recordId: recordId,
                actionType: actionType,
                payload: payload,
                logicalClock: logicalClock,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShuaSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ShuaSyncQueueTable,
      ShuaSyncQueueData,
      $$ShuaSyncQueueTableFilterComposer,
      $$ShuaSyncQueueTableOrderingComposer,
      $$ShuaSyncQueueTableAnnotationComposer,
      $$ShuaSyncQueueTableCreateCompanionBuilder,
      $$ShuaSyncQueueTableUpdateCompanionBuilder,
      (
        ShuaSyncQueueData,
        BaseReferences<_$LocalDatabase, $ShuaSyncQueueTable, ShuaSyncQueueData>,
      ),
      ShuaSyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$EpisodicMemoriesTableCreateCompanionBuilder =
    EpisodicMemoriesCompanion Function({
      required String id,
      required String userId,
      required String memoryContent,
      Value<int> priorityTier,
      Value<String> moodTag,
      Value<DateTime> createdAt,
      Value<String?> suggestedTags,
      Value<int> rowid,
    });
typedef $$EpisodicMemoriesTableUpdateCompanionBuilder =
    EpisodicMemoriesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> memoryContent,
      Value<int> priorityTier,
      Value<String> moodTag,
      Value<DateTime> createdAt,
      Value<String?> suggestedTags,
      Value<int> rowid,
    });

class $$EpisodicMemoriesTableFilterComposer
    extends Composer<_$LocalDatabase, $EpisodicMemoriesTable> {
  $$EpisodicMemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoryContent => $composableBuilder(
    column: $table.memoryContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priorityTier => $composableBuilder(
    column: $table.priorityTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moodTag => $composableBuilder(
    column: $table.moodTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestedTags => $composableBuilder(
    column: $table.suggestedTags,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodicMemoriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $EpisodicMemoriesTable> {
  $$EpisodicMemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoryContent => $composableBuilder(
    column: $table.memoryContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priorityTier => $composableBuilder(
    column: $table.priorityTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moodTag => $composableBuilder(
    column: $table.moodTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestedTags => $composableBuilder(
    column: $table.suggestedTags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodicMemoriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $EpisodicMemoriesTable> {
  $$EpisodicMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get memoryContent => $composableBuilder(
    column: $table.memoryContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priorityTier => $composableBuilder(
    column: $table.priorityTier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get moodTag =>
      $composableBuilder(column: $table.moodTag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get suggestedTags => $composableBuilder(
    column: $table.suggestedTags,
    builder: (column) => column,
  );
}

class $$EpisodicMemoriesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $EpisodicMemoriesTable,
          EpisodicMemory,
          $$EpisodicMemoriesTableFilterComposer,
          $$EpisodicMemoriesTableOrderingComposer,
          $$EpisodicMemoriesTableAnnotationComposer,
          $$EpisodicMemoriesTableCreateCompanionBuilder,
          $$EpisodicMemoriesTableUpdateCompanionBuilder,
          (
            EpisodicMemory,
            BaseReferences<
              _$LocalDatabase,
              $EpisodicMemoriesTable,
              EpisodicMemory
            >,
          ),
          EpisodicMemory,
          PrefetchHooks Function()
        > {
  $$EpisodicMemoriesTableTableManager(
    _$LocalDatabase db,
    $EpisodicMemoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodicMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodicMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodicMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> memoryContent = const Value.absent(),
                Value<int> priorityTier = const Value.absent(),
                Value<String> moodTag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> suggestedTags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodicMemoriesCompanion(
                id: id,
                userId: userId,
                memoryContent: memoryContent,
                priorityTier: priorityTier,
                moodTag: moodTag,
                createdAt: createdAt,
                suggestedTags: suggestedTags,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String memoryContent,
                Value<int> priorityTier = const Value.absent(),
                Value<String> moodTag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> suggestedTags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodicMemoriesCompanion.insert(
                id: id,
                userId: userId,
                memoryContent: memoryContent,
                priorityTier: priorityTier,
                moodTag: moodTag,
                createdAt: createdAt,
                suggestedTags: suggestedTags,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodicMemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $EpisodicMemoriesTable,
      EpisodicMemory,
      $$EpisodicMemoriesTableFilterComposer,
      $$EpisodicMemoriesTableOrderingComposer,
      $$EpisodicMemoriesTableAnnotationComposer,
      $$EpisodicMemoriesTableCreateCompanionBuilder,
      $$EpisodicMemoriesTableUpdateCompanionBuilder,
      (
        EpisodicMemory,
        BaseReferences<_$LocalDatabase, $EpisodicMemoriesTable, EpisodicMemory>,
      ),
      EpisodicMemory,
      PrefetchHooks Function()
    >;
typedef $$ShuaDiaryEntriesTableCreateCompanionBuilder =
    ShuaDiaryEntriesCompanion Function({
      required String id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<int> lamportClock,
      Value<String> privacyTag,
      Value<String> analysisState,
      Value<double?> sentimentScore,
      Value<String?> milestoneTag,
      Value<int> rowid,
    });
typedef $$ShuaDiaryEntriesTableUpdateCompanionBuilder =
    ShuaDiaryEntriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<int> lamportClock,
      Value<String> privacyTag,
      Value<String> analysisState,
      Value<double?> sentimentScore,
      Value<String?> milestoneTag,
      Value<int> rowid,
    });

class $$ShuaDiaryEntriesTableFilterComposer
    extends Composer<_$LocalDatabase, $ShuaDiaryEntriesTable> {
  $$ShuaDiaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamportClock => $composableBuilder(
    column: $table.lamportClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacyTag => $composableBuilder(
    column: $table.privacyTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analysisState => $composableBuilder(
    column: $table.analysisState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sentimentScore => $composableBuilder(
    column: $table.sentimentScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestoneTag => $composableBuilder(
    column: $table.milestoneTag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShuaDiaryEntriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $ShuaDiaryEntriesTable> {
  $$ShuaDiaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamportClock => $composableBuilder(
    column: $table.lamportClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacyTag => $composableBuilder(
    column: $table.privacyTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analysisState => $composableBuilder(
    column: $table.analysisState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sentimentScore => $composableBuilder(
    column: $table.sentimentScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestoneTag => $composableBuilder(
    column: $table.milestoneTag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShuaDiaryEntriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ShuaDiaryEntriesTable> {
  $$ShuaDiaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lamportClock => $composableBuilder(
    column: $table.lamportClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privacyTag => $composableBuilder(
    column: $table.privacyTag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get analysisState => $composableBuilder(
    column: $table.analysisState,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sentimentScore => $composableBuilder(
    column: $table.sentimentScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get milestoneTag => $composableBuilder(
    column: $table.milestoneTag,
    builder: (column) => column,
  );
}

class $$ShuaDiaryEntriesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ShuaDiaryEntriesTable,
          ShuaDiaryEntry,
          $$ShuaDiaryEntriesTableFilterComposer,
          $$ShuaDiaryEntriesTableOrderingComposer,
          $$ShuaDiaryEntriesTableAnnotationComposer,
          $$ShuaDiaryEntriesTableCreateCompanionBuilder,
          $$ShuaDiaryEntriesTableUpdateCompanionBuilder,
          (
            ShuaDiaryEntry,
            BaseReferences<
              _$LocalDatabase,
              $ShuaDiaryEntriesTable,
              ShuaDiaryEntry
            >,
          ),
          ShuaDiaryEntry,
          PrefetchHooks Function()
        > {
  $$ShuaDiaryEntriesTableTableManager(
    _$LocalDatabase db,
    $ShuaDiaryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShuaDiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShuaDiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShuaDiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> lamportClock = const Value.absent(),
                Value<String> privacyTag = const Value.absent(),
                Value<String> analysisState = const Value.absent(),
                Value<double?> sentimentScore = const Value.absent(),
                Value<String?> milestoneTag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShuaDiaryEntriesCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                lamportClock: lamportClock,
                privacyTag: privacyTag,
                analysisState: analysisState,
                sentimentScore: sentimentScore,
                milestoneTag: milestoneTag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> lamportClock = const Value.absent(),
                Value<String> privacyTag = const Value.absent(),
                Value<String> analysisState = const Value.absent(),
                Value<double?> sentimentScore = const Value.absent(),
                Value<String?> milestoneTag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShuaDiaryEntriesCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                lamportClock: lamportClock,
                privacyTag: privacyTag,
                analysisState: analysisState,
                sentimentScore: sentimentScore,
                milestoneTag: milestoneTag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShuaDiaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ShuaDiaryEntriesTable,
      ShuaDiaryEntry,
      $$ShuaDiaryEntriesTableFilterComposer,
      $$ShuaDiaryEntriesTableOrderingComposer,
      $$ShuaDiaryEntriesTableAnnotationComposer,
      $$ShuaDiaryEntriesTableCreateCompanionBuilder,
      $$ShuaDiaryEntriesTableUpdateCompanionBuilder,
      (
        ShuaDiaryEntry,
        BaseReferences<_$LocalDatabase, $ShuaDiaryEntriesTable, ShuaDiaryEntry>,
      ),
      ShuaDiaryEntry,
      PrefetchHooks Function()
    >;
typedef $$ShuaDiaryBlocksTableCreateCompanionBuilder =
    ShuaDiaryBlocksCompanion Function({
      required String id,
      required String entryId,
      required String blockType,
      required String content,
      Value<String?> metadata,
      required Uint8List sortKey,
      Value<int> lamportClock,
      Value<int> rowid,
    });
typedef $$ShuaDiaryBlocksTableUpdateCompanionBuilder =
    ShuaDiaryBlocksCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<String> blockType,
      Value<String> content,
      Value<String?> metadata,
      Value<Uint8List> sortKey,
      Value<int> lamportClock,
      Value<int> rowid,
    });

class $$ShuaDiaryBlocksTableFilterComposer
    extends Composer<_$LocalDatabase, $ShuaDiaryBlocksTable> {
  $$ShuaDiaryBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockType => $composableBuilder(
    column: $table.blockType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamportClock => $composableBuilder(
    column: $table.lamportClock,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShuaDiaryBlocksTableOrderingComposer
    extends Composer<_$LocalDatabase, $ShuaDiaryBlocksTable> {
  $$ShuaDiaryBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockType => $composableBuilder(
    column: $table.blockType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamportClock => $composableBuilder(
    column: $table.lamportClock,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShuaDiaryBlocksTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ShuaDiaryBlocksTable> {
  $$ShuaDiaryBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get blockType =>
      $composableBuilder(column: $table.blockType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<Uint8List> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<int> get lamportClock => $composableBuilder(
    column: $table.lamportClock,
    builder: (column) => column,
  );
}

class $$ShuaDiaryBlocksTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ShuaDiaryBlocksTable,
          ShuaDiaryBlock,
          $$ShuaDiaryBlocksTableFilterComposer,
          $$ShuaDiaryBlocksTableOrderingComposer,
          $$ShuaDiaryBlocksTableAnnotationComposer,
          $$ShuaDiaryBlocksTableCreateCompanionBuilder,
          $$ShuaDiaryBlocksTableUpdateCompanionBuilder,
          (
            ShuaDiaryBlock,
            BaseReferences<
              _$LocalDatabase,
              $ShuaDiaryBlocksTable,
              ShuaDiaryBlock
            >,
          ),
          ShuaDiaryBlock,
          PrefetchHooks Function()
        > {
  $$ShuaDiaryBlocksTableTableManager(
    _$LocalDatabase db,
    $ShuaDiaryBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShuaDiaryBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShuaDiaryBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShuaDiaryBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> blockType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<Uint8List> sortKey = const Value.absent(),
                Value<int> lamportClock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShuaDiaryBlocksCompanion(
                id: id,
                entryId: entryId,
                blockType: blockType,
                content: content,
                metadata: metadata,
                sortKey: sortKey,
                lamportClock: lamportClock,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required String blockType,
                required String content,
                Value<String?> metadata = const Value.absent(),
                required Uint8List sortKey,
                Value<int> lamportClock = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShuaDiaryBlocksCompanion.insert(
                id: id,
                entryId: entryId,
                blockType: blockType,
                content: content,
                metadata: metadata,
                sortKey: sortKey,
                lamportClock: lamportClock,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShuaDiaryBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ShuaDiaryBlocksTable,
      ShuaDiaryBlock,
      $$ShuaDiaryBlocksTableFilterComposer,
      $$ShuaDiaryBlocksTableOrderingComposer,
      $$ShuaDiaryBlocksTableAnnotationComposer,
      $$ShuaDiaryBlocksTableCreateCompanionBuilder,
      $$ShuaDiaryBlocksTableUpdateCompanionBuilder,
      (
        ShuaDiaryBlock,
        BaseReferences<_$LocalDatabase, $ShuaDiaryBlocksTable, ShuaDiaryBlock>,
      ),
      ShuaDiaryBlock,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$ShuaSyncQueueTableTableManager get shuaSyncQueue =>
      $$ShuaSyncQueueTableTableManager(_db, _db.shuaSyncQueue);
  $$EpisodicMemoriesTableTableManager get episodicMemories =>
      $$EpisodicMemoriesTableTableManager(_db, _db.episodicMemories);
  $$ShuaDiaryEntriesTableTableManager get shuaDiaryEntries =>
      $$ShuaDiaryEntriesTableTableManager(_db, _db.shuaDiaryEntries);
  $$ShuaDiaryBlocksTableTableManager get shuaDiaryBlocks =>
      $$ShuaDiaryBlocksTableTableManager(_db, _db.shuaDiaryBlocks);
}
