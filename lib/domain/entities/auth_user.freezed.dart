// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthUser {

/// Stable account id (the Google `sub`). Used as the storage key so a
/// returning user keeps their previously-edited profile.
 String get id; String get email;/// Name/photo as reported by Google (read-only).
 String? get googleDisplayName; String? get googlePhotoUrl;/// User-editable overrides and extra local fields.
 String? get displayNameOverride; String? get photoPath;// local file path to a picked avatar image
 String? get phone; String? get company; String? get role; DateTime get signedInAt;
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserCopyWith<AuthUser> get copyWith => _$AuthUserCopyWithImpl<AuthUser>(this as AuthUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.googleDisplayName, googleDisplayName) || other.googleDisplayName == googleDisplayName)&&(identical(other.googlePhotoUrl, googlePhotoUrl) || other.googlePhotoUrl == googlePhotoUrl)&&(identical(other.displayNameOverride, displayNameOverride) || other.displayNameOverride == displayNameOverride)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.company, company) || other.company == company)&&(identical(other.role, role) || other.role == role)&&(identical(other.signedInAt, signedInAt) || other.signedInAt == signedInAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,email,googleDisplayName,googlePhotoUrl,displayNameOverride,photoPath,phone,company,role,signedInAt);

@override
String toString() {
  return 'AuthUser(id: $id, email: $email, googleDisplayName: $googleDisplayName, googlePhotoUrl: $googlePhotoUrl, displayNameOverride: $displayNameOverride, photoPath: $photoPath, phone: $phone, company: $company, role: $role, signedInAt: $signedInAt)';
}


}

/// @nodoc
abstract mixin class $AuthUserCopyWith<$Res>  {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) _then) = _$AuthUserCopyWithImpl;
@useResult
$Res call({
 String id, String email, String? googleDisplayName, String? googlePhotoUrl, String? displayNameOverride, String? photoPath, String? phone, String? company, String? role, DateTime signedInAt
});




}
/// @nodoc
class _$AuthUserCopyWithImpl<$Res>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._self, this._then);

  final AuthUser _self;
  final $Res Function(AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? googleDisplayName = freezed,Object? googlePhotoUrl = freezed,Object? displayNameOverride = freezed,Object? photoPath = freezed,Object? phone = freezed,Object? company = freezed,Object? role = freezed,Object? signedInAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,googleDisplayName: freezed == googleDisplayName ? _self.googleDisplayName : googleDisplayName // ignore: cast_nullable_to_non_nullable
as String?,googlePhotoUrl: freezed == googlePhotoUrl ? _self.googlePhotoUrl : googlePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,displayNameOverride: freezed == displayNameOverride ? _self.displayNameOverride : displayNameOverride // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,company: freezed == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,signedInAt: null == signedInAt ? _self.signedInAt : signedInAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthUser].
extension AuthUserPatterns on AuthUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUser value)  $default,){
final _that = this;
switch (_that) {
case _AuthUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUser value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String? googleDisplayName,  String? googlePhotoUrl,  String? displayNameOverride,  String? photoPath,  String? phone,  String? company,  String? role,  DateTime signedInAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.email,_that.googleDisplayName,_that.googlePhotoUrl,_that.displayNameOverride,_that.photoPath,_that.phone,_that.company,_that.role,_that.signedInAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String? googleDisplayName,  String? googlePhotoUrl,  String? displayNameOverride,  String? photoPath,  String? phone,  String? company,  String? role,  DateTime signedInAt)  $default,) {final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that.id,_that.email,_that.googleDisplayName,_that.googlePhotoUrl,_that.displayNameOverride,_that.photoPath,_that.phone,_that.company,_that.role,_that.signedInAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String? googleDisplayName,  String? googlePhotoUrl,  String? displayNameOverride,  String? photoPath,  String? phone,  String? company,  String? role,  DateTime signedInAt)?  $default,) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.email,_that.googleDisplayName,_that.googlePhotoUrl,_that.displayNameOverride,_that.photoPath,_that.phone,_that.company,_that.role,_that.signedInAt);case _:
  return null;

}
}

}

/// @nodoc


class _AuthUser implements AuthUser {
  const _AuthUser({required this.id, required this.email, this.googleDisplayName, this.googlePhotoUrl, this.displayNameOverride, this.photoPath, this.phone, this.company, this.role, required this.signedInAt});
  

/// Stable account id (the Google `sub`). Used as the storage key so a
/// returning user keeps their previously-edited profile.
@override final  String id;
@override final  String email;
/// Name/photo as reported by Google (read-only).
@override final  String? googleDisplayName;
@override final  String? googlePhotoUrl;
/// User-editable overrides and extra local fields.
@override final  String? displayNameOverride;
@override final  String? photoPath;
// local file path to a picked avatar image
@override final  String? phone;
@override final  String? company;
@override final  String? role;
@override final  DateTime signedInAt;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserCopyWith<_AuthUser> get copyWith => __$AuthUserCopyWithImpl<_AuthUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.googleDisplayName, googleDisplayName) || other.googleDisplayName == googleDisplayName)&&(identical(other.googlePhotoUrl, googlePhotoUrl) || other.googlePhotoUrl == googlePhotoUrl)&&(identical(other.displayNameOverride, displayNameOverride) || other.displayNameOverride == displayNameOverride)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.company, company) || other.company == company)&&(identical(other.role, role) || other.role == role)&&(identical(other.signedInAt, signedInAt) || other.signedInAt == signedInAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,email,googleDisplayName,googlePhotoUrl,displayNameOverride,photoPath,phone,company,role,signedInAt);

@override
String toString() {
  return 'AuthUser(id: $id, email: $email, googleDisplayName: $googleDisplayName, googlePhotoUrl: $googlePhotoUrl, displayNameOverride: $displayNameOverride, photoPath: $photoPath, phone: $phone, company: $company, role: $role, signedInAt: $signedInAt)';
}


}

/// @nodoc
abstract mixin class _$AuthUserCopyWith<$Res> implements $AuthUserCopyWith<$Res> {
  factory _$AuthUserCopyWith(_AuthUser value, $Res Function(_AuthUser) _then) = __$AuthUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String? googleDisplayName, String? googlePhotoUrl, String? displayNameOverride, String? photoPath, String? phone, String? company, String? role, DateTime signedInAt
});




}
/// @nodoc
class __$AuthUserCopyWithImpl<$Res>
    implements _$AuthUserCopyWith<$Res> {
  __$AuthUserCopyWithImpl(this._self, this._then);

  final _AuthUser _self;
  final $Res Function(_AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? googleDisplayName = freezed,Object? googlePhotoUrl = freezed,Object? displayNameOverride = freezed,Object? photoPath = freezed,Object? phone = freezed,Object? company = freezed,Object? role = freezed,Object? signedInAt = null,}) {
  return _then(_AuthUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,googleDisplayName: freezed == googleDisplayName ? _self.googleDisplayName : googleDisplayName // ignore: cast_nullable_to_non_nullable
as String?,googlePhotoUrl: freezed == googlePhotoUrl ? _self.googlePhotoUrl : googlePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,displayNameOverride: freezed == displayNameOverride ? _self.displayNameOverride : displayNameOverride // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,company: freezed == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,signedInAt: null == signedInAt ? _self.signedInAt : signedInAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
