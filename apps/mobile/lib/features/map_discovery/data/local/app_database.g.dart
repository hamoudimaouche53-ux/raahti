// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedPlacesTable extends CachedPlaces
    with TableInfo<$CachedPlacesTable, CachedPlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeKindMeta = const VerificationMeta(
    'placeKind',
  );
  @override
  late final GeneratedColumn<String> placeKind = GeneratedColumn<String>(
    'place_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinColorMeta = const VerificationMeta(
    'pinColor',
  );
  @override
  late final GeneratedColumn<String> pinColor = GeneratedColumn<String>(
    'pin_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageRatingMeta = const VerificationMeta(
    'averageRating',
  );
  @override
  late final GeneratedColumn<double> averageRating = GeneratedColumn<double>(
    'average_rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFreeMeta = const VerificationMeta('isFree');
  @override
  late final GeneratedColumn<bool> isFree = GeneratedColumn<bool>(
    'is_free',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_free" IN (0, 1))',
    ),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    placeKind,
    nameFr,
    nameAr,
    nameEn,
    latitude,
    longitude,
    pinColor,
    distanceMeters,
    averageRating,
    reviewCount,
    isFree,
    tags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPlace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('place_kind')) {
      context.handle(
        _placeKindMeta,
        placeKind.isAcceptableOrUnknown(data['place_kind']!, _placeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_placeKindMeta);
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameFrMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('pin_color')) {
      context.handle(
        _pinColorMeta,
        pinColor.isAcceptableOrUnknown(data['pin_color']!, _pinColorMeta),
      );
    } else if (isInserting) {
      context.missing(_pinColorMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('average_rating')) {
      context.handle(
        _averageRatingMeta,
        averageRating.isAcceptableOrUnknown(
          data['average_rating']!,
          _averageRatingMeta,
        ),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewCountMeta);
    }
    if (data.containsKey('is_free')) {
      context.handle(
        _isFreeMeta,
        isFree.isAcceptableOrUnknown(data['is_free']!, _isFreeMeta),
      );
    } else if (isInserting) {
      context.missing(_isFreeMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPlace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      placeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_kind'],
      )!,
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      pinColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_color'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      averageRating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_rating'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      isFree: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_free'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
    );
  }

  @override
  $CachedPlacesTable createAlias(String alias) {
    return $CachedPlacesTable(attachedDatabase, alias);
  }
}

