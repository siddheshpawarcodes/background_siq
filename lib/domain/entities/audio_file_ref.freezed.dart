// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_file_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioFileRef {

 String get path; String get name; String get ext;// lower-case, no dot
 int? get sizeBytes; Duration? get duration;
/// Create a copy of AudioFileRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<AudioFileRef> get copyWith => _$AudioFileRefCopyWithImpl<AudioFileRef>(this as AudioFileRef, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioFileRef&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.ext, ext) || other.ext == ext)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,ext,sizeBytes,duration);

@override
String toString() {
  return 'AudioFileRef(path: $path, name: $name, ext: $ext, sizeBytes: $sizeBytes, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $AudioFileRefCopyWith<$Res>  {
  factory $AudioFileRefCopyWith(AudioFileRef value, $Res Function(AudioFileRef) _then) = _$AudioFileRefCopyWithImpl;
@useResult
$Res call({
 String path, String name, String ext, int? sizeBytes, Duration? duration
});




}
/// @nodoc
class _$AudioFileRefCopyWithImpl<$Res>
    implements $AudioFileRefCopyWith<$Res> {
  _$AudioFileRefCopyWithImpl(this._self, this._then);

  final AudioFileRef _self;
  final $Res Function(AudioFileRef) _then;

/// Create a copy of AudioFileRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? ext = null,Object? sizeBytes = freezed,Object? duration = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ext: null == ext ? _self.ext : ext // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioFileRef].
extension AudioFileRefPatterns on AudioFileRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioFileRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioFileRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioFileRef value)  $default,){
final _that = this;
switch (_that) {
case _AudioFileRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioFileRef value)?  $default,){
final _that = this;
switch (_that) {
case _AudioFileRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  String ext,  int? sizeBytes,  Duration? duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioFileRef() when $default != null:
return $default(_that.path,_that.name,_that.ext,_that.sizeBytes,_that.duration);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  String ext,  int? sizeBytes,  Duration? duration)  $default,) {final _that = this;
switch (_that) {
case _AudioFileRef():
return $default(_that.path,_that.name,_that.ext,_that.sizeBytes,_that.duration);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  String ext,  int? sizeBytes,  Duration? duration)?  $default,) {final _that = this;
switch (_that) {
case _AudioFileRef() when $default != null:
return $default(_that.path,_that.name,_that.ext,_that.sizeBytes,_that.duration);case _:
  return null;

}
}

}

/// @nodoc


class _AudioFileRef implements AudioFileRef {
  const _AudioFileRef({required this.path, required this.name, required this.ext, this.sizeBytes, this.duration});
  

@override final  String path;
@override final  String name;
@override final  String ext;
// lower-case, no dot
@override final  int? sizeBytes;
@override final  Duration? duration;

/// Create a copy of AudioFileRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioFileRefCopyWith<_AudioFileRef> get copyWith => __$AudioFileRefCopyWithImpl<_AudioFileRef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioFileRef&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.ext, ext) || other.ext == ext)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.duration, duration) || other.duration == duration));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,ext,sizeBytes,duration);

@override
String toString() {
  return 'AudioFileRef(path: $path, name: $name, ext: $ext, sizeBytes: $sizeBytes, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$AudioFileRefCopyWith<$Res> implements $AudioFileRefCopyWith<$Res> {
  factory _$AudioFileRefCopyWith(_AudioFileRef value, $Res Function(_AudioFileRef) _then) = __$AudioFileRefCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, String ext, int? sizeBytes, Duration? duration
});




}
/// @nodoc
class __$AudioFileRefCopyWithImpl<$Res>
    implements _$AudioFileRefCopyWith<$Res> {
  __$AudioFileRefCopyWithImpl(this._self, this._then);

  final _AudioFileRef _self;
  final $Res Function(_AudioFileRef) _then;

/// Create a copy of AudioFileRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? ext = null,Object? sizeBytes = freezed,Object? duration = freezed,}) {
  return _then(_AudioFileRef(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ext: null == ext ? _self.ext : ext // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
