// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batch_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BatchFileResult {

 AudioFileRef get file; JobStatus get status; String? get outputPath; String? get error;
/// Create a copy of BatchFileResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchFileResultCopyWith<BatchFileResult> get copyWith => _$BatchFileResultCopyWithImpl<BatchFileResult>(this as BatchFileResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchFileResult&&(identical(other.file, file) || other.file == file)&&(identical(other.status, status) || other.status == status)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,file,status,outputPath,error);

@override
String toString() {
  return 'BatchFileResult(file: $file, status: $status, outputPath: $outputPath, error: $error)';
}


}

/// @nodoc
abstract mixin class $BatchFileResultCopyWith<$Res>  {
  factory $BatchFileResultCopyWith(BatchFileResult value, $Res Function(BatchFileResult) _then) = _$BatchFileResultCopyWithImpl;
@useResult
$Res call({
 AudioFileRef file, JobStatus status, String? outputPath, String? error
});


$AudioFileRefCopyWith<$Res> get file;

}
/// @nodoc
class _$BatchFileResultCopyWithImpl<$Res>
    implements $BatchFileResultCopyWith<$Res> {
  _$BatchFileResultCopyWithImpl(this._self, this._then);

  final BatchFileResult _self;
  final $Res Function(BatchFileResult) _then;

/// Create a copy of BatchFileResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = null,Object? status = null,Object? outputPath = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as AudioFileRef,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BatchFileResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<$Res> get file {
  
  return $AudioFileRefCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}


