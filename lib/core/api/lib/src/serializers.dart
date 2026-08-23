//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:openapi/src/date_serializer.dart';
import 'package:openapi/src/model/date.dart';

import 'package:openapi/src/model/assign_permissions_request.dart';
import 'package:openapi/src/model/create_role_request.dart';
import 'package:openapi/src/model/forgot_password_response_schema.dart';
import 'package:openapi/src/model/forgot_password_schema.dart';
import 'package:openapi/src/model/http_validation_error.dart';
import 'package:openapi/src/model/location_inner.dart';
import 'package:openapi/src/model/login_schema.dart';
import 'package:openapi/src/model/message_schema.dart';
import 'package:openapi/src/model/permission_schema.dart';
import 'package:openapi/src/model/refresh_token_schema.dart';
import 'package:openapi/src/model/register_schema.dart';
import 'package:openapi/src/model/reset_password_schema.dart';
import 'package:openapi/src/model/role_schema.dart';
import 'package:openapi/src/model/token_pair_schema.dart';
import 'package:openapi/src/model/update_role_request.dart';
import 'package:openapi/src/model/user_schema.dart';
import 'package:openapi/src/model/validation_error.dart';

part 'serializers.g.dart';

@SerializersFor([
  AssignPermissionsRequest,
  CreateRoleRequest,
  ForgotPasswordResponseSchema,
  ForgotPasswordSchema,
  HTTPValidationError,
  LocationInner,
  LoginSchema,
  MessageSchema,
  PermissionSchema,
  RefreshTokenSchema,
  RegisterSchema,
  ResetPasswordSchema,
  RoleSchema,
  TokenPairSchema,
  UpdateRoleRequest,
  UserSchema,
  ValidationError,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(String)]),
        () => MapBuilder<String, String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PermissionSchema)]),
        () => ListBuilder<PermissionSchema>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(LocationInner)]),
        () => ListBuilder<LocationInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ValidationError)]),
        () => ListBuilder<ValidationError>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(RoleSchema)]),
        () => ListBuilder<RoleSchema>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
