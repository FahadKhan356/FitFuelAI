
import 'package:fitfuel_ai/core/domain/entities/user_entity.dart';

import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository _repository;
  SignInWithEmailUseCase(this._repository);

  Future<UserEntity> call(String email, String password) {
    return _repository.signInWithEmail(email, password);
  }
}