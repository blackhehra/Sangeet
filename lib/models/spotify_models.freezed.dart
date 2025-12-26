// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spotify_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SpotifyImage _$SpotifyImageFromJson(Map<String, dynamic> json) {
  return _SpotifyImage.fromJson(json);
}

/// @nodoc
mixin _$SpotifyImage {
  String get url => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;

  /// Serializes this SpotifyImage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyImageCopyWith<SpotifyImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyImageCopyWith<$Res> {
  factory $SpotifyImageCopyWith(
    SpotifyImage value,
    $Res Function(SpotifyImage) then,
  ) = _$SpotifyImageCopyWithImpl<$Res, SpotifyImage>;
  @useResult
  $Res call({String url, int? width, int? height});
}

/// @nodoc
class _$SpotifyImageCopyWithImpl<$Res, $Val extends SpotifyImage>
    implements $SpotifyImageCopyWith<$Res> {
  _$SpotifyImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? width = freezed,
    Object? height = freezed,
  }) {
    return _then(
      _value.copyWith(
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            width: freezed == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int?,
            height: freezed == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifyImageImplCopyWith<$Res>
    implements $SpotifyImageCopyWith<$Res> {
  factory _$$SpotifyImageImplCopyWith(
    _$SpotifyImageImpl value,
    $Res Function(_$SpotifyImageImpl) then,
  ) = __$$SpotifyImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String url, int? width, int? height});
}

/// @nodoc
class __$$SpotifyImageImplCopyWithImpl<$Res>
    extends _$SpotifyImageCopyWithImpl<$Res, _$SpotifyImageImpl>
    implements _$$SpotifyImageImplCopyWith<$Res> {
  __$$SpotifyImageImplCopyWithImpl(
    _$SpotifyImageImpl _value,
    $Res Function(_$SpotifyImageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? width = freezed,
    Object? height = freezed,
  }) {
    return _then(
      _$SpotifyImageImpl(
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        width: freezed == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int?,
        height: freezed == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifyImageImpl implements _SpotifyImage {
  _$SpotifyImageImpl({required this.url, this.width, this.height});

  factory _$SpotifyImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifyImageImplFromJson(json);

  @override
  final String url;
  @override
  final int? width;
  @override
  final int? height;

  @override
  String toString() {
    return 'SpotifyImage(url: $url, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyImageImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url, width, height);

  /// Create a copy of SpotifyImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyImageImplCopyWith<_$SpotifyImageImpl> get copyWith =>
      __$$SpotifyImageImplCopyWithImpl<_$SpotifyImageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifyImageImplToJson(this);
  }
}

abstract class _SpotifyImage implements SpotifyImage {
  factory _SpotifyImage({
    required final String url,
    final int? width,
    final int? height,
  }) = _$SpotifyImageImpl;

  factory _SpotifyImage.fromJson(Map<String, dynamic> json) =
      _$SpotifyImageImpl.fromJson;

  @override
  String get url;
  @override
  int? get width;
  @override
  int? get height;

  /// Create a copy of SpotifyImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyImageImplCopyWith<_$SpotifyImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifyUser _$SpotifyUserFromJson(Map<String, dynamic> json) {
  return _SpotifyUser.fromJson(json);
}

/// @nodoc
mixin _$SpotifyUser {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<SpotifyImage> get images => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;

  /// Serializes this SpotifyUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyUserCopyWith<SpotifyUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyUserCopyWith<$Res> {
  factory $SpotifyUserCopyWith(
    SpotifyUser value,
    $Res Function(SpotifyUser) then,
  ) = _$SpotifyUserCopyWithImpl<$Res, SpotifyUser>;
  @useResult
  $Res call({
    String id,
    String name,
    List<SpotifyImage> images,
    String externalUri,
  });
}

/// @nodoc
class _$SpotifyUserCopyWithImpl<$Res, $Val extends SpotifyUser>
    implements $SpotifyUserCopyWith<$Res> {
  _$SpotifyUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? images = null,
    Object? externalUri = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifyUserImplCopyWith<$Res>
    implements $SpotifyUserCopyWith<$Res> {
  factory _$$SpotifyUserImplCopyWith(
    _$SpotifyUserImpl value,
    $Res Function(_$SpotifyUserImpl) then,
  ) = __$$SpotifyUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    List<SpotifyImage> images,
    String externalUri,
  });
}

/// @nodoc
class __$$SpotifyUserImplCopyWithImpl<$Res>
    extends _$SpotifyUserCopyWithImpl<$Res, _$SpotifyUserImpl>
    implements _$$SpotifyUserImplCopyWith<$Res> {
  __$$SpotifyUserImplCopyWithImpl(
    _$SpotifyUserImpl _value,
    $Res Function(_$SpotifyUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? images = null,
    Object? externalUri = null,
  }) {
    return _then(
      _$SpotifyUserImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifyUserImpl implements _SpotifyUser {
  _$SpotifyUserImpl({
    required this.id,
    required this.name,
    final List<SpotifyImage> images = const [],
    required this.externalUri,
  }) : _images = images;

  factory _$SpotifyUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifyUserImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<SpotifyImage> _images;
  @override
  @JsonKey()
  List<SpotifyImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final String externalUri;

  @override
  String toString() {
    return 'SpotifyUser(id: $id, name: $name, images: $images, externalUri: $externalUri)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_images),
    externalUri,
  );

  /// Create a copy of SpotifyUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyUserImplCopyWith<_$SpotifyUserImpl> get copyWith =>
      __$$SpotifyUserImplCopyWithImpl<_$SpotifyUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifyUserImplToJson(this);
  }
}

abstract class _SpotifyUser implements SpotifyUser {
  factory _SpotifyUser({
    required final String id,
    required final String name,
    final List<SpotifyImage> images,
    required final String externalUri,
  }) = _$SpotifyUserImpl;

  factory _SpotifyUser.fromJson(Map<String, dynamic> json) =
      _$SpotifyUserImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<SpotifyImage> get images;
  @override
  String get externalUri;

  /// Create a copy of SpotifyUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyUserImplCopyWith<_$SpotifyUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifyArtist _$SpotifyArtistFromJson(Map<String, dynamic> json) {
  return _SpotifyArtist.fromJson(json);
}

/// @nodoc
mixin _$SpotifyArtist {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  List<SpotifyImage>? get images => throw _privateConstructorUsedError;
  List<String>? get genres => throw _privateConstructorUsedError;
  int? get followers => throw _privateConstructorUsedError;

  /// Serializes this SpotifyArtist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyArtist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyArtistCopyWith<SpotifyArtist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyArtistCopyWith<$Res> {
  factory $SpotifyArtistCopyWith(
    SpotifyArtist value,
    $Res Function(SpotifyArtist) then,
  ) = _$SpotifyArtistCopyWithImpl<$Res, SpotifyArtist>;
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifyImage>? images,
    List<String>? genres,
    int? followers,
  });
}

/// @nodoc
class _$SpotifyArtistCopyWithImpl<$Res, $Val extends SpotifyArtist>
    implements $SpotifyArtistCopyWith<$Res> {
  _$SpotifyArtistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyArtist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? images = freezed,
    Object? genres = freezed,
    Object? followers = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            images: freezed == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>?,
            genres: freezed == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            followers: freezed == followers
                ? _value.followers
                : followers // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifyArtistImplCopyWith<$Res>
    implements $SpotifyArtistCopyWith<$Res> {
  factory _$$SpotifyArtistImplCopyWith(
    _$SpotifyArtistImpl value,
    $Res Function(_$SpotifyArtistImpl) then,
  ) = __$$SpotifyArtistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifyImage>? images,
    List<String>? genres,
    int? followers,
  });
}

/// @nodoc
class __$$SpotifyArtistImplCopyWithImpl<$Res>
    extends _$SpotifyArtistCopyWithImpl<$Res, _$SpotifyArtistImpl>
    implements _$$SpotifyArtistImplCopyWith<$Res> {
  __$$SpotifyArtistImplCopyWithImpl(
    _$SpotifyArtistImpl _value,
    $Res Function(_$SpotifyArtistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyArtist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? images = freezed,
    Object? genres = freezed,
    Object? followers = freezed,
  }) {
    return _then(
      _$SpotifyArtistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        images: freezed == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>?,
        genres: freezed == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        followers: freezed == followers
            ? _value.followers
            : followers // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifyArtistImpl implements _SpotifyArtist {
  _$SpotifyArtistImpl({
    required this.id,
    required this.name,
    required this.externalUri,
    final List<SpotifyImage>? images,
    final List<String>? genres,
    this.followers,
  }) : _images = images,
       _genres = genres;

  factory _$SpotifyArtistImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifyArtistImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String externalUri;
  final List<SpotifyImage>? _images;
  @override
  List<SpotifyImage>? get images {
    final value = _images;
    if (value == null) return null;
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _genres;
  @override
  List<String>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? followers;

  @override
  String toString() {
    return 'SpotifyArtist(id: $id, name: $name, externalUri: $externalUri, images: $images, genres: $genres, followers: $followers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyArtistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.followers, followers) ||
                other.followers == followers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    externalUri,
    const DeepCollectionEquality().hash(_images),
    const DeepCollectionEquality().hash(_genres),
    followers,
  );

  /// Create a copy of SpotifyArtist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyArtistImplCopyWith<_$SpotifyArtistImpl> get copyWith =>
      __$$SpotifyArtistImplCopyWithImpl<_$SpotifyArtistImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifyArtistImplToJson(this);
  }
}

abstract class _SpotifyArtist implements SpotifyArtist {
  factory _SpotifyArtist({
    required final String id,
    required final String name,
    required final String externalUri,
    final List<SpotifyImage>? images,
    final List<String>? genres,
    final int? followers,
  }) = _$SpotifyArtistImpl;

  factory _SpotifyArtist.fromJson(Map<String, dynamic> json) =
      _$SpotifyArtistImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get externalUri;
  @override
  List<SpotifyImage>? get images;
  @override
  List<String>? get genres;
  @override
  int? get followers;

  /// Create a copy of SpotifyArtist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyArtistImplCopyWith<_$SpotifyArtistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifySimpleArtist _$SpotifySimpleArtistFromJson(Map<String, dynamic> json) {
  return _SpotifySimpleArtist.fromJson(json);
}

/// @nodoc
mixin _$SpotifySimpleArtist {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  List<SpotifyImage>? get images => throw _privateConstructorUsedError;

  /// Serializes this SpotifySimpleArtist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifySimpleArtist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifySimpleArtistCopyWith<SpotifySimpleArtist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifySimpleArtistCopyWith<$Res> {
  factory $SpotifySimpleArtistCopyWith(
    SpotifySimpleArtist value,
    $Res Function(SpotifySimpleArtist) then,
  ) = _$SpotifySimpleArtistCopyWithImpl<$Res, SpotifySimpleArtist>;
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifyImage>? images,
  });
}

/// @nodoc
class _$SpotifySimpleArtistCopyWithImpl<$Res, $Val extends SpotifySimpleArtist>
    implements $SpotifySimpleArtistCopyWith<$Res> {
  _$SpotifySimpleArtistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifySimpleArtist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? images = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            images: freezed == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifySimpleArtistImplCopyWith<$Res>
    implements $SpotifySimpleArtistCopyWith<$Res> {
  factory _$$SpotifySimpleArtistImplCopyWith(
    _$SpotifySimpleArtistImpl value,
    $Res Function(_$SpotifySimpleArtistImpl) then,
  ) = __$$SpotifySimpleArtistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifyImage>? images,
  });
}

/// @nodoc
class __$$SpotifySimpleArtistImplCopyWithImpl<$Res>
    extends _$SpotifySimpleArtistCopyWithImpl<$Res, _$SpotifySimpleArtistImpl>
    implements _$$SpotifySimpleArtistImplCopyWith<$Res> {
  __$$SpotifySimpleArtistImplCopyWithImpl(
    _$SpotifySimpleArtistImpl _value,
    $Res Function(_$SpotifySimpleArtistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifySimpleArtist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? images = freezed,
  }) {
    return _then(
      _$SpotifySimpleArtistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        images: freezed == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifySimpleArtistImpl implements _SpotifySimpleArtist {
  _$SpotifySimpleArtistImpl({
    required this.id,
    required this.name,
    required this.externalUri,
    final List<SpotifyImage>? images,
  }) : _images = images;

  factory _$SpotifySimpleArtistImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifySimpleArtistImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String externalUri;
  final List<SpotifyImage>? _images;
  @override
  List<SpotifyImage>? get images {
    final value = _images;
    if (value == null) return null;
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'SpotifySimpleArtist(id: $id, name: $name, externalUri: $externalUri, images: $images)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifySimpleArtistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            const DeepCollectionEquality().equals(other._images, _images));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    externalUri,
    const DeepCollectionEquality().hash(_images),
  );

  /// Create a copy of SpotifySimpleArtist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifySimpleArtistImplCopyWith<_$SpotifySimpleArtistImpl> get copyWith =>
      __$$SpotifySimpleArtistImplCopyWithImpl<_$SpotifySimpleArtistImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifySimpleArtistImplToJson(this);
  }
}

abstract class _SpotifySimpleArtist implements SpotifySimpleArtist {
  factory _SpotifySimpleArtist({
    required final String id,
    required final String name,
    required final String externalUri,
    final List<SpotifyImage>? images,
  }) = _$SpotifySimpleArtistImpl;

  factory _SpotifySimpleArtist.fromJson(Map<String, dynamic> json) =
      _$SpotifySimpleArtistImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get externalUri;
  @override
  List<SpotifyImage>? get images;

  /// Create a copy of SpotifySimpleArtist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifySimpleArtistImplCopyWith<_$SpotifySimpleArtistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifyAlbum _$SpotifyAlbumFromJson(Map<String, dynamic> json) {
  return _SpotifyAlbum.fromJson(json);
}

/// @nodoc
mixin _$SpotifyAlbum {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  List<SpotifySimpleArtist> get artists => throw _privateConstructorUsedError;
  List<SpotifyImage> get images => throw _privateConstructorUsedError;
  SpotifyAlbumType get albumType => throw _privateConstructorUsedError;
  String? get releaseDate => throw _privateConstructorUsedError;
  int? get totalTracks => throw _privateConstructorUsedError;
  String? get recordLabel => throw _privateConstructorUsedError;
  List<String>? get genres => throw _privateConstructorUsedError;

  /// Serializes this SpotifyAlbum to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyAlbum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyAlbumCopyWith<SpotifyAlbum> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyAlbumCopyWith<$Res> {
  factory $SpotifyAlbumCopyWith(
    SpotifyAlbum value,
    $Res Function(SpotifyAlbum) then,
  ) = _$SpotifyAlbumCopyWithImpl<$Res, SpotifyAlbum>;
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifySimpleArtist> artists,
    List<SpotifyImage> images,
    SpotifyAlbumType albumType,
    String? releaseDate,
    int? totalTracks,
    String? recordLabel,
    List<String>? genres,
  });
}

/// @nodoc
class _$SpotifyAlbumCopyWithImpl<$Res, $Val extends SpotifyAlbum>
    implements $SpotifyAlbumCopyWith<$Res> {
  _$SpotifyAlbumCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyAlbum
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? artists = null,
    Object? images = null,
    Object? albumType = null,
    Object? releaseDate = freezed,
    Object? totalTracks = freezed,
    Object? recordLabel = freezed,
    Object? genres = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            artists: null == artists
                ? _value.artists
                : artists // ignore: cast_nullable_to_non_nullable
                      as List<SpotifySimpleArtist>,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>,
            albumType: null == albumType
                ? _value.albumType
                : albumType // ignore: cast_nullable_to_non_nullable
                      as SpotifyAlbumType,
            releaseDate: freezed == releaseDate
                ? _value.releaseDate
                : releaseDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalTracks: freezed == totalTracks
                ? _value.totalTracks
                : totalTracks // ignore: cast_nullable_to_non_nullable
                      as int?,
            recordLabel: freezed == recordLabel
                ? _value.recordLabel
                : recordLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            genres: freezed == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifyAlbumImplCopyWith<$Res>
    implements $SpotifyAlbumCopyWith<$Res> {
  factory _$$SpotifyAlbumImplCopyWith(
    _$SpotifyAlbumImpl value,
    $Res Function(_$SpotifyAlbumImpl) then,
  ) = __$$SpotifyAlbumImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifySimpleArtist> artists,
    List<SpotifyImage> images,
    SpotifyAlbumType albumType,
    String? releaseDate,
    int? totalTracks,
    String? recordLabel,
    List<String>? genres,
  });
}

/// @nodoc
class __$$SpotifyAlbumImplCopyWithImpl<$Res>
    extends _$SpotifyAlbumCopyWithImpl<$Res, _$SpotifyAlbumImpl>
    implements _$$SpotifyAlbumImplCopyWith<$Res> {
  __$$SpotifyAlbumImplCopyWithImpl(
    _$SpotifyAlbumImpl _value,
    $Res Function(_$SpotifyAlbumImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyAlbum
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? artists = null,
    Object? images = null,
    Object? albumType = null,
    Object? releaseDate = freezed,
    Object? totalTracks = freezed,
    Object? recordLabel = freezed,
    Object? genres = freezed,
  }) {
    return _then(
      _$SpotifyAlbumImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        artists: null == artists
            ? _value._artists
            : artists // ignore: cast_nullable_to_non_nullable
                  as List<SpotifySimpleArtist>,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>,
        albumType: null == albumType
            ? _value.albumType
            : albumType // ignore: cast_nullable_to_non_nullable
                  as SpotifyAlbumType,
        releaseDate: freezed == releaseDate
            ? _value.releaseDate
            : releaseDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalTracks: freezed == totalTracks
            ? _value.totalTracks
            : totalTracks // ignore: cast_nullable_to_non_nullable
                  as int?,
        recordLabel: freezed == recordLabel
            ? _value.recordLabel
            : recordLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        genres: freezed == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifyAlbumImpl implements _SpotifyAlbum {
  _$SpotifyAlbumImpl({
    required this.id,
    required this.name,
    required this.externalUri,
    required final List<SpotifySimpleArtist> artists,
    final List<SpotifyImage> images = const [],
    required this.albumType,
    this.releaseDate,
    this.totalTracks,
    this.recordLabel,
    final List<String>? genres,
  }) : _artists = artists,
       _images = images,
       _genres = genres;

  factory _$SpotifyAlbumImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifyAlbumImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String externalUri;
  final List<SpotifySimpleArtist> _artists;
  @override
  List<SpotifySimpleArtist> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  final List<SpotifyImage> _images;
  @override
  @JsonKey()
  List<SpotifyImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final SpotifyAlbumType albumType;
  @override
  final String? releaseDate;
  @override
  final int? totalTracks;
  @override
  final String? recordLabel;
  final List<String>? _genres;
  @override
  List<String>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'SpotifyAlbum(id: $id, name: $name, externalUri: $externalUri, artists: $artists, images: $images, albumType: $albumType, releaseDate: $releaseDate, totalTracks: $totalTracks, recordLabel: $recordLabel, genres: $genres)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyAlbumImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.albumType, albumType) ||
                other.albumType == albumType) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.totalTracks, totalTracks) ||
                other.totalTracks == totalTracks) &&
            (identical(other.recordLabel, recordLabel) ||
                other.recordLabel == recordLabel) &&
            const DeepCollectionEquality().equals(other._genres, _genres));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    externalUri,
    const DeepCollectionEquality().hash(_artists),
    const DeepCollectionEquality().hash(_images),
    albumType,
    releaseDate,
    totalTracks,
    recordLabel,
    const DeepCollectionEquality().hash(_genres),
  );

  /// Create a copy of SpotifyAlbum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyAlbumImplCopyWith<_$SpotifyAlbumImpl> get copyWith =>
      __$$SpotifyAlbumImplCopyWithImpl<_$SpotifyAlbumImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifyAlbumImplToJson(this);
  }
}