class CachedPlace extends DataClass implements Insertable<CachedPlace> {
  final String id;
  final String placeKind;
  final String nameFr;
  final String nameAr;
  final String nameEn;
  final double latitude;
  final double longitude;
  final String pinColor;
  final double distanceMeters;
  final double? averageRating;
  final int reviewCount;
  final bool isFree;
  final String tags;
  const CachedPlace({
    required this.id,
    required this.placeKind,
    required this.nameFr,
    required this.nameAr,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
    required this.pinColor,
    required this.distanceMeters,
    this.averageRating,
    required this.reviewCount,
    required this.isFree,
    required this.tags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['place_kind'] = Variable<String>(placeKind);
    map['name_fr'] = Variable<String>(nameFr);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['pin_color'] = Variable<String>(pinColor);
    map['distance_meters'] = Variable<double>(distanceMeters);
    if (!nullToAbsent || averageRating != null) {
      map['average_rating'] = Variable<double>(averageRating);
    }
    map['review_count'] = Variable<int>(reviewCount);
    map['is_free'] = Variable<bool>(isFree);
    map['tags'] = Variable<String>(tags);
    return map;
  }

  CachedPlacesCompanion toCompanion(bool nullToAbsent) {
    return CachedPlacesCompanion(
      id: Value(id),
      placeKind: Value(placeKind),
      nameFr: Value(nameFr),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      latitude: Value(latitude),
      longitude: Value(longitude),
      pinColor: Value(pinColor),
      distanceMeters: Value(distanceMeters),
      averageRating: averageRating == null && nullToAbsent
          ? const Value.absent()
          : Value(averageRating),
      reviewCount: Value(reviewCount),
      isFree: Value(isFree),
      tags: Value(tags),
    );
  }

  factory CachedPlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPlace(
      id: serializer.fromJson<String>(json['id']),
      placeKind: serializer.fromJson<String>(json['placeKind']),
      nameFr: serializer.fromJson<String>(json['nameFr']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      pinColor: serializer.fromJson<String>(json['pinColor']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      averageRating: serializer.fromJson<double?>(json['averageRating']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      isFree: serializer.fromJson<bool>(json['isFree']),
      tags: serializer.fromJson<String>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'placeKind': serializer.toJson<String>(placeKind),
      'nameFr': serializer.toJson<String>(nameFr),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'pinColor': serializer.toJson<String>(pinColor),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'averageRating': serializer.toJson<double?>(averageRating),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'isFree': serializer.toJson<bool>(isFree),
      'tags': serializer.toJson<String>(tags),
    };
  }

  CachedPlace copyWith({
    String? id,
    String? placeKind,
    String? nameFr,
    String? nameAr,
    String? nameEn,
    double? latitude,
    double? longitude,
    String? pinColor,
    double? distanceMeters,
    Value<double?> averageRating = const Value.absent(),
    int? reviewCount,
    bool? isFree,
    String? tags,
  }) => CachedPlace(
    id: id ?? this.id,
    placeKind: placeKind ?? this.placeKind,
    nameFr: nameFr ?? this.nameFr,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    pinColor: pinColor ?? this.pinColor,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    averageRating: averageRating.present
        ? averageRating.value
        : this.averageRating,
    reviewCount: reviewCount ?? this.reviewCount,
    isFree: isFree ?? this.isFree,
    tags: tags ?? this.tags,
  );
  CachedPlace copyWithCompanion(CachedPlacesCompanion data) {
    return CachedPlace(
      id: data.id.present ? data.id.value : this.id,
      placeKind: data.placeKind.present ? data.placeKind.value : this.placeKind,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      pinColor: data.pinColor.present ? data.pinColor.value : this.pinColor,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      averageRating: data.averageRating.present
          ? data.averageRating.value
          : this.averageRating,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      isFree: data.isFree.present ? data.isFree.value : this.isFree,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlace(')
          ..write('id: $id, ')
          ..write('placeKind: $placeKind, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('pinColor: $pinColor, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('averageRating: $averageRating, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('isFree: $isFree, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    placeKind,
    nameFr,
    nameAr,
    nameEn,
    latitude,
    longitude,
    pinColor,
    distanceMeters,
    averageRating,
    reviewCount,
    isFree,
    tags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPlace &&
          other.id == this.id &&
          other.placeKind == this.placeKind &&
          other.nameFr == this.nameFr &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.pinColor == this.pinColor &&
          other.distanceMeters == this.distanceMeters &&
          other.averageRating == this.averageRating &&
          other.reviewCount == this.reviewCount &&
          other.isFree == this.isFree &&
          other.tags == this.tags);
}

class CachedPlacesCompanion extends UpdateCompanion<CachedPlace> {
  final Value<String> id;
  final Value<String> placeKind;
  final Value<String> nameFr;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> pinColor;
  final Value<double> distanceMeters;
  final Value<double?> averageRating;
  final Value<int> reviewCount;
  final Value<bool> isFree;
  final Value<String> tags;
  final Value<int> rowid;
  const CachedPlacesCompanion({
    this.id = const Value.absent(),
    this.placeKind = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.pinColor = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.averageRating = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.isFree = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPlacesCompanion.insert({
    required String id,
    required String placeKind,
    required String nameFr,
    required String nameAr,
    required String nameEn,
    required double latitude,
    required double longitude,
    required String pinColor,
    required double distanceMeters,
    this.averageRating = const Value.absent(),
    required int reviewCount,
    required bool isFree,
    required String tags,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       placeKind = Value(placeKind),
       nameFr = Value(nameFr),
       nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       latitude = Value(latitude),
       longitude = Value(longitude),
       pinColor = Value(pinColor),
       distanceMeters = Value(distanceMeters),
       reviewCount = Value(reviewCount),
       isFree = Value(isFree),
       tags = Value(tags);
  static Insertable<CachedPlace> custom({
    Expression<String>? id,
    Expression<String>? placeKind,
    Expression<String>? nameFr,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? pinColor,
    Expression<double>? distanceMeters,
    Expression<double>? averageRating,
    Expression<int>? reviewCount,
    Expression<bool>? isFree,
    Expression<String>? tags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeKind != null) 'place_kind': placeKind,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (pinColor != null) 'pin_color': pinColor,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (averageRating != null) 'average_rating': averageRating,
      if (reviewCount != null) 'review_count': reviewCount,
      if (isFree != null) 'is_free': isFree,
      if (tags != null) 'tags': tags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? placeKind,
    Value<String>? nameFr,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? pinColor,
    Value<double>? distanceMeters,
    Value<double?>? averageRating,
    Value<int>? reviewCount,
    Value<bool>? isFree,
    Value<String>? tags,
    Value<int>? rowid,
  }) {
    return CachedPlacesCompanion(
      id: id ?? this.id,
      placeKind: placeKind ?? this.placeKind,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pinColor: pinColor ?? this.pinColor,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFree: isFree ?? this.isFree,
      tags: tags ?? this.tags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (placeKind.present) {
      map['place_kind'] = Variable<String>(placeKind.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (pinColor.present) {
      map['pin_color'] = Variable<String>(pinColor.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (averageRating.present) {
      map['average_rating'] = Variable<double>(averageRating.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (isFree.present) {
      map['is_free'] = Variable<bool>(isFree.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlacesCompanion(')
          ..write('id: $id, ')
          ..write('placeKind: $placeKind, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('pinColor: $pinColor, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('averageRating: $averageRating, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('isFree: $isFree, ')
          ..write('tags: $tags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheMetaTable extends CacheMeta
    with TableInfo<$CacheMetaTable, CacheMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $CacheMetaTable createAlias(String alias) {
    return $CacheMetaTable(attachedDatabase, alias);
  }
}

class CacheMetaData extends DataClass implements Insertable<CacheMetaData> {
  final int id;
  final DateTime lastSyncedAt;
  const CacheMetaData({required this.id, required this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  CacheMetaCompanion toCompanion(bool nullToAbsent) {
    return CacheMetaCompanion(id: Value(id), lastSyncedAt: Value(lastSyncedAt));
  }

  factory CacheMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetaData(
      id: serializer.fromJson<int>(json['id']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  CacheMetaData copyWith({int? id, DateTime? lastSyncedAt}) => CacheMetaData(
    id: id ?? this.id,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
  CacheMetaData copyWithCompanion(CacheMetaCompanion data) {
    return CacheMetaData(
      id: data.id.present ? data.id.value : this.id,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetaData(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetaData &&
          other.id == this.id &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CacheMetaCompanion extends UpdateCompanion<CacheMetaData> {
  final Value<int> id;
  final Value<DateTime> lastSyncedAt;
  const CacheMetaCompanion({
    this.id = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  CacheMetaCompanion.insert({
    this.id = const Value.absent(),
    required DateTime lastSyncedAt,
  }) : lastSyncedAt = Value(lastSyncedAt);
  static Insertable<CacheMetaData> custom({
    Expression<int>? id,
    Expression<DateTime>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  CacheMetaCompanion copyWith({Value<int>? id, Value<DateTime>? lastSyncedAt}) {
    return CacheMetaCompanion(
      id: id ?? this.id,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetaCompanion(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedPlacesTable cachedPlaces = $CachedPlacesTable(this);
  late final $CacheMetaTable cacheMeta = $CacheMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedPlaces, cacheMeta];
}

typedef $$CachedPlacesTableCreateCompanionBuilder =
    CachedPlacesCompanion Function({
      required String id,
      required String placeKind,
      required String nameFr,
      required String nameAr,
      required String nameEn,
      required double latitude,
      required double longitude,
      required String pinColor,
      required double distanceMeters,
      Value<double?> averageRating,
      required int reviewCount,
      required bool isFree,
      required String tags,
      Value<int> rowid,
    });
typedef $$CachedPlacesTableUpdateCompanionBuilder =
    CachedPlacesCompanion Function({
      Value<String> id,
      Value<String> placeKind,
      Value<String> nameFr,
      Value<String> nameAr,
      Value<String> nameEn,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> pinColor,
      Value<double> distanceMeters,
      Value<double?> averageRating,
      Value<int> reviewCount,
      Value<bool> isFree,
      Value<String> tags,
      Value<int> rowid,
    });

class $$CachedPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPlacesTable> {
  $$CachedPlacesTableFilterComposer({
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

  ColumnFilters<String> get placeKind => $composableBuilder(
    column: $table.placeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinColor => $composableBuilder(
    column: $table.pinColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFree => $composableBuilder(
    column: $table.isFree,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPlacesTable> {
  $$CachedPlacesTableOrderingComposer({
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

  ColumnOrderings<String> get placeKind => $composableBuilder(
    column: $table.placeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinColor => $composableBuilder(
    column: $table.pinColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFree => $composableBuilder(
    column: $table.isFree,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPlacesTable> {
  $$CachedPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get placeKind =>
      $composableBuilder(column: $table.placeKind, builder: (column) => column);

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get pinColor =>
      $composableBuilder(column: $table.pinColor, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageRating => $composableBuilder(
    column: $table.averageRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFree =>
      $composableBuilder(column: $table.isFree, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);
}

class $$CachedPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPlacesTable,
          CachedPlace,
          $$CachedPlacesTableFilterComposer,
          $$CachedPlacesTableOrderingComposer,
          $$CachedPlacesTableAnnotationComposer,
          $$CachedPlacesTableCreateCompanionBuilder,
          $$CachedPlacesTableUpdateCompanionBuilder,
          (
            CachedPlace,
            BaseReferences<_$AppDatabase, $CachedPlacesTable, CachedPlace>,
          ),
          CachedPlace,
          PrefetchHooks Function()
        > {
  $$CachedPlacesTableTableManager(_$AppDatabase db, $CachedPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> placeKind = const Value.absent(),
                Value<String> nameFr = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> pinColor = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double?> averageRating = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<bool> isFree = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPlacesCompanion(
                id: id,
                placeKind: placeKind,
                nameFr: nameFr,
                nameAr: nameAr,
                nameEn: nameEn,
                latitude: latitude,
                longitude: longitude,
                pinColor: pinColor,
                distanceMeters: distanceMeters,
                averageRating: averageRating,
                reviewCount: reviewCount,
                isFree: isFree,
                tags: tags,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String placeKind,
                required String nameFr,
                required String nameAr,
                required String nameEn,
                required double latitude,
                required double longitude,
                required String pinColor,
                required double distanceMeters,
                Value<double?> averageRating = const Value.absent(),
                required int reviewCount,
                required bool isFree,
                required String tags,
                Value<int> rowid = const Value.absent(),
              }) => CachedPlacesCompanion.insert(
                id: id,
                placeKind: placeKind,
                nameFr: nameFr,
                nameAr: nameAr,
                nameEn: nameEn,
                latitude: latitude,
                longitude: longitude,
                pinColor: pinColor,
                distanceMeters: distanceMeters,
                averageRating: averageRating,
                reviewCount: reviewCount,
                isFree: isFree,
                tags: tags,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPlacesTable,
      CachedPlace,
      $$CachedPlacesTableFilterComposer,
      $$CachedPlacesTableOrderingComposer,
      $$CachedPlacesTableAnnotationComposer,
      $$CachedPlacesTableCreateCompanionBuilder,
      $$CachedPlacesTableUpdateCompanionBuilder,
      (
        CachedPlace,
        BaseReferences<_$AppDatabase, $CachedPlacesTable, CachedPlace>,
      ),
      CachedPlace,
      PrefetchHooks Function()
    >;
typedef $$CacheMetaTableCreateCompanionBuilder =
    CacheMetaCompanion Function({
      Value<int> id,
      required DateTime lastSyncedAt,
    });
typedef $$CacheMetaTableUpdateCompanionBuilder =
    CacheMetaCompanion Function({Value<int> id, Value<DateTime> lastSyncedAt});

class $$CacheMetaTableFilterComposer
    extends Composer<_$AppDatabase, $CacheMetaTable> {
  $$CacheMetaTableFilterComposer({
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

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheMetaTable> {
  $$CacheMetaTableOrderingComposer({
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

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheMetaTable> {
  $$CacheMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CacheMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheMetaTable,
          CacheMetaData,
          $$CacheMetaTableFilterComposer,
          $$CacheMetaTableOrderingComposer,
          $$CacheMetaTableAnnotationComposer,
          $$CacheMetaTableCreateCompanionBuilder,
          $$CacheMetaTableUpdateCompanionBuilder,
          (
            CacheMetaData,
            BaseReferences<_$AppDatabase, $CacheMetaTable, CacheMetaData>,
          ),
          CacheMetaData,
          PrefetchHooks Function()
        > {
  $$CacheMetaTableTableManager(_$AppDatabase db, $CacheMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
              }) => CacheMetaCompanion(id: id, lastSyncedAt: lastSyncedAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime lastSyncedAt,
              }) =>
                  CacheMetaCompanion.insert(id: id, lastSyncedAt: lastSyncedAt),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheMetaTable,
      CacheMetaData,
      $$CacheMetaTableFilterComposer,
      $$CacheMetaTableOrderingComposer,
      $$CacheMetaTableAnnotationComposer,
      $$CacheMetaTableCreateCompanionBuilder,
      $$CacheMetaTableUpdateCompanionBuilder,
      (
        CacheMetaData,
        BaseReferences<_$AppDatabase, $CacheMetaTable, CacheMetaData>,
      ),
      CacheMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedPlacesTableTableManager get cachedPlaces =>
      $$CachedPlacesTableTableManager(_db, _db.cachedPlaces);
  $$CacheMetaTableTableManager get cacheMeta =>
      $$CacheMetaTableTableManager(_db, _db.cacheMeta);
}
