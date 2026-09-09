import 'package:equatable/equatable.dart';

import 'json_converters.dart';

/// Aligned with web `ActorNftVaultDepositResponse`.
class ActorNftVaultDeposit extends Equatable {
  final String? actorCollectionId;
  final String? vaultAmount;

  const ActorNftVaultDeposit({this.actorCollectionId, this.vaultAmount});

  factory ActorNftVaultDeposit.fromJson(Map<String, dynamic> json) {
    return ActorNftVaultDeposit(
      actorCollectionId: asString(json['actorCollectionId']),
      vaultAmount: asString(json['vaultAmount']),
    );
  }

  @override
  List<Object?> get props => [actorCollectionId, vaultAmount];
}
