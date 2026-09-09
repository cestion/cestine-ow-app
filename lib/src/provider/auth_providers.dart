import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/controllers.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
