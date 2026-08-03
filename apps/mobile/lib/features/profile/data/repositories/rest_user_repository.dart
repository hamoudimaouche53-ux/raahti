import "../../domain/entities/app_user.dart";
import "../../domain/repositories/user_repository.dart";
import "../datasources/user_remote_data_source.dart";

/// [UserRepository] implementation backed by the REST API.
class RestUserRepository implements UserRepository {
  const RestUserRepository(this._remote);

  final UserRemoteDataSource _remote;

  @override
  Future<AppUser> getCurrentUser() async {
    final dto = await _remote.getCurrentUser();
    return dto.toEntity();
  }
}
