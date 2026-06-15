// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'process_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProcessRequest {

 String get jobId; AudioFileRef get source; BackgroundProfile get profile; String get outputPath;/// When set, only this leading slice is rendered (preview — SRS §10.5).
 Duration? get trim;
/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessRequestCopyWith<ProcessRequest> get copyWith => _$ProcessRequestCopyWithImpl<ProcessRequest>(this as ProcessRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessRequest&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.source, source) || other.source == source)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.trim, trim) || other.trim == trim));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,source,profile,outputPath,trim);

@override
String toString() {
  return 'ProcessRequest(jobId: $jobId, source: $source, profile: $profile, outputPath: $outputPath, trim: $trim)';
}


}

/// @nodoc
abstract mixin class $ProcessRequestCopyWith<$Res>  {
  factory $ProcessRequestCopyWith(ProcessRequest value, $Res Function(ProcessRequest) _then) = _$ProcessRequestCopyWithImpl;
@useResult
$Res call({
 String jobId, AudioFileRef source, BackgroundProfile profile, String outputPath, Duration? trim
});


$AudioFileRefCopyWith<$Res> get source;$BackgroundProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$ProcessRequestCopyWithImpl<$Res>
    implements $ProcessRequestCopyWith<$Res> {
  _$ProcessRequestCopyWithImpl(this._self, this._then);

  final ProcessRequest _self;
  final $Res Function(ProcessRequest) _then;

/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? source = null,Object? profile = null,Object? outputPath = null,Object? trim = freezed,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AudioFileRef,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BackgroundProfile,outputPath: null == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String,trim: freezed == trim ? _self.trim : trim // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}
/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<$Res> get source {
  
  return $AudioFileRefCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackgroundProfileCopyWith<$Res> get profile {
  
  return $BackgroundProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProcessRequest].
extension ProcessRequestPatterns on ProcessRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessRequest value)  $default,){
final _that = this;
switch (_that) {
case _ProcessRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String jobId,  AudioFileRef source,  BackgroundProfile profile,  String outputPath,  Duration? trim)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessRequest() when $default != null:
return $default(_that.jobId,_that.source,_that.profile,_that.outputPath,_that.trim);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String jobId,  AudioFileRef source,  BackgroundProfile profile,  String outputPath,  Duration? trim)  $default,) {final _that = this;
switch (_that) {
case _ProcessRequest():
return $default(_that.jobId,_that.source,_that.profile,_that.outputPath,_that.trim);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String jobId,  AudioFileRef source,  BackgroundProfile profile,  String outputPath,  Duration? trim)?  $default,) {final _that = this;
switch (_that) {
case _ProcessRequest() when $default != null:
return $default(_that.jobId,_that.source,_that.profile,_that.outputPath,_that.trim);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessRequest implements ProcessRequest {
  const _ProcessRequest({required this.jobId, required this.source, required this.profile, required this.outputPath, this.trim});
  

@override final  String jobId;
@override final  AudioFileRef source;
@override final  BackgroundProfile profile;
@override final  String outputPath;
/// When set, only this leading slice is rendered (preview — SRS §10.5).
@override final  Duration? trim;

/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessRequestCopyWith<_ProcessRequest> get copyWith => __$ProcessRequestCopyWithImpl<_ProcessRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessRequest&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.source, source) || other.source == source)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.trim, trim) || other.trim == trim));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,source,profile,outputPath,trim);

@override
String toString() {
  return 'ProcessRequest(jobId: $jobId, source: $source, profile: $profile, outputPath: $outputPath, trim: $trim)';
}


}