abstract class _SpotifyAlbum implements SpotifyAlbum {
  factory _SpotifyAlbum({
    required final String id,
    required final String name,
    required final String externalUri,
    required final List<SpotifySimpleArtist> artists,
    final List<SpotifyImage> images,
    required final SpotifyAlbumType albumType,
    final String? releaseDate,
    final int? totalTracks,
    final String? recordLabel,
    final List<String>? genres,
  }) = _$SpotifyAlbumImpl;

  factory _SpotifyAlbum.fromJson(Map<String, dynamic> json) =
      _$SpotifyAlbumImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get externalUri;
  @override
  List<SpotifySimpleArtist> get artists;
  @override
  List<SpotifyImage> get images;
  @override
  SpotifyAlbumType get albumType;
  @override
  String? get releaseDate;
  @override
  int? get totalTracks;
  @override
  String? get recordLabel;
  @override
  List<String>? get genres;

  /// Create a copy of SpotifyAlbum
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyAlbumImplCopyWith<_$SpotifyAlbumImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifySimpleAlbum _$SpotifySimpleAlbumFromJson(Map<String, dynamic> json) {
  return _SpotifySimpleAlbum.fromJson(json);
}

/// @nodoc
mixin _$SpotifySimpleAlbum {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  List<SpotifySimpleArtist> get artists => throw _privateConstructorUsedError;
  List<SpotifyImage> get images => throw _privateConstructorUsedError;
  SpotifyAlbumType get albumType => throw _privateConstructorUsedError;
  String? get releaseDate => throw _privateConstructorUsedError;

  /// Serializes this SpotifySimpleAlbum to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifySimpleAlbum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifySimpleAlbumCopyWith<SpotifySimpleAlbum> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifySimpleAlbumCopyWith<$Res> {
  factory $SpotifySimpleAlbumCopyWith(
    SpotifySimpleAlbum value,
    $Res Function(SpotifySimpleAlbum) then,
  ) = _$SpotifySimpleAlbumCopyWithImpl<$Res, SpotifySimpleAlbum>;
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifySimpleArtist> artists,
    List<SpotifyImage> images,
    SpotifyAlbumType albumType,
    String? releaseDate,
  });
}

