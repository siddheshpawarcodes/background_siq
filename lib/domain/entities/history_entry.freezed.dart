// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryEntry {

 String get id; String get sourcePath; String get outputPath; DateTime get date; String get profileName; Duration get processingTime; JobStatus get status;
/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryEntryCopyWith<HistoryEntry> get copyWith => _$HistoryEntryCopyWithImpl<HistoryEntry>(this as HistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.date, date) || other.date == date)&&(identical(other.profileName, profileName) || other.profileName == profileName)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,sourcePath,outputPath,date,profileName,processingTime,status);

@override
String toString() {
  return 'HistoryEntry(id: $id, sourcePath: $sourcePath, outputPath: $outputPath, date: $date, profileName: $profileName, processingTime: $processingTime, status: $status)';
}


}

/// @nodoc
abstract mixin class $HistoryEntryCopyWith<$Res>  {
  factory $HistoryEntryCopyWith(HistoryEntry value, $Res Function(HistoryEntry) _then) = _$HistoryEntryCopyWithImpl;
@useResult
$Res call({
 String id, String sourcePath, String outputPath, DateTime date, String profileName, Duration processingTime, JobStatus status
});




}
/// @nodoc
class _$HistoryEntryCopyWithImpl<$Res>
    implements $HistoryEntryCopyWith<$Res> {
  _$HistoryEntryCopyWithImpl(this._self, this._then);

  final HistoryEntry _self;
  final $Res Function(HistoryEntry) _then;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourcePath = null,Object? outputPath = null,Object? date = null,Object? profileName = null,Object? processingTime = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,outputPath: null == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,profileName: null == profileName ? _self.profileName : profileName // ignore: cast_nullable_to_non_nullable
as String,processingTime: null == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as Duration,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryEntry].
extension HistoryEntryPatterns on HistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _HistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourcePath,  String outputPath,  DateTime date,  String profileName,  Duration processingTime,  JobStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
return $default(_that.id,_that.sourcePath,_that.outputPath,_that.date,_that.profileName,_that.processingTime,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourcePath,  String outputPath,  DateTime date,  String profileName,  Duration processingTime,  JobStatus status)  $default,) {final _that = this;
switch (_that) {
case _HistoryEntry():
return $default(_that.id,_that.sourcePath,_that.outputPath,_that.date,_that.profileName,_that.processingTime,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourcePath,  String outputPath,  DateTime date,  String profileName,  Duration processingTime,  JobStatus status)?  $default,) {final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
return $default(_that.id,_that.sourcePath,_that.outputPath,_that.date,_that.profileName,_that.processingTime,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryEntry implements HistoryEntry {
  const _HistoryEntry({required this.id, required this.sourcePath, required this.outputPath, required this.date, required this.profileName, required this.processingTime, required this.status});
  

@override final  String id;
@override final  String sourcePath;
@override final  String outputPath;
@override final  DateTime date;
@override final  String profileName;
@override final  Duration processingTime;
@override final  JobStatus status;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryEntryCopyWith<_HistoryEntry> get copyWith => __$HistoryEntryCopyWithImpl<_HistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.outputPath, outputPath) || other.outputPath == outputPath)&&(identical(other.date, date) || other.date == date)&&(identical(other.profileName, profileName) || other.profileName == profileName)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,sourcePath,outputPath,date,profileName,processingTime,status);

@override
String toString() {
  return 'HistoryEntry(id: $id, sourcePath: $sourcePath, outputPath: $outputPath, date: $date, profileName: $profileName, processingTime: $processingTime, status: $status)';
}


}

/// @nodoc
abstract mixin class _$HistoryEntryCopyWith<$Res> implements $HistoryEntryCopyWith<$Res> {
  factory _$HistoryEntryCopyWith(_HistoryEntry value, $Res Function(_HistoryEntry) _then) = __$HistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourcePath, String outputPath, DateTime date, String profileName, Duration processingTime, JobStatus status
});




}
/// @nodoc
class __$HistoryEntryCopyWithImpl<$Res>
    implements _$HistoryEntryCopyWith<$Res> {
  __$HistoryEntryCopyWithImpl(this._self, this._then);

  final _HistoryEntry _self;
  final $Res Function(_HistoryEntry) _then;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourcePath = null,Object? outputPath = null,Object? date = null,Object? profileName = null,Object? processingTime = null,Object? status = null,}) {
  return _then(_HistoryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,outputPath: null == outputPath ? _self.outputPath : outputPath // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,profileName: null == profileName ? _self.profileName : profileName // ignore: cast_nullable_to_non_nullable
as String,processingTime: null == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as Duration,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,
  ));
}


}

// dart format on