/// @nodoc
abstract mixin class _$ProcessRequestCopyWith<$Res> implements $ProcessRequestCopyWith<$Res> {
  factory _$ProcessRequestCopyWith(_ProcessRequest value, $Res Function(_ProcessRequest) _then) = __$ProcessRequestCopyWithImpl;
@override @useResult
$Res call({
 String jobId, AudioFileRef source, BackgroundProfile profile, String outputPath, Duration? trim
});


@override $AudioFileRefCopyWith<$Res> get source;@override $BackgroundProfileCopyWith<$Res> get profile;

}
/// @nodoc
class __$ProcessRequestCopyWithImpl<$Res>
    implements _$ProcessRequestCopyWith<$Res> {
  __$ProcessRequestCopyWithImpl(this._self, this._then);

  final _ProcessRequest _self;
  final $Res Function(_ProcessRequest) _then;

/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? source = null,Object? profile = null,Object? outputPath = null,Object? trim = freezed,}) {
  return _then(_ProcessRequest(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AudioFileRef,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BackgroundProfile,outputPath: null == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String,trim: freezed == trim ? _self.trim : trim // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<$Res> get source {
  
  return $AudioFileRefCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of ProcessRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackgroundProfileCopyWith<$Res> get profile {
  
  return $BackgroundProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

/// @nodoc
mixin _$ProcessingProgress {

 JobStage get stage; double get progress;
/// Create a copy of ProcessingProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProcessingProgressCopyWith<ProcessingProgress> get copyWith => _$ProcessingProgressCopyWithImpl<ProcessingProgress>(this as ProcessingProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProcessingProgress&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,stage,progress);

@override
String toString() {
  return 'ProcessingProgress(stage: $stage, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $ProcessingProgressCopyWith<$Res>  {
  factory $ProcessingProgressCopyWith(ProcessingProgress value, $Res Function(ProcessingProgress) _then) = _$ProcessingProgressCopyWithImpl;
@useResult
$Res call({
 JobStage stage, double progress
});




}
/// @nodoc
class _$ProcessingProgressCopyWithImpl<$Res>
    implements $ProcessingProgressCopyWith<$Res> {
  _$ProcessingProgressCopyWithImpl(this._self, this._then);

  final ProcessingProgress _self;
  final $Res Function(ProcessingProgress) _then;

/// Create a copy of ProcessingProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? progress = null,}) {
  return _then(_self.copyWith(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as JobStage,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProcessingProgress].
extension ProcessingProgressPatterns on ProcessingProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProcessingProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProcessingProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProcessingProgress value)  $default,){
final _that = this;
switch (_that) {
case _ProcessingProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProcessingProgress value)?  $default,){
final _that = this;
switch (_that) {
case _ProcessingProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JobStage stage,  double progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProcessingProgress() when $default != null:
return $default(_that.stage,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JobStage stage,  double progress)  $default,) {final _that = this;
switch (_that) {
case _ProcessingProgress():
return $default(_that.stage,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JobStage stage,  double progress)?  $default,) {final _that = this;
switch (_that) {
case _ProcessingProgress() when $default != null:
return $default(_that.stage,_that.progress);case _:
  return null;

}
}

}

/// @nodoc


class _ProcessingProgress implements ProcessingProgress {
  const _ProcessingProgress({required this.stage, required this.progress});
  

@override final  JobStage stage;
@override final  double progress;

/// Create a copy of ProcessingProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProcessingProgressCopyWith<_ProcessingProgress> get copyWith => __$ProcessingProgressCopyWithImpl<_ProcessingProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProcessingProgress&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,stage,progress);

@override
String toString() {
  return 'ProcessingProgress(stage: $stage, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$ProcessingProgressCopyWith<$Res> implements $ProcessingProgressCopyWith<$Res> {
  factory _$ProcessingProgressCopyWith(_ProcessingProgress value, $Res Function(_ProcessingProgress) _then) = __$ProcessingProgressCopyWithImpl;
@override @useResult
$Res call({
 JobStage stage, double progress
});




}
/// @nodoc
class __$ProcessingProgressCopyWithImpl<$Res>
    implements _$ProcessingProgressCopyWith<$Res> {
  __$ProcessingProgressCopyWithImpl(this._self, this._then);

  final _ProcessingProgress _self;
  final $Res Function(_ProcessingProgress) _then;

/// Create a copy of ProcessingProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? progress = null,}) {
  return _then(_ProcessingProgress(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as JobStage,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