/// @nodoc
class _$SpotifySimpleAlbumCopyWithImpl<$Res, $Val extends SpotifySimpleAlbum>
    implements $SpotifySimpleAlbumCopyWith<$Res> {
  _$SpotifySimpleAlbumCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifySimpleAlbum
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? artists = null,
    Object? images = null,
    Object? albumType = null,
    Object? releaseDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            artists: null == artists
                ? _value.artists
                : artists // ignore: cast_nullable_to_non_nullable
                      as List<SpotifySimpleArtist>,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>,
            albumType: null == albumType
                ? _value.albumType
                : albumType // ignore: cast_nullable_to_non_nullable
                      as SpotifyAlbumType,
            releaseDate: freezed == releaseDate
                ? _value.releaseDate
                : releaseDate // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifySimpleAlbumImplCopyWith<$Res>
    implements $SpotifySimpleAlbumCopyWith<$Res> {
  factory _$$SpotifySimpleAlbumImplCopyWith(
    _$SpotifySimpleAlbumImpl value,
    $Res Function(_$SpotifySimpleAlbumImpl) then,
  ) = __$$SpotifySimpleAlbumImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifySimpleArtist> artists,
    List<SpotifyImage> images,
    SpotifyAlbumType albumType,
    String? releaseDate,
  });
}

