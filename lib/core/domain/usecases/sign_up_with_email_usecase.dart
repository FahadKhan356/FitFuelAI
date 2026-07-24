
import 'package:fitfuel_ai/core/domain/entities/user_entity.dart';

import '../repositories/auth_repository.dart';

class SignUpWithEmailUseCase {
  final AuthRepository _repository;
  SignUpWithEmailUseCase(this._repository);

  Future<UserEntity> call(String email, String password) {
    return _repository.signUpWithEmail(email, password);
  }
}