import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for RolesApi
void main() {
  final instance = Openapi().getRolesApi();

  group(RolesApi, () {
    // Assign Permissions
    //
    //Future<RoleSchema> assignPermissionsRolesRoleIdPermissionsPut(String roleId, AssignPermissionsRequest assignPermissionsRequest) async
    test('test assignPermissionsRolesRoleIdPermissionsPut', () async {
      // TODO
    });

    // Create Role
    //
    //Future<RoleSchema> createRoleRolesPost(CreateRoleRequest createRoleRequest) async
    test('test createRoleRolesPost', () async {
      // TODO
    });

    // Delete Role
    //
    //Future deleteRoleRolesRoleIdDelete(String roleId) async
    test('test deleteRoleRolesRoleIdDelete', () async {
      // TODO
    });

    // Get Role
    //
    //Future<RoleSchema> getRoleRolesRoleIdGet(String roleId) async
    test('test getRoleRolesRoleIdGet', () async {
      // TODO
    });

    // List Roles
    //
    //Future<BuiltList<RoleSchema>> listRolesRolesGet() async
    test('test listRolesRolesGet', () async {
      // TODO
    });

    // Update Role
    //
    //Future<RoleSchema> updateRoleRolesRoleIdPatch(String roleId, UpdateRoleRequest updateRoleRequest) async
    test('test updateRoleRolesRoleIdPatch', () async {
      // TODO
    });

  });
}