/// @nodoc
class __$$SpotifySimpleAlbumImplCopyWithImpl<$Res>
    extends _$SpotifySimpleAlbumCopyWithImpl<$Res, _$SpotifySimpleAlbumImpl>
    implements _$$SpotifySimpleAlbumImplCopyWith<$Res> {
  __$$SpotifySimpleAlbumImplCopyWithImpl(
    _$SpotifySimpleAlbumImpl _value,
    $Res Function(_$SpotifySimpleAlbumImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifySimpleAlbum
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? artists = null,
    Object? images = null,
    Object? albumType = null,
    Object? releaseDate = freezed,
  }) {
    return _then(
      _$SpotifySimpleAlbumImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        artists: null == artists
            ? _value._artists
            : artists // ignore: cast_nullable_to_non_nullable
                  as List<SpotifySimpleArtist>,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>,
        albumType: null == albumType
            ? _value.albumType
            : albumType // ignore: cast_nullable_to_non_nullable
                  as SpotifyAlbumType,
        releaseDate: freezed == releaseDate
            ? _value.releaseDate
            : releaseDate // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifySimpleAlbumImpl implements _SpotifySimpleAlbum {
  _$SpotifySimpleAlbumImpl({
    required this.id,
    required this.name,
    required this.externalUri,
    required final List<SpotifySimpleArtist> artists,
    final List<SpotifyImage> images = const [],
    required this.albumType,
    this.releaseDate,
  }) : _artists = artists,
       _images = images;

  factory _$SpotifySimpleAlbumImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifySimpleAlbumImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String externalUri;
  final List<SpotifySimpleArtist> _artists;
  @override
  List<SpotifySimpleArtist> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  final List<SpotifyImage> _images;
  @override
  @JsonKey()
  List<SpotifyImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final SpotifyAlbumType albumType;
  @override
  final String? releaseDate;

  @override
  String toString() {
    return 'SpotifySimpleAlbum(id: $id, name: $name, externalUri: $externalUri, artists: $artists, images: $images, albumType: $albumType, releaseDate: $releaseDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifySimpleAlbumImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.albumType, albumType) ||
                other.albumType == albumType) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    externalUri,
    const DeepCollectionEquality().hash(_artists),
    const DeepCollectionEquality().hash(_images),
    albumType,
    releaseDate,
  );

  /// Create a copy of SpotifySimpleAlbum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifySimpleAlbumImplCopyWith<_$SpotifySimpleAlbumImpl> get copyWith =>
      __$$SpotifySimpleAlbumImplCopyWithImpl<_$SpotifySimpleAlbumImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifySimpleAlbumImplToJson(this);
  }
}

abstract class _SpotifySimpleAlbum implements SpotifySimpleAlbum {
  factory _SpotifySimpleAlbum({
    required final String id,
    required final String name,
    required final String externalUri,
    required final List<SpotifySimpleArtist> artists,
    final List<SpotifyImage> images,
    required final SpotifyAlbumType albumType,
    final String? releaseDate,
  }) = _$SpotifySimpleAlbumImpl;

  factory _SpotifySimpleAlbum.fromJson(Map<String, dynamic> json) =
      _$SpotifySimpleAlbumImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get externalUri;
  @override
  List<SpotifySimpleArtist> get artists;
  @override
  List<SpotifyImage> get images;
  @override
  SpotifyAlbumType get albumType;
  @override
  String? get releaseDate;

  /// Create a copy of SpotifySimpleAlbum
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifySimpleAlbumImplCopyWith<_$SpotifySimpleAlbumImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifyTrack _$SpotifyTrackFromJson(Map<String, dynamic> json) {
  return _SpotifyTrack.fromJson(json);
}

/// @nodoc
mixin _$SpotifyTrack {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  List<SpotifySimpleArtist> get artists => throw _privateConstructorUsedError;
  SpotifySimpleAlbum get album => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;
  String get isrc => throw _privateConstructorUsedError;
  bool get explicit => throw _privateConstructorUsedError;

  /// Serializes this SpotifyTrack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyTrackCopyWith<SpotifyTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyTrackCopyWith<$Res> {
  factory $SpotifyTrackCopyWith(
    SpotifyTrack value,
    $Res Function(SpotifyTrack) then,
  ) = _$SpotifyTrackCopyWithImpl<$Res, SpotifyTrack>;
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifySimpleArtist> artists,
    SpotifySimpleAlbum album,
    int durationMs,
    String isrc,
    bool explicit,
  });

  $SpotifySimpleAlbumCopyWith<$Res> get album;
}

