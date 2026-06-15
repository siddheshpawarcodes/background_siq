// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioMeta {

 Duration get duration; int? get sampleRate; int? get channels; String? get codec;
/// Create a copy of AudioMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioMetaCopyWith<AudioMeta> get copyWith => _$AudioMetaCopyWithImpl<AudioMeta>(this as AudioMeta, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioMeta&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.codec, codec) || other.codec == codec));
}


@override
int get hashCode => Object.hash(runtimeType,duration,sampleRate,channels,codec);

@override
String toString() {
  return 'AudioMeta(duration: $duration, sampleRate: $sampleRate, channels: $channels, codec: $codec)';
}


}

/// @nodoc
abstract mixin class $AudioMetaCopyWith<$Res>  {
  factory $AudioMetaCopyWith(AudioMeta value, $Res Function(AudioMeta) _then) = _$AudioMetaCopyWithImpl;
@useResult
$Res call({
 Duration duration, int? sampleRate, int? channels, String? codec
});




}
/// @nodoc
class _$AudioMetaCopyWithImpl<$Res>
    implements $AudioMetaCopyWith<$Res> {
  _$AudioMetaCopyWithImpl(this._self, this._then);

  final AudioMeta _self;
  final $Res Function(AudioMeta) _then;

/// Create a copy of AudioMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,Object? sampleRate = freezed,Object? channels = freezed,Object? codec = freezed,}) {
  return _then(_self.copyWith(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int?,channels: freezed == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as int?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioMeta].
extension AudioMetaPatterns on AudioMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioMeta value)  $default,){
final _that = this;
switch (_that) {
case _AudioMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioMeta value)?  $default,){
final _that = this;
switch (_that) {
case _AudioMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration duration,  int? sampleRate,  int? channels,  String? codec)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioMeta() when $default != null:
return $default(_that.duration,_that.sampleRate,_that.channels,_that.codec);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration duration,  int? sampleRate,  int? channels,  String? codec)  $default,) {final _that = this;
switch (_that) {
case _AudioMeta():
return $default(_that.duration,_that.sampleRate,_that.channels,_that.codec);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration duration,  int? sampleRate,  int? channels,  String? codec)?  $default,) {final _that = this;
switch (_that) {
case _AudioMeta() when $default != null:
return $default(_that.duration,_that.sampleRate,_that.channels,_that.codec);case _:
  return null;

}
}

}

/// @nodoc


class _AudioMeta implements AudioMeta {
  const _AudioMeta({required this.duration, this.sampleRate, this.channels, this.codec});
  

@override final  Duration duration;
@override final  int? sampleRate;
@override final  int? channels;
@override final  String? codec;

/// Create a copy of AudioMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioMetaCopyWith<_AudioMeta> get copyWith => __$AudioMetaCopyWithImpl<_AudioMeta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioMeta&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.codec, codec) || other.codec == codec));
}


@override
int get hashCode => Object.hash(runtimeType,duration,sampleRate,channels,codec);

@override
String toString() {
  return 'AudioMeta(duration: $duration, sampleRate: $sampleRate, channels: $channels, codec: $codec)';
}


}

/// @nodoc
abstract mixin class _$AudioMetaCopyWith<$Res> implements $AudioMetaCopyWith<$Res> {
  factory _$AudioMetaCopyWith(_AudioMeta value, $Res Function(_AudioMeta) _then) = __$AudioMetaCopyWithImpl;
@override @useResult
$Res call({
 Duration duration, int? sampleRate, int? channels, String? codec
});




}
/// @nodoc
class __$AudioMetaCopyWithImpl<$Res>
    implements _$AudioMetaCopyWith<$Res> {
  __$AudioMetaCopyWithImpl(this._self, this._then);

  final _AudioMeta _self;
  final $Res Function(_AudioMeta) _then;

/// Create a copy of AudioMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,Object? sampleRate = freezed,Object? channels = freezed,Object? codec = freezed,}) {
  return _then(_AudioMeta(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int?,channels: freezed == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as int?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
