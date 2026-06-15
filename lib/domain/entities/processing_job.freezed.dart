// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'processing_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProcessingJob {

 String get id; AudioFileRef get source; BackgroundProfile get profile; JobStage get stage; double get progress;// 0..1
 String? get outputPath; String? get errorMessage;
/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessingJobCopyWith<ProcessingJob> get copyWith => _$ProcessingJobCopyWithImpl<ProcessingJob>(this as ProcessingJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessingJob&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,profile,stage,progress,outputPath,errorMessage);

@override
String toString() {
  return 'ProcessingJob(id: $id, source: $source, profile: $profile, stage: $stage, progress: $progress, outputPath: $outputPath, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ProcessingJobCopyWith<$Res>  {
  factory $ProcessingJobCopyWith(ProcessingJob value, $Res Function(ProcessingJob) _then) = _$ProcessingJobCopyWithImpl;
@useResult
$Res call({
 String id, AudioFileRef source, BackgroundProfile profile, JobStage stage, double progress, String? outputPath, String? errorMessage
});


$AudioFileRefCopyWith<$Res> get source;$BackgroundProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$ProcessingJobCopyWithImpl<$Res>
    implements $ProcessingJobCopyWith<$Res> {
  _$ProcessingJobCopyWithImpl(this._self, this._then);

  final ProcessingJob _self;
  final $Res Function(ProcessingJob) _then;

/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? profile = null,Object? stage = null,Object? progress = null,Object? outputPath = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AudioFileRef,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BackgroundProfile,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as JobStage,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<$Res> get source {
  
  return $AudioFileRefCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackgroundProfileCopyWith<$Res> get profile {
  
  return $BackgroundProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProcessingJob].
extension ProcessingJobPatterns on ProcessingJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessingJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessingJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessingJob value)  $default,){
final _that = this;
switch (_that) {
case _ProcessingJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessingJob value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessingJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AudioFileRef source,  BackgroundProfile profile,  JobStage stage,  double progress,  String? outputPath,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessingJob() when $default != null:
return $default(_that.id,_that.source,_that.profile,_that.stage,_that.progress,_that.outputPath,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AudioFileRef source,  BackgroundProfile profile,  JobStage stage,  double progress,  String? outputPath,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ProcessingJob():
return $default(_that.id,_that.source,_that.profile,_that.stage,_that.progress,_that.outputPath,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AudioFileRef source,  BackgroundProfile profile,  JobStage stage,  double progress,  String? outputPath,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ProcessingJob() when $default != null:
return $default(_that.id,_that.source,_that.profile,_that.stage,_that.progress,_that.outputPath,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessingJob implements ProcessingJob {
  const _ProcessingJob({required this.id, required this.source, required this.profile, this.stage = JobStage.preparing, this.progress = 0.0, this.outputPath, this.errorMessage});
  

@override final  String id;
@override final  AudioFileRef source;
@override final  BackgroundProfile profile;
@override@JsonKey() final  JobStage stage;
@override@JsonKey() final  double progress;
// 0..1
@override final  String? outputPath;
@override final  String? errorMessage;

/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessingJobCopyWith<_ProcessingJob> get copyWith => __$ProcessingJobCopyWithImpl<_ProcessingJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessingJob&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,id,source,profile,stage,progress,outputPath,errorMessage);

@override
String toString() {
  return 'ProcessingJob(id: $id, source: $source, profile: $profile, stage: $stage, progress: $progress, outputPath: $outputPath, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ProcessingJobCopyWith<$Res> implements $ProcessingJobCopyWith<$Res> {
  factory _$ProcessingJobCopyWith(_ProcessingJob value, $Res Function(_ProcessingJob) _then) = __$ProcessingJobCopyWithImpl;
@override @useResult
$Res call({
 String id, AudioFileRef source, BackgroundProfile profile, JobStage stage, double progress, String? outputPath, String? errorMessage
});


@override $AudioFileRefCopyWith<$Res> get source;@override $BackgroundProfileCopyWith<$Res> get profile;

}
/// @nodoc
class __$ProcessingJobCopyWithImpl<$Res>
    implements _$ProcessingJobCopyWith<$Res> {
  __$ProcessingJobCopyWithImpl(this._self, this._then);

  final _ProcessingJob _self;
  final $Res Function(_ProcessingJob) _then;

/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? profile = null,Object? stage = null,Object? progress = null,Object? outputPath = freezed,Object? errorMessage = freezed,}) {
  return _then(_ProcessingJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AudioFileRef,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BackgroundProfile,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as JobStage,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<$Res> get source {
  
  return $AudioFileRefCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ProcessingJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackgroundProfileCopyWith<$Res> get profile {
  
  return $BackgroundProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