/// @nodoc
class _$SpotifyTrackCopyWithImpl<$Res, $Val extends SpotifyTrack>
    implements $SpotifyTrackCopyWith<$Res> {
  _$SpotifyTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? artists = null,
    Object? album = null,
    Object? durationMs = null,
    Object? isrc = null,
    Object? explicit = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            artists: null == artists
                ? _value.artists
                : artists // ignore: cast_nullable_to_non_nullable
                      as List<SpotifySimpleArtist>,
            album: null == album
                ? _value.album
                : album // ignore: cast_nullable_to_non_nullable
                      as SpotifySimpleAlbum,
            durationMs: null == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                      as int,
            isrc: null == isrc
                ? _value.isrc
                : isrc // ignore: cast_nullable_to_non_nullable
                      as String,
            explicit: null == explicit
                ? _value.explicit
                : explicit // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of SpotifyTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpotifySimpleAlbumCopyWith<$Res> get album {
    return $SpotifySimpleAlbumCopyWith<$Res>(_value.album, (value) {
      return _then(_value.copyWith(album: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SpotifyTrackImplCopyWith<$Res>
    implements $SpotifyTrackCopyWith<$Res> {
  factory _$$SpotifyTrackImplCopyWith(
    _$SpotifyTrackImpl value,
    $Res Function(_$SpotifyTrackImpl) then,
  ) = __$$SpotifyTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String externalUri,
    List<SpotifySimpleArtist> artists,
    SpotifySimpleAlbum album,
    int durationMs,
    String isrc,
    bool explicit,
  });

  @override
  $SpotifySimpleAlbumCopyWith<$Res> get album;
}

/// @nodoc
class __$$SpotifyTrackImplCopyWithImpl<$Res>
    extends _$SpotifyTrackCopyWithImpl<$Res, _$SpotifyTrackImpl>
    implements _$$SpotifyTrackImplCopyWith<$Res> {
  __$$SpotifyTrackImplCopyWithImpl(
    _$SpotifyTrackImpl _value,
    $Res Function(_$SpotifyTrackImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? externalUri = null,
    Object? artists = null,
    Object? album = null,
    Object? durationMs = null,
    Object? isrc = null,
    Object? explicit = null,
  }) {
    return _then(
      _$SpotifyTrackImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        artists: null == artists
            ? _value._artists
            : artists // ignore: cast_nullable_to_non_nullable
                  as List<SpotifySimpleArtist>,
        album: null == album
            ? _value.album
            : album // ignore: cast_nullable_to_non_nullable
                  as SpotifySimpleAlbum,
        durationMs: null == durationMs
            ? _value.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        isrc: null == isrc
            ? _value.isrc
            : isrc // ignore: cast_nullable_to_non_nullable
                  as String,
        explicit: null == explicit
            ? _value.explicit
            : explicit // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifyTrackImpl implements _SpotifyTrack {
  _$SpotifyTrackImpl({
    required this.id,
    required this.name,
    required this.externalUri,
    final List<SpotifySimpleArtist> artists = const [],
    required this.album,
    required this.durationMs,
    required this.isrc,
    required this.explicit,
  }) : _artists = artists;

  factory _$SpotifyTrackImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifyTrackImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String externalUri;
  final List<SpotifySimpleArtist> _artists;
  @override
  @JsonKey()
  List<SpotifySimpleArtist> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  @override
  final SpotifySimpleAlbum album;
  @override
  final int durationMs;
  @override
  final String isrc;
  @override
  final bool explicit;

  @override
  String toString() {
    return 'SpotifyTrack(id: $id, name: $name, externalUri: $externalUri, artists: $artists, album: $album, durationMs: $durationMs, isrc: $isrc, explicit: $explicit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.isrc, isrc) || other.isrc == isrc) &&
            (identical(other.explicit, explicit) ||
                other.explicit == explicit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    externalUri,
    const DeepCollectionEquality().hash(_artists),
    album,
    durationMs,
    isrc,
    explicit,
  );

  /// Create a copy of SpotifyTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyTrackImplCopyWith<_$SpotifyTrackImpl> get copyWith =>
      __$$SpotifyTrackImplCopyWithImpl<_$SpotifyTrackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifyTrackImplToJson(this);
  }
}

abstract class _SpotifyTrack implements SpotifyTrack {
  factory _SpotifyTrack({
    required final String id,
    required final String name,
    required final String externalUri,
    final List<SpotifySimpleArtist> artists,
    required final SpotifySimpleAlbum album,
    required final int durationMs,
    required final String isrc,
    required final bool explicit,
  }) = _$SpotifyTrackImpl;

  factory _SpotifyTrack.fromJson(Map<String, dynamic> json) =
      _$SpotifyTrackImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get externalUri;
  @override
  List<SpotifySimpleArtist> get artists;
  @override
  SpotifySimpleAlbum get album;
  @override
  int get durationMs;
  @override
  String get isrc;
  @override
  bool get explicit;

  /// Create a copy of SpotifyTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyTrackImplCopyWith<_$SpotifyTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifyPlaylist _$SpotifyPlaylistFromJson(Map<String, dynamic> json) {
  return _SpotifyPlaylist.fromJson(json);
}

/// @nodoc
mixin _$SpotifyPlaylist {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  SpotifyUser get owner => throw _privateConstructorUsedError;
  List<SpotifyImage> get images => throw _privateConstructorUsedError;
  bool get collaborative => throw _privateConstructorUsedError;
  bool get public => throw _privateConstructorUsedError;

  /// Serializes this SpotifyPlaylist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyPlaylistCopyWith<SpotifyPlaylist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyPlaylistCopyWith<$Res> {
  factory $SpotifyPlaylistCopyWith(
    SpotifyPlaylist value,
    $Res Function(SpotifyPlaylist) then,
  ) = _$SpotifyPlaylistCopyWithImpl<$Res, SpotifyPlaylist>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String externalUri,
    SpotifyUser owner,
    List<SpotifyImage> images,
    bool collaborative,
    bool public,
  });

  $SpotifyUserCopyWith<$Res> get owner;
}

/// @nodoc
class _$SpotifyPlaylistCopyWithImpl<$Res, $Val extends SpotifyPlaylist>
    implements $SpotifyPlaylistCopyWith<$Res> {
  _$SpotifyPlaylistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? externalUri = null,
    Object? owner = null,
    Object? images = null,
    Object? collaborative = null,
    Object? public = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as SpotifyUser,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>,
            collaborative: null == collaborative
                ? _value.collaborative
                : collaborative // ignore: cast_nullable_to_non_nullable
                      as bool,
            public: null == public
                ? _value.public
                : public // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of SpotifyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpotifyUserCopyWith<$Res> get owner {
    return $SpotifyUserCopyWith<$Res>(_value.owner, (value) {
      return _then(_value.copyWith(owner: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SpotifyPlaylistImplCopyWith<$Res>
    implements $SpotifyPlaylistCopyWith<$Res> {
  factory _$$SpotifyPlaylistImplCopyWith(
    _$SpotifyPlaylistImpl value,
    $Res Function(_$SpotifyPlaylistImpl) then,
  ) = __$$SpotifyPlaylistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String externalUri,
    SpotifyUser owner,
    List<SpotifyImage> images,
    bool collaborative,
    bool public,
  });

  @override
  $SpotifyUserCopyWith<$Res> get owner;
}

/// @nodoc
class __$$SpotifyPlaylistImplCopyWithImpl<$Res>
    extends _$SpotifyPlaylistCopyWithImpl<$Res, _$SpotifyPlaylistImpl>
    implements _$$SpotifyPlaylistImplCopyWith<$Res> {
  __$$SpotifyPlaylistImplCopyWithImpl(
    _$SpotifyPlaylistImpl _value,
    $Res Function(_$SpotifyPlaylistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? externalUri = null,
    Object? owner = null,
    Object? images = null,
    Object? collaborative = null,
    Object? public = null,
  }) {
    return _then(
      _$SpotifyPlaylistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as SpotifyUser,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>,
        collaborative: null == collaborative
            ? _value.collaborative
            : collaborative // ignore: cast_nullable_to_non_nullable
                  as bool,
        public: null == public
            ? _value.public
            : public // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifyPlaylistImpl implements _SpotifyPlaylist {
  _$SpotifyPlaylistImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.externalUri,
    required this.owner,
    final List<SpotifyImage> images = const [],
    this.collaborative = false,
    this.public = false,
  }) : _images = images;

  factory _$SpotifyPlaylistImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifyPlaylistImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String externalUri;
  @override
  final SpotifyUser owner;
  final List<SpotifyImage> _images;
  @override
  @JsonKey()
  List<SpotifyImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  @JsonKey()
  final bool collaborative;
  @override
  @JsonKey()
  final bool public;

  @override
  String toString() {
    return 'SpotifyPlaylist(id: $id, name: $name, description: $description, externalUri: $externalUri, owner: $owner, images: $images, collaborative: $collaborative, public: $public)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyPlaylistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.collaborative, collaborative) ||
                other.collaborative == collaborative) &&
            (identical(other.public, public) || other.public == public));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    externalUri,
    owner,
    const DeepCollectionEquality().hash(_images),
    collaborative,
    public,
  );

  /// Create a copy of SpotifyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyPlaylistImplCopyWith<_$SpotifyPlaylistImpl> get copyWith =>
      __$$SpotifyPlaylistImplCopyWithImpl<_$SpotifyPlaylistImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifyPlaylistImplToJson(this);
  }
}

abstract class _SpotifyPlaylist implements SpotifyPlaylist {
  factory _SpotifyPlaylist({
    required final String id,
    required final String name,
    required final String description,
    required final String externalUri,
    required final SpotifyUser owner,
    final List<SpotifyImage> images,
    final bool collaborative,
    final bool public,
  }) = _$SpotifyPlaylistImpl;

  factory _SpotifyPlaylist.fromJson(Map<String, dynamic> json) =
      _$SpotifyPlaylistImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get externalUri;
  @override
  SpotifyUser get owner;
  @override
  List<SpotifyImage> get images;
  @override
  bool get collaborative;
  @override
  bool get public;

  /// Create a copy of SpotifyPlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyPlaylistImplCopyWith<_$SpotifyPlaylistImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpotifySimplePlaylist _$SpotifySimplePlaylistFromJson(
  Map<String, dynamic> json,
) {
  return _SpotifySimplePlaylist.fromJson(json);
}

/// @nodoc
mixin _$SpotifySimplePlaylist {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get externalUri => throw _privateConstructorUsedError;
  SpotifyUser get owner => throw _privateConstructorUsedError;
  List<SpotifyImage> get images => throw _privateConstructorUsedError;

  /// Serializes this SpotifySimplePlaylist to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifySimplePlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifySimplePlaylistCopyWith<SpotifySimplePlaylist> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifySimplePlaylistCopyWith<$Res> {
  factory $SpotifySimplePlaylistCopyWith(
    SpotifySimplePlaylist value,
    $Res Function(SpotifySimplePlaylist) then,
  ) = _$SpotifySimplePlaylistCopyWithImpl<$Res, SpotifySimplePlaylist>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String externalUri,
    SpotifyUser owner,
    List<SpotifyImage> images,
  });

  $SpotifyUserCopyWith<$Res> get owner;
}

/// @nodoc
class _$SpotifySimplePlaylistCopyWithImpl<
  $Res,
  $Val extends SpotifySimplePlaylist
>
    implements $SpotifySimplePlaylistCopyWith<$Res> {
  _$SpotifySimplePlaylistCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifySimplePlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? externalUri = null,
    Object? owner = null,
    Object? images = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            externalUri: null == externalUri
                ? _value.externalUri
                : externalUri // ignore: cast_nullable_to_non_nullable
                      as String,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as SpotifyUser,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyImage>,
          )
          as $Val,
    );
  }

  /// Create a copy of SpotifySimplePlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpotifyUserCopyWith<$Res> get owner {
    return $SpotifyUserCopyWith<$Res>(_value.owner, (value) {
      return _then(_value.copyWith(owner: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SpotifySimplePlaylistImplCopyWith<$Res>
    implements $SpotifySimplePlaylistCopyWith<$Res> {
  factory _$$SpotifySimplePlaylistImplCopyWith(
    _$SpotifySimplePlaylistImpl value,
    $Res Function(_$SpotifySimplePlaylistImpl) then,
  ) = __$$SpotifySimplePlaylistImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String externalUri,
    SpotifyUser owner,
    List<SpotifyImage> images,
  });

  @override
  $SpotifyUserCopyWith<$Res> get owner;
}

/// @nodoc
class __$$SpotifySimplePlaylistImplCopyWithImpl<$Res>
    extends
        _$SpotifySimplePlaylistCopyWithImpl<$Res, _$SpotifySimplePlaylistImpl>
    implements _$$SpotifySimplePlaylistImplCopyWith<$Res> {
  __$$SpotifySimplePlaylistImplCopyWithImpl(
    _$SpotifySimplePlaylistImpl _value,
    $Res Function(_$SpotifySimplePlaylistImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifySimplePlaylist
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? externalUri = null,
    Object? owner = null,
    Object? images = null,
  }) {
    return _then(
      _$SpotifySimplePlaylistImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        externalUri: null == externalUri
            ? _value.externalUri
            : externalUri // ignore: cast_nullable_to_non_nullable
                  as String,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as SpotifyUser,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyImage>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifySimplePlaylistImpl implements _SpotifySimplePlaylist {
  _$SpotifySimplePlaylistImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.externalUri,
    required this.owner,
    final List<SpotifyImage> images = const [],
  }) : _images = images;

  factory _$SpotifySimplePlaylistImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifySimplePlaylistImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String externalUri;
  @override
  final SpotifyUser owner;
  final List<SpotifyImage> _images;
  @override
  @JsonKey()
  List<SpotifyImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  String toString() {
    return 'SpotifySimplePlaylist(id: $id, name: $name, description: $description, externalUri: $externalUri, owner: $owner, images: $images)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifySimplePlaylistImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.externalUri, externalUri) ||
                other.externalUri == externalUri) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            const DeepCollectionEquality().equals(other._images, _images));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    externalUri,
    owner,
    const DeepCollectionEquality().hash(_images),
  );

  /// Create a copy of SpotifySimplePlaylist
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifySimplePlaylistImplCopyWith<_$SpotifySimplePlaylistImpl>
  get copyWith =>
      __$$SpotifySimplePlaylistImplCopyWithImpl<_$SpotifySimplePlaylistImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifySimplePlaylistImplToJson(this);
  }
}

