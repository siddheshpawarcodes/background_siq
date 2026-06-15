// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackgroundProfile {

 String get id; String get name; String? get description;// optional, shown in wizard
 String? get musicFilePath; String? get calibrationVoiceSamplePath;// calibration/preview only (design §9 E6)
 int get musicVolume;// 0..100
 NoiseLevel get noiseReduction; bool get voiceEnhancementEnabled; DuckingStrength get ducking; double get fadeInSeconds;// 0..10
 double get fadeOutSeconds;// 0..10
 bool get normalizationEnabled; ExportFormat get exportFormat; DateTime get createdDate; DateTime get modifiedDate;
/// Create a copy of BackgroundProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundProfileCopyWith<BackgroundProfile> get copyWith => _$BackgroundProfileCopyWithImpl<BackgroundProfile>(this as BackgroundProfile, _$identity);

  /// Serializes this BackgroundProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.musicFilePath, musicFilePath) || other.musicFilePath == musicFilePath)&&(identical(other.calibrationVoiceSamplePath, calibrationVoiceSamplePath) || other.calibrationVoiceSamplePath == calibrationVoiceSamplePath)&&(identical(other.musicVolume, musicVolume) || other.musicVolume == musicVolume)&&(identical(other.noiseReduction, noiseReduction) || other.noiseReduction == noiseReduction)&&(identical(other.voiceEnhancementEnabled, voiceEnhancementEnabled) || other.voiceEnhancementEnabled == voiceEnhancementEnabled)&&(identical(other.ducking, ducking) || other.ducking == ducking)&&(identical(other.fadeInSeconds, fadeInSeconds) || other.fadeInSeconds == fadeInSeconds)&&(identical(other.fadeOutSeconds, fadeOutSeconds) || other.fadeOutSeconds == fadeOutSeconds)&&(identical(other.normalizationEnabled, normalizationEnabled) || other.normalizationEnabled == normalizationEnabled)&&(identical(other.exportFormat, exportFormat) || other.exportFormat == exportFormat)&&(identical(other.createdDate, createdDate) || other.createdDate == createdDate)&&(identical(other.modifiedDate, modifiedDate) || other.modifiedDate == modifiedDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,musicFilePath,calibrationVoiceSamplePath,musicVolume,noiseReduction,voiceEnhancementEnabled,ducking,fadeInSeconds,fadeOutSeconds,normalizationEnabled,exportFormat,createdDate,modifiedDate);

@override
String toString() {
  return 'BackgroundProfile(id: $id, name: $name, description: $description, musicFilePath: $musicFilePath, calibrationVoiceSamplePath: $calibrationVoiceSamplePath, musicVolume: $musicVolume, noiseReduction: $noiseReduction, voiceEnhancementEnabled: $voiceEnhancementEnabled, ducking: $ducking, fadeInSeconds: $fadeInSeconds, fadeOutSeconds: $fadeOutSeconds, normalizationEnabled: $normalizationEnabled, exportFormat: $exportFormat, createdDate: $createdDate, modifiedDate: $modifiedDate)';
}


}

