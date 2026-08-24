// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (Serializers().toBuilder()
          ..add(AssignPermissionsRequest.serializer)
          ..add(CreateRoleRequest.serializer)
          ..add(ForgotPasswordResponseSchema.serializer)
          ..add(ForgotPasswordSchema.serializer)
          ..add(HTTPValidationError.serializer)
          ..add(LocationInner.serializer)
          ..add(LoginSchema.serializer)
          ..add(MessageSchema.serializer)
          ..add(PermissionSchema.serializer)
          ..add(RefreshTokenSchema.serializer)
          ..add(RegisterSchema.serializer)
          ..add(ResetPasswordSchema.serializer)
          ..add(RoleSchema.serializer)
          ..add(TokenPairSchema.serializer)
          ..add(UpdateRoleRequest.serializer)
          ..add(UserSchema.serializer)
          ..add(ValidationError.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(LocationInner)]),
            () => ListBuilder<LocationInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(PermissionSchema)]),
            () => ListBuilder<PermissionSchema>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ValidationError)]),
            () => ListBuilder<ValidationError>(),
          ))
        .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
