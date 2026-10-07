
import 'package:fitfuel_ai/core/domain/entities/user_entity.dart';

import '../repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  SignInWithEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<UserEntity> call(String email, String password) => _repository.signInWithEmail(email, password);
}