/// @nodoc
abstract mixin class $BackgroundProfileCopyWith<$Res>  {
  factory $BackgroundProfileCopyWith(BackgroundProfile value, $Res Function(BackgroundProfile) _then) = _$BackgroundProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String? musicFilePath, String? calibrationVoiceSamplePath, int musicVolume, NoiseLevel noiseReduction, bool voiceEnhancementEnabled, DuckingStrength ducking, double fadeInSeconds, double fadeOutSeconds, bool normalizationEnabled, ExportFormat exportFormat, DateTime createdDate, DateTime modifiedDate
});




}
/// @nodoc
class _$BackgroundProfileCopyWithImpl<$Res>
    implements $BackgroundProfileCopyWith<$Res> {
  _$BackgroundProfileCopyWithImpl(this._self, this._then);

  final BackgroundProfile _self;
  final $Res Function(BackgroundProfile) _then;

/// Create a copy of BackgroundProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? musicFilePath = freezed,Object? calibrationVoiceSamplePath = freezed,Object? musicVolume = null,Object? noiseReduction = null,Object? voiceEnhancementEnabled = null,Object? ducking = null,Object? fadeInSeconds = null,Object? fadeOutSeconds = null,Object? normalizationEnabled = null,Object? exportFormat = null,Object? createdDate = null,Object? modifiedDate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,musicFilePath: freezed == musicFilePath ? _self.musicFilePath : musicFilePath // ignore: cast_nullable_to_non_nullable
as String?,calibrationVoiceSamplePath: freezed == calibrationVoiceSamplePath ? _self.calibrationVoiceSamplePath : calibrationVoiceSamplePath // ignore: cast_nullable_to_non_nullable
as String?,musicVolume: null == musicVolume ? _self.musicVolume : musicVolume // ignore: cast_nullable_to_non_nullable
as int,noiseReduction: null == noiseReduction ? _self.noiseReduction : noiseReduction // ignore: cast_nullable_to_non_nullable
as NoiseLevel,voiceEnhancementEnabled: null == voiceEnhancementEnabled ? _self.voiceEnhancementEnabled : voiceEnhancementEnabled // ignore: cast_nullable_to_non_nullable
as bool,ducking: null == ducking ? _self.ducking : ducking // ignore: cast_nullable_to_non_nullable
as DuckingStrength,fadeInSeconds: null == fadeInSeconds ? _self.fadeInSeconds : fadeInSeconds // ignore: cast_nullable_to_non_nullable
as double,fadeOutSeconds: null == fadeOutSeconds ? _self.fadeOutSeconds : fadeOutSeconds // ignore: cast_nullable_to_non_nullable
as double,normalizationEnabled: null == normalizationEnabled ? _self.normalizationEnabled : normalizationEnabled // ignore: cast_nullable_to_non_nullable
as bool,exportFormat: null == exportFormat ? _self.exportFormat : exportFormat // ignore: cast_nullable_to_non_nullable
as ExportFormat,createdDate: null == createdDate ? _self.createdDate : createdDate // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedDate: null == modifiedDate ? _self.modifiedDate : modifiedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BackgroundProfile].
extension BackgroundProfilePatterns on BackgroundProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundProfile value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? musicFilePath,  String? calibrationVoiceSamplePath,  int musicVolume,  NoiseLevel noiseReduction,  bool voiceEnhancementEnabled,  DuckingStrength ducking,  double fadeInSeconds,  double fadeOutSeconds,  bool normalizationEnabled,  ExportFormat exportFormat,  DateTime createdDate,  DateTime modifiedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundProfile() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.musicFilePath,_that.calibrationVoiceSamplePath,_that.musicVolume,_that.noiseReduction,_that.voiceEnhancementEnabled,_that.ducking,_that.fadeInSeconds,_that.fadeOutSeconds,_that.normalizationEnabled,_that.exportFormat,_that.createdDate,_that.modifiedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? musicFilePath,  String? calibrationVoiceSamplePath,  int musicVolume,  NoiseLevel noiseReduction,  bool voiceEnhancementEnabled,  DuckingStrength ducking,  double fadeInSeconds,  double fadeOutSeconds,  bool normalizationEnabled,  ExportFormat exportFormat,  DateTime createdDate,  DateTime modifiedDate)  $default,) {final _that = this;
switch (_that) {
case _BackgroundProfile():
return $default(_that.id,_that.name,_that.description,_that.musicFilePath,_that.calibrationVoiceSamplePath,_that.musicVolume,_that.noiseReduction,_that.voiceEnhancementEnabled,_that.ducking,_that.fadeInSeconds,_that.fadeOutSeconds,_that.normalizationEnabled,_that.exportFormat,_that.createdDate,_that.modifiedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String? musicFilePath,  String? calibrationVoiceSamplePath,  int musicVolume,  NoiseLevel noiseReduction,  bool voiceEnhancementEnabled,  DuckingStrength ducking,  double fadeInSeconds,  double fadeOutSeconds,  bool normalizationEnabled,  ExportFormat exportFormat,  DateTime createdDate,  DateTime modifiedDate)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundProfile() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.musicFilePath,_that.calibrationVoiceSamplePath,_that.musicVolume,_that.noiseReduction,_that.voiceEnhancementEnabled,_that.ducking,_that.fadeInSeconds,_that.fadeOutSeconds,_that.normalizationEnabled,_that.exportFormat,_that.createdDate,_that.modifiedDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackgroundProfile implements BackgroundProfile {
  const _BackgroundProfile({required this.id, required this.name, this.description, this.musicFilePath, this.calibrationVoiceSamplePath, this.musicVolume = 20, this.noiseReduction = NoiseLevel.medium, this.voiceEnhancementEnabled = true, this.ducking = DuckingStrength.medium, this.fadeInSeconds = 0.0, this.fadeOutSeconds = 0.0, this.normalizationEnabled = true, this.exportFormat = ExportFormat.mp3, required this.createdDate, required this.modifiedDate});
  factory _BackgroundProfile.fromJson(Map<String, dynamic> json) => _$BackgroundProfileFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
// optional, shown in wizard
@override final  String? musicFilePath;
@override final  String? calibrationVoiceSamplePath;
// calibration/preview only (design §9 E6)
@override@JsonKey() final  int musicVolume;
// 0..100
@override@JsonKey() final  NoiseLevel noiseReduction;
@override@JsonKey() final  bool voiceEnhancementEnabled;
@override@JsonKey() final  DuckingStrength ducking;
@override@JsonKey() final  double fadeInSeconds;
// 0..10
@override@JsonKey() final  double fadeOutSeconds;
// 0..10
@override@JsonKey() final  bool normalizationEnabled;
@override@JsonKey() final  ExportFormat exportFormat;
@override final  DateTime createdDate;
@override final  DateTime modifiedDate;

/// Create a copy of BackgroundProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundProfileCopyWith<_BackgroundProfile> get copyWith => __$BackgroundProfileCopyWithImpl<_BackgroundProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackgroundProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.musicFilePath, musicFilePath) || other.musicFilePath == musicFilePath)&&(identical(other.calibrationVoiceSamplePath, calibrationVoiceSamplePath) || other.calibrationVoiceSamplePath == calibrationVoiceSamplePath)&&(identical(other.musicVolume, musicVolume) || other.musicVolume == musicVolume)&&(identical(other.noiseReduction, noiseReduction) || other.noiseReduction == noiseReduction)&&(identical(other.voiceEnhancementEnabled, voiceEnhancementEnabled) || other.voiceEnhancementEnabled == voiceEnhancementEnabled)&&(identical(other.ducking, ducking) || other.ducking == ducking)&&(identical(other.fadeInSeconds, fadeInSeconds) || other.fadeInSeconds == fadeInSeconds)&&(identical(other.fadeOutSeconds, fadeOutSeconds) || other.fadeOutSeconds == fadeOutSeconds)&&(identical(other.normalizationEnabled, normalizationEnabled) || other.normalizationEnabled == normalizationEnabled)&&(identical(other.exportFormat, exportFormat) || other.exportFormat == exportFormat)&&(identical(other.createdDate, createdDate) || other.createdDate == createdDate)&&(identical(other.modifiedDate, modifiedDate) || other.modifiedDate == modifiedDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,musicFilePath,calibrationVoiceSamplePath,musicVolume,noiseReduction,voiceEnhancementEnabled,ducking,fadeInSeconds,fadeOutSeconds,normalizationEnabled,exportFormat,createdDate,modifiedDate);

@override
String toString() {
  return 'BackgroundProfile(id: $id, name: $name, description: $description, musicFilePath: $musicFilePath, calibrationVoiceSamplePath: $calibrationVoiceSamplePath, musicVolume: $musicVolume, noiseReduction: $noiseReduction, voiceEnhancementEnabled: $voiceEnhancementEnabled, ducking: $ducking, fadeInSeconds: $fadeInSeconds, fadeOutSeconds: $fadeOutSeconds, normalizationEnabled: $normalizationEnabled, exportFormat: $exportFormat, createdDate: $createdDate, modifiedDate: $modifiedDate)';
}


}

/// @nodoc
abstract mixin class _$BackgroundProfileCopyWith<$Res> implements $BackgroundProfileCopyWith<$Res> {
  factory _$BackgroundProfileCopyWith(_BackgroundProfile value, $Res Function(_BackgroundProfile) _then) = __$BackgroundProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String? musicFilePath, String? calibrationVoiceSamplePath, int musicVolume, NoiseLevel noiseReduction, bool voiceEnhancementEnabled, DuckingStrength ducking, double fadeInSeconds, double fadeOutSeconds, bool normalizationEnabled, ExportFormat exportFormat, DateTime createdDate, DateTime modifiedDate
});




}
/// @nodoc
class __$BackgroundProfileCopyWithImpl<$Res>
    implements _$BackgroundProfileCopyWith<$Res> {
  __$BackgroundProfileCopyWithImpl(this._self, this._then);

  final _BackgroundProfile _self;
  final $Res Function(_BackgroundProfile) _then;

/// Create a copy of BackgroundProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? musicFilePath = freezed,Object? calibrationVoiceSamplePath = freezed,Object? musicVolume = null,Object? noiseReduction = null,Object? voiceEnhancementEnabled = null,Object? ducking = null,Object? fadeInSeconds = null,Object? fadeOutSeconds = null,Object? normalizationEnabled = null,Object? exportFormat = null,Object? createdDate = null,Object? modifiedDate = null,}) {
  return _then(_BackgroundProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,musicFilePath: freezed == musicFilePath ? _self.musicFilePath : musicFilePath // ignore: cast_nullable_to_non_nullable
as String?,calibrationVoiceSamplePath: freezed == calibrationVoiceSamplePath ? _self.calibrationVoiceSamplePath : calibrationVoiceSamplePath // ignore: cast_nullable_to_non_nullable
as String?,musicVolume: null == musicVolume ? _self.musicVolume : musicVolume // ignore: cast_nullable_to_non_nullable
as int,noiseReduction: null == noiseReduction ? _self.noiseReduction : noiseReduction // ignore: cast_nullable_to_non_nullable
as NoiseLevel,voiceEnhancementEnabled: null == voiceEnhancementEnabled ? _self.voiceEnhancementEnabled : voiceEnhancementEnabled // ignore: cast_nullable_to_non_nullable
as bool,ducking: null == ducking ? _self.ducking : ducking // ignore: cast_nullable_to_non_nullable
as DuckingStrength,fadeInSeconds: null == fadeInSeconds ? _self.fadeInSeconds : fadeInSeconds // ignore: cast_nullable_to_non_nullable
as double,fadeOutSeconds: null == fadeOutSeconds ? _self.fadeOutSeconds : fadeOutSeconds // ignore: cast_nullable_to_non_nullable
as double,normalizationEnabled: null == normalizationEnabled ? _self.normalizationEnabled : normalizationEnabled // ignore: cast_nullable_to_non_nullable
as bool,exportFormat: null == exportFormat ? _self.exportFormat : exportFormat // ignore: cast_nullable_to_non_nullable
as ExportFormat,createdDate: null == createdDate ? _self.createdDate : createdDate // ignore: cast_nullable_to_non_nullable
as DateTime,modifiedDate: null == modifiedDate ? _self.modifiedDate : modifiedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