abstract class _SpotifySimplePlaylist implements SpotifySimplePlaylist {
  factory _SpotifySimplePlaylist({
    required final String id,
    required final String name,
    required final String description,
    required final String externalUri,
    required final SpotifyUser owner,
    final List<SpotifyImage> images,
  }) = _$SpotifySimplePlaylistImpl;

  factory _SpotifySimplePlaylist.fromJson(Map<String, dynamic> json) =
      _$SpotifySimplePlaylistImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get externalUri;
  @override
  SpotifyUser get owner;
  @override
  List<SpotifyImage> get images;

  /// Create a copy of SpotifySimplePlaylist
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifySimplePlaylistImplCopyWith<_$SpotifySimplePlaylistImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SpotifyPaginatedResponse<T> _$SpotifyPaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object?) fromJsonT,
) {
  return _SpotifyPaginatedResponse<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$SpotifyPaginatedResponse<T> {
  int get limit => throw _privateConstructorUsedError;
  int? get nextOffset => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  List<T> get items => throw _privateConstructorUsedError;

  /// Serializes this SpotifyPaginatedResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of SpotifyPaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifyPaginatedResponseCopyWith<T, SpotifyPaginatedResponse<T>>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifyPaginatedResponseCopyWith<T, $Res> {
  factory $SpotifyPaginatedResponseCopyWith(
    SpotifyPaginatedResponse<T> value,
    $Res Function(SpotifyPaginatedResponse<T>) then,
  ) =
      _$SpotifyPaginatedResponseCopyWithImpl<
        T,
        $Res,
        SpotifyPaginatedResponse<T>
      >;
  @useResult
  $Res call({
    int limit,
    int? nextOffset,
    int total,
    bool hasMore,
    List<T> items,
  });
}

/// @nodoc
class _$SpotifyPaginatedResponseCopyWithImpl<
  T,
  $Res,
  $Val extends SpotifyPaginatedResponse<T>
>
    implements $SpotifyPaginatedResponseCopyWith<T, $Res> {
  _$SpotifyPaginatedResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifyPaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? limit = null,
    Object? nextOffset = freezed,
    Object? total = null,
    Object? hasMore = null,
    Object? items = null,
  }) {
    return _then(
      _value.copyWith(
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            nextOffset: freezed == nextOffset
                ? _value.nextOffset
                : nextOffset // ignore: cast_nullable_to_non_nullable
                      as int?,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<T>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifyPaginatedResponseImplCopyWith<T, $Res>
    implements $SpotifyPaginatedResponseCopyWith<T, $Res> {
  factory _$$SpotifyPaginatedResponseImplCopyWith(
    _$SpotifyPaginatedResponseImpl<T> value,
    $Res Function(_$SpotifyPaginatedResponseImpl<T>) then,
  ) = __$$SpotifyPaginatedResponseImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({
    int limit,
    int? nextOffset,
    int total,
    bool hasMore,
    List<T> items,
  });
}

/// @nodoc
class __$$SpotifyPaginatedResponseImplCopyWithImpl<T, $Res>
    extends
        _$SpotifyPaginatedResponseCopyWithImpl<
          T,
          $Res,
          _$SpotifyPaginatedResponseImpl<T>
        >
    implements _$$SpotifyPaginatedResponseImplCopyWith<T, $Res> {
  __$$SpotifyPaginatedResponseImplCopyWithImpl(
    _$SpotifyPaginatedResponseImpl<T> _value,
    $Res Function(_$SpotifyPaginatedResponseImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifyPaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? limit = null,
    Object? nextOffset = freezed,
    Object? total = null,
    Object? hasMore = null,
    Object? items = null,
  }) {
    return _then(
      _$SpotifyPaginatedResponseImpl<T>(
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        nextOffset: freezed == nextOffset
            ? _value.nextOffset
            : nextOffset // ignore: cast_nullable_to_non_nullable
                  as int?,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<T>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$SpotifyPaginatedResponseImpl<T>
    implements _SpotifyPaginatedResponse<T> {
  _$SpotifyPaginatedResponseImpl({
    required this.limit,
    required this.nextOffset,
    required this.total,
    required this.hasMore,
    required final List<T> items,
  }) : _items = items;

  factory _$SpotifyPaginatedResponseImpl.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$$SpotifyPaginatedResponseImplFromJson(json, fromJsonT);

  @override
  final int limit;
  @override
  final int? nextOffset;
  @override
  final int total;
  @override
  final bool hasMore;
  final List<T> _items;
  @override
  List<T> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'SpotifyPaginatedResponse<$T>(limit: $limit, nextOffset: $nextOffset, total: $total, hasMore: $hasMore, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifyPaginatedResponseImpl<T> &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.nextOffset, nextOffset) ||
                other.nextOffset == nextOffset) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    limit,
    nextOffset,
    total,
    hasMore,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of SpotifyPaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifyPaginatedResponseImplCopyWith<T, _$SpotifyPaginatedResponseImpl<T>>
  get copyWith =>
      __$$SpotifyPaginatedResponseImplCopyWithImpl<
        T,
        _$SpotifyPaginatedResponseImpl<T>
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$SpotifyPaginatedResponseImplToJson<T>(this, toJsonT);
  }
}

abstract class _SpotifyPaginatedResponse<T>
    implements SpotifyPaginatedResponse<T> {
  factory _SpotifyPaginatedResponse({
    required final int limit,
    required final int? nextOffset,
    required final int total,
    required final bool hasMore,
    required final List<T> items,
  }) = _$SpotifyPaginatedResponseImpl<T>;

  factory _SpotifyPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) = _$SpotifyPaginatedResponseImpl<T>.fromJson;

  @override
  int get limit;
  @override
  int? get nextOffset;
  @override
  int get total;
  @override
  bool get hasMore;
  @override
  List<T> get items;

  /// Create a copy of SpotifyPaginatedResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifyPaginatedResponseImplCopyWith<T, _$SpotifyPaginatedResponseImpl<T>>
  get copyWith => throw _privateConstructorUsedError;
}

SpotifySearchResponse _$SpotifySearchResponseFromJson(
  Map<String, dynamic> json,
) {
  return _SpotifySearchResponse.fromJson(json);
}

/// @nodoc
mixin _$SpotifySearchResponse {
  List<SpotifySimpleAlbum> get albums => throw _privateConstructorUsedError;
  List<SpotifyArtist> get artists => throw _privateConstructorUsedError;
  List<SpotifySimplePlaylist> get playlists =>
      throw _privateConstructorUsedError;
  List<SpotifyTrack> get tracks => throw _privateConstructorUsedError;

  /// Serializes this SpotifySearchResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpotifySearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotifySearchResponseCopyWith<SpotifySearchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotifySearchResponseCopyWith<$Res> {
  factory $SpotifySearchResponseCopyWith(
    SpotifySearchResponse value,
    $Res Function(SpotifySearchResponse) then,
  ) = _$SpotifySearchResponseCopyWithImpl<$Res, SpotifySearchResponse>;
  @useResult
  $Res call({
    List<SpotifySimpleAlbum> albums,
    List<SpotifyArtist> artists,
    List<SpotifySimplePlaylist> playlists,
    List<SpotifyTrack> tracks,
  });
}

/// @nodoc
class _$SpotifySearchResponseCopyWithImpl<
  $Res,
  $Val extends SpotifySearchResponse
>
    implements $SpotifySearchResponseCopyWith<$Res> {
  _$SpotifySearchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotifySearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? albums = null,
    Object? artists = null,
    Object? playlists = null,
    Object? tracks = null,
  }) {
    return _then(
      _value.copyWith(
            albums: null == albums
                ? _value.albums
                : albums // ignore: cast_nullable_to_non_nullable
                      as List<SpotifySimpleAlbum>,
            artists: null == artists
                ? _value.artists
                : artists // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyArtist>,
            playlists: null == playlists
                ? _value.playlists
                : playlists // ignore: cast_nullable_to_non_nullable
                      as List<SpotifySimplePlaylist>,
            tracks: null == tracks
                ? _value.tracks
                : tracks // ignore: cast_nullable_to_non_nullable
                      as List<SpotifyTrack>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotifySearchResponseImplCopyWith<$Res>
    implements $SpotifySearchResponseCopyWith<$Res> {
  factory _$$SpotifySearchResponseImplCopyWith(
    _$SpotifySearchResponseImpl value,
    $Res Function(_$SpotifySearchResponseImpl) then,
  ) = __$$SpotifySearchResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<SpotifySimpleAlbum> albums,
    List<SpotifyArtist> artists,
    List<SpotifySimplePlaylist> playlists,
    List<SpotifyTrack> tracks,
  });
}

/// @nodoc
class __$$SpotifySearchResponseImplCopyWithImpl<$Res>
    extends
        _$SpotifySearchResponseCopyWithImpl<$Res, _$SpotifySearchResponseImpl>
    implements _$$SpotifySearchResponseImplCopyWith<$Res> {
  __$$SpotifySearchResponseImplCopyWithImpl(
    _$SpotifySearchResponseImpl _value,
    $Res Function(_$SpotifySearchResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotifySearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? albums = null,
    Object? artists = null,
    Object? playlists = null,
    Object? tracks = null,
  }) {
    return _then(
      _$SpotifySearchResponseImpl(
        albums: null == albums
            ? _value._albums
            : albums // ignore: cast_nullable_to_non_nullable
                  as List<SpotifySimpleAlbum>,
        artists: null == artists
            ? _value._artists
            : artists // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyArtist>,
        playlists: null == playlists
            ? _value._playlists
            : playlists // ignore: cast_nullable_to_non_nullable
                  as List<SpotifySimplePlaylist>,
        tracks: null == tracks
            ? _value._tracks
            : tracks // ignore: cast_nullable_to_non_nullable
                  as List<SpotifyTrack>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SpotifySearchResponseImpl implements _SpotifySearchResponse {
  _$SpotifySearchResponseImpl({
    required final List<SpotifySimpleAlbum> albums,
    required final List<SpotifyArtist> artists,
    required final List<SpotifySimplePlaylist> playlists,
    required final List<SpotifyTrack> tracks,
  }) : _albums = albums,
       _artists = artists,
       _playlists = playlists,
       _tracks = tracks;

  factory _$SpotifySearchResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpotifySearchResponseImplFromJson(json);

  final List<SpotifySimpleAlbum> _albums;
  @override
  List<SpotifySimpleAlbum> get albums {
    if (_albums is EqualUnmodifiableListView) return _albums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_albums);
  }

  final List<SpotifyArtist> _artists;
  @override
  List<SpotifyArtist> get artists {
    if (_artists is EqualUnmodifiableListView) return _artists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_artists);
  }

  final List<SpotifySimplePlaylist> _playlists;
  @override
  List<SpotifySimplePlaylist> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  final List<SpotifyTrack> _tracks;
  @override
  List<SpotifyTrack> get tracks {
    if (_tracks is EqualUnmodifiableListView) return _tracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tracks);
  }

  @override
  String toString() {
    return 'SpotifySearchResponse(albums: $albums, artists: $artists, playlists: $playlists, tracks: $tracks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotifySearchResponseImpl &&
            const DeepCollectionEquality().equals(other._albums, _albums) &&
            const DeepCollectionEquality().equals(other._artists, _artists) &&
            const DeepCollectionEquality().equals(
              other._playlists,
              _playlists,
            ) &&
            const DeepCollectionEquality().equals(other._tracks, _tracks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_albums),
    const DeepCollectionEquality().hash(_artists),
    const DeepCollectionEquality().hash(_playlists),
    const DeepCollectionEquality().hash(_tracks),
  );

  /// Create a copy of SpotifySearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotifySearchResponseImplCopyWith<_$SpotifySearchResponseImpl>
  get copyWith =>
      __$$SpotifySearchResponseImplCopyWithImpl<_$SpotifySearchResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpotifySearchResponseImplToJson(this);
  }
}

abstract class _SpotifySearchResponse implements SpotifySearchResponse {
  factory _SpotifySearchResponse({
    required final List<SpotifySimpleAlbum> albums,
    required final List<SpotifyArtist> artists,
    required final List<SpotifySimplePlaylist> playlists,
    required final List<SpotifyTrack> tracks,
  }) = _$SpotifySearchResponseImpl;

  factory _SpotifySearchResponse.fromJson(Map<String, dynamic> json) =
      _$SpotifySearchResponseImpl.fromJson;

  @override
  List<SpotifySimpleAlbum> get albums;
  @override
  List<SpotifyArtist> get artists;
  @override
  List<SpotifySimplePlaylist> get playlists;
  @override
  List<SpotifyTrack> get tracks;

  /// Create a copy of SpotifySearchResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotifySearchResponseImplCopyWith<_$SpotifySearchResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PluginConfig _$PluginConfigFromJson(Map<String, dynamic> json) {
  return _PluginConfig.fromJson(json);
}

/// @nodoc
mixin _$PluginConfig {
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get entryPoint => throw _privateConstructorUsedError;
  String get pluginApiVersion => throw _privateConstructorUsedError;
  List<PluginApi> get apis => throw _privateConstructorUsedError;
  List<PluginAbility> get abilities => throw _privateConstructorUsedError;
  String? get repository => throw _privateConstructorUsedError;

  /// Serializes this PluginConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PluginConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PluginConfigCopyWith<PluginConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PluginConfigCopyWith<$Res> {
  factory $PluginConfigCopyWith(
    PluginConfig value,
    $Res Function(PluginConfig) then,
  ) = _$PluginConfigCopyWithImpl<$Res, PluginConfig>;
  @useResult
  $Res call({
    String name,
    String description,
    String version,
    String author,
    String entryPoint,
    String pluginApiVersion,
    List<PluginApi> apis,
    List<PluginAbility> abilities,
    String? repository,
  });
}

/// @nodoc
class _$PluginConfigCopyWithImpl<$Res, $Val extends PluginConfig>
    implements $PluginConfigCopyWith<$Res> {
  _$PluginConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PluginConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? version = null,
    Object? author = null,
    Object? entryPoint = null,
    Object? pluginApiVersion = null,
    Object? apis = null,
    Object? abilities = null,
    Object? repository = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            entryPoint: null == entryPoint
                ? _value.entryPoint
                : entryPoint // ignore: cast_nullable_to_non_nullable
                      as String,
            pluginApiVersion: null == pluginApiVersion
                ? _value.pluginApiVersion
                : pluginApiVersion // ignore: cast_nullable_to_non_nullable
                      as String,
            apis: null == apis
                ? _value.apis
                : apis // ignore: cast_nullable_to_non_nullable
                      as List<PluginApi>,
            abilities: null == abilities
                ? _value.abilities
                : abilities // ignore: cast_nullable_to_non_nullable
                      as List<PluginAbility>,
            repository: freezed == repository
                ? _value.repository
                : repository // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PluginConfigImplCopyWith<$Res>
    implements $PluginConfigCopyWith<$Res> {
  factory _$$PluginConfigImplCopyWith(
    _$PluginConfigImpl value,
    $Res Function(_$PluginConfigImpl) then,
  ) = __$$PluginConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String description,
    String version,
    String author,
    String entryPoint,
    String pluginApiVersion,
    List<PluginApi> apis,
    List<PluginAbility> abilities,
    String? repository,
  });
}

/// @nodoc
class __$$PluginConfigImplCopyWithImpl<$Res>
    extends _$PluginConfigCopyWithImpl<$Res, _$PluginConfigImpl>
    implements _$$PluginConfigImplCopyWith<$Res> {
  __$$PluginConfigImplCopyWithImpl(
    _$PluginConfigImpl _value,
    $Res Function(_$PluginConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PluginConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? version = null,
    Object? author = null,
    Object? entryPoint = null,
    Object? pluginApiVersion = null,
    Object? apis = null,
    Object? abilities = null,
    Object? repository = freezed,
  }) {
    return _then(
      _$PluginConfigImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        entryPoint: null == entryPoint
            ? _value.entryPoint
            : entryPoint // ignore: cast_nullable_to_non_nullable
                  as String,
        pluginApiVersion: null == pluginApiVersion
            ? _value.pluginApiVersion
            : pluginApiVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        apis: null == apis
            ? _value._apis
            : apis // ignore: cast_nullable_to_non_nullable
                  as List<PluginApi>,
        abilities: null == abilities
            ? _value._abilities
            : abilities // ignore: cast_nullable_to_non_nullable
                  as List<PluginAbility>,
        repository: freezed == repository
            ? _value.repository
            : repository // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PluginConfigImpl extends _PluginConfig {
  _$PluginConfigImpl({
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.entryPoint,
    required this.pluginApiVersion,
    final List<PluginApi> apis = const [],
    final List<PluginAbility> abilities = const [],
    this.repository,
  }) : _apis = apis,
       _abilities = abilities,
       super._();

  factory _$PluginConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$PluginConfigImplFromJson(json);

  @override
  final String name;
  @override
  final String description;
  @override
  final String version;
  @override
  final String author;
  @override
  final String entryPoint;
  @override
  final String pluginApiVersion;
  final List<PluginApi> _apis;
  @override
  @JsonKey()
  List<PluginApi> get apis {
    if (_apis is EqualUnmodifiableListView) return _apis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_apis);
  }

  final List<PluginAbility> _abilities;
  @override
  @JsonKey()
  List<PluginAbility> get abilities {
    if (_abilities is EqualUnmodifiableListView) return _abilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_abilities);
  }

  @override
  final String? repository;

  @override
  String toString() {
    return 'PluginConfig(name: $name, description: $description, version: $version, author: $author, entryPoint: $entryPoint, pluginApiVersion: $pluginApiVersion, apis: $apis, abilities: $abilities, repository: $repository)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PluginConfigImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.entryPoint, entryPoint) ||
                other.entryPoint == entryPoint) &&
            (identical(other.pluginApiVersion, pluginApiVersion) ||
                other.pluginApiVersion == pluginApiVersion) &&
            const DeepCollectionEquality().equals(other._apis, _apis) &&
            const DeepCollectionEquality().equals(
              other._abilities,
              _abilities,
            ) &&
            (identical(other.repository, repository) ||
                other.repository == repository));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    description,
    version,
    author,
    entryPoint,
    pluginApiVersion,
    const DeepCollectionEquality().hash(_apis),
    const DeepCollectionEquality().hash(_abilities),
    repository,
  );

  /// Create a copy of PluginConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PluginConfigImplCopyWith<_$PluginConfigImpl> get copyWith =>
      __$$PluginConfigImplCopyWithImpl<_$PluginConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PluginConfigImplToJson(this);
  }
}

abstract class _PluginConfig extends PluginConfig {
  factory _PluginConfig({
    required final String name,
    required final String description,
    required final String version,
    required final String author,
    required final String entryPoint,
    required final String pluginApiVersion,
    final List<PluginApi> apis,
    final List<PluginAbility> abilities,
    final String? repository,
  }) = _$PluginConfigImpl;
  _PluginConfig._() : super._();

  factory _PluginConfig.fromJson(Map<String, dynamic> json) =
      _$PluginConfigImpl.fromJson;

  @override
  String get name;
  @override
  String get description;
  @override
  String get version;
  @override
  String get author;
  @override
  String get entryPoint;
  @override
  String get pluginApiVersion;
  @override
  List<PluginApi> get apis;
  @override
  List<PluginAbility> get abilities;
  @override
  String? get repository;

  /// Create a copy of PluginConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PluginConfigImplCopyWith<_$PluginConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