/// Adds pattern-matching-related methods to [BatchFileResult].
extension BatchFileResultPatterns on BatchFileResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchFileResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchFileResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchFileResult value)  $default,){
final _that = this;
switch (_that) {
case _BatchFileResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchFileResult value)?  $default,){
final _that = this;
switch (_that) {
case _BatchFileResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AudioFileRef file,  JobStatus status,  String? outputPath,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchFileResult() when $default != null:
return $default(_that.file,_that.status,_that.outputPath,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AudioFileRef file,  JobStatus status,  String? outputPath,  String? error)  $default,) {final _that = this;
switch (_that) {
case _BatchFileResult():
return $default(_that.file,_that.status,_that.outputPath,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AudioFileRef file,  JobStatus status,  String? outputPath,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _BatchFileResult() when $default != null:
return $default(_that.file,_that.status,_that.outputPath,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _BatchFileResult implements BatchFileResult {
  const _BatchFileResult({required this.file, required this.status, this.outputPath, this.error});
  

@override final  AudioFileRef file;
@override final  JobStatus status;
@override final  String? outputPath;
@override final  String? error;

/// Create a copy of BatchFileResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchFileResultCopyWith<_BatchFileResult> get copyWith => __$BatchFileResultCopyWithImpl<_BatchFileResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchFileResult&&(identical(other.file, file) || other.file == file)&&(identical(other.status, status) || other.status == status)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,file,status,outputPath,error);

@override
String toString() {
  return 'BatchFileResult(file: $file, status: $status, outputPath: $outputPath, error: $error)';
}


}

/// @nodoc
abstract mixin class _$BatchFileResultCopyWith<$Res> implements $BatchFileResultCopyWith<$Res> {
  factory _$BatchFileResultCopyWith(_BatchFileResult value, $Res Function(_BatchFileResult) _then) = __$BatchFileResultCopyWithImpl;
@override @useResult
$Res call({
 AudioFileRef file, JobStatus status, String? outputPath, String? error
});


@override $AudioFileRefCopyWith<$Res> get file;

}
/// @nodoc
class __$BatchFileResultCopyWithImpl<$Res>
    implements _$BatchFileResultCopyWith<$Res> {
  __$BatchFileResultCopyWithImpl(this._self, this._then);

  final _BatchFileResult _self;
  final $Res Function(_BatchFileResult) _then;

/// Create a copy of BatchFileResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = null,Object? status = null,Object? outputPath = freezed,Object? error = freezed,}) {
  return _then(_BatchFileResult(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as AudioFileRef,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,outputPath: freezed == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BatchFileResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioFileRefCopyWith<$Res> get file {
  
  return $AudioFileRefCopyWith<$Res>(_self.file, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}

/// @nodoc
mixin _$BatchProgress {

 int get total; int get currentIndex;// 0-based index of the file in progress
 double get currentFileProgress;// 0..1
 JobStage get currentStage; List<BatchFileResult> get completed; bool get done;
/// Create a copy of BatchProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchProgressCopyWith<BatchProgress> get copyWith => _$BatchProgressCopyWithImpl<BatchProgress>(this as BatchProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchProgress&&(identical(other.total, total) || other.total == total)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.currentFileProgress, currentFileProgress) || other.currentFileProgress == currentFileProgress)&&(identical(other.currentStage, currentStage) || other.currentStage == currentStage)&&const DeepCollectionEquality().equals(other.completed, completed)&&(identical(other.done, done) || other.done == done));
}


@override
int get hashCode => Object.hash(runtimeType,total,currentIndex,currentFileProgress,currentStage,const DeepCollectionEquality().hash(completed),done);

@override
String toString() {
  return 'BatchProgress(total: $total, currentIndex: $currentIndex, currentFileProgress: $currentFileProgress, currentStage: $currentStage, completed: $completed, done: $done)';
}


}

/// @nodoc
abstract mixin class $BatchProgressCopyWith<$Res>  {
  factory $BatchProgressCopyWith(BatchProgress value, $Res Function(BatchProgress) _then) = _$BatchProgressCopyWithImpl;
@useResult
$Res call({
 int total, int currentIndex, double currentFileProgress, JobStage currentStage, List<BatchFileResult> completed, bool done
});




}
/// @nodoc
class _$BatchProgressCopyWithImpl<$Res>
    implements $BatchProgressCopyWith<$Res> {
  _$BatchProgressCopyWithImpl(this._self, this._then);

  final BatchProgress _self;
  final $Res Function(BatchProgress) _then;

/// Create a copy of BatchProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? currentIndex = null,Object? currentFileProgress = null,Object? currentStage = null,Object? completed = null,Object? done = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentFileProgress: null == currentFileProgress ? _self.currentFileProgress : currentFileProgress // ignore: cast_nullable_to_non_nullable
as double,currentStage: null == currentStage ? _self.currentStage : currentStage // ignore: cast_nullable_to_non_nullable
as JobStage,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as List<BatchFileResult>,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchProgress].
extension BatchProgressPatterns on BatchProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchProgress value)  $default,){
final _that = this;
switch (_that) {
case _BatchProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchProgress value)?  $default,){
final _that = this;
switch (_that) {
case _BatchProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int currentIndex,  double currentFileProgress,  JobStage currentStage,  List<BatchFileResult> completed,  bool done)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchProgress() when $default != null:
return $default(_that.total,_that.currentIndex,_that.currentFileProgress,_that.currentStage,_that.completed,_that.done);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int currentIndex,  double currentFileProgress,  JobStage currentStage,  List<BatchFileResult> completed,  bool done)  $default,) {final _that = this;
switch (_that) {
case _BatchProgress():
return $default(_that.total,_that.currentIndex,_that.currentFileProgress,_that.currentStage,_that.completed,_that.done);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int currentIndex,  double currentFileProgress,  JobStage currentStage,  List<BatchFileResult> completed,  bool done)?  $default,) {final _that = this;
switch (_that) {
case _BatchProgress() when $default != null:
return $default(_that.total,_that.currentIndex,_that.currentFileProgress,_that.currentStage,_that.completed,_that.done);case _:
  return null;

}
}

}

/// @nodoc


class _BatchProgress extends BatchProgress {
  const _BatchProgress({required this.total, required this.currentIndex, this.currentFileProgress = 0.0, this.currentStage = JobStage.preparing, final  List<BatchFileResult> completed = const [], this.done = false}): _completed = completed,super._();
  

@override final  int total;
@override final  int currentIndex;
// 0-based index of the file in progress
@override@JsonKey() final  double currentFileProgress;
// 0..1
@override@JsonKey() final  JobStage currentStage;
 final  List<BatchFileResult> _completed;
@override@JsonKey() List<BatchFileResult> get completed {
  if (_completed is EqualUnmodifiableListView) return _completed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completed);
}

@override@JsonKey() final  bool done;

/// Create a copy of BatchProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchProgressCopyWith<_BatchProgress> get copyWith => __$BatchProgressCopyWithImpl<_BatchProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchProgress&&(identical(other.total, total) || other.total == total)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.currentFileProgress, currentFileProgress) || other.currentFileProgress == currentFileProgress)&&(identical(other.currentStage, currentStage) || other.currentStage == currentStage)&&const DeepCollectionEquality().equals(other._completed, _completed)&&(identical(other.done, done) || other.done == done));
}


@override
int get hashCode => Object.hash(runtimeType,total,currentIndex,currentFileProgress,currentStage,const DeepCollectionEquality().hash(_completed),done);

@override
String toString() {
  return 'BatchProgress(total: $total, currentIndex: $currentIndex, currentFileProgress: $currentFileProgress, currentStage: $currentStage, completed: $completed, done: $done)';
}


}

/// @nodoc
abstract mixin class _$BatchProgressCopyWith<$Res> implements $BatchProgressCopyWith<$Res> {
  factory _$BatchProgressCopyWith(_BatchProgress value, $Res Function(_BatchProgress) _then) = __$BatchProgressCopyWithImpl;
@override @useResult
$Res call({
 int total, int currentIndex, double currentFileProgress, JobStage currentStage, List<BatchFileResult> completed, bool done
});




}
/// @nodoc
class __$BatchProgressCopyWithImpl<$Res>
    implements _$BatchProgressCopyWith<$Res> {
  __$BatchProgressCopyWithImpl(this._self, this._then);

  final _BatchProgress _self;
  final $Res Function(_BatchProgress) _then;

/// Create a copy of BatchProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? currentIndex = null,Object? currentFileProgress = null,Object? currentStage = null,Object? completed = null,Object? done = null,}) {
  return _then(_BatchProgress(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentFileProgress: null == currentFileProgress ? _self.currentFileProgress : currentFileProgress // ignore: cast_nullable_to_non_nullable
as double,currentStage: null == currentStage ? _self.currentStage : currentStage // ignore: cast_nullable_to_non_nullable
as JobStage,completed: null == completed ? _self._completed : completed // ignore: cast_nullable_to_non_nullable
as List<BatchFileResult>,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
