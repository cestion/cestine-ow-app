import 'package:equatable/equatable.dart';

import '../l10n/app_localizations.dart';
import '../model/prepare_actor_collection_request_model.dart';
import 'system_number_format.dart';

/// Mint 价格范围（USDC）：对齐 Web / 创建演员合集接口要求 [10, 1,000]。
const createActorMintPriceMinUsdc = 10;
const createActorMintPriceMaxUsdc = 1000;
const createActorMintPriceMaxFractionDigits = 2;

final _positiveIntegerPattern = RegExp(r'^[1-9]\d*$');

/// Field-level validation errors for the create-actor issuance form.
class CreateActorFieldErrors extends Equatable {
  final String? name;
  final String? bio;
  final String? totalSupply;
  final String? price;

  const CreateActorFieldErrors({
    this.name,
    this.bio,
    this.totalSupply,
    this.price,
  });

  static const empty = CreateActorFieldErrors();

  bool get hasErrors =>
      name != null || bio != null || totalSupply != null || price != null;

  CreateActorFieldErrors copyWith({
    String? name,
    String? bio,
    String? totalSupply,
    String? price,
    bool clearName = false,
    bool clearBio = false,
    bool clearTotalSupply = false,
    bool clearPrice = false,
  }) {
    return CreateActorFieldErrors(
      name: clearName ? null : (name ?? this.name),
      bio: clearBio ? null : (bio ?? this.bio),
      totalSupply: clearTotalSupply ? null : (totalSupply ?? this.totalSupply),
      price: clearPrice ? null : (price ?? this.price),
    );
  }

  @override
  List<Object?> get props => [name, bio, totalSupply, price];
}

class CreateActorFormValidationResult extends Equatable {
  final CreateActorFieldErrors errors;
  final int? totalSupply;
  final double? price;

  const CreateActorFormValidationResult({
    required this.errors,
    this.totalSupply,
    this.price,
  });

  bool get isValid => !errors.hasErrors && totalSupply != null && price != null;

  @override
  List<Object?> get props => [errors, totalSupply, price];
}

/// Mirrors Web `buildCreateActorSchema` validation for create-mode issuance.
CreateActorFormValidationResult validateCreateActorForm({
  required AppLocalizations l10n,
  required String name,
  required String bio,
  required String totalSupplyText,
  required String priceText,
}) {
  final trimmedName = name.trim();
  final trimmedBio = bio.trim();
  final trimmedSupply = totalSupplyText.trim();
  final trimmedPrice = priceText.trim();

  String? nameError;
  String? bioError;
  String? totalSupplyError;
  String? priceError;
  int? parsedSupply;
  double? parsedPrice;

  if (trimmedName.isEmpty) {
    nameError = l10n.createActorValidationNameRequired;
  } else if (trimmedName.length > 20) {
    nameError = l10n.createActorValidationNameTooLong;
  }

  if (trimmedBio.isEmpty) {
    bioError = l10n.createActorValidationBioRequired;
  } else if (trimmedBio.length > 500) {
    bioError = l10n.createActorValidationBioTooLong;
  }

  if (trimmedSupply.isEmpty) {
    totalSupplyError = l10n.createActorValidationTotalSupplyRequired;
  } else if (!_positiveIntegerPattern.hasMatch(trimmedSupply)) {
    totalSupplyError = l10n.createActorValidationTotalSupplyPositiveInteger;
  } else {
    parsedSupply = int.parse(trimmedSupply);
    if (parsedSupply < prepareActorCollectionMinTotalSupply ||
        parsedSupply > prepareActorCollectionMaxTotalSupply) {
      totalSupplyError = l10n.createActorValidationTotalSupplyRange;
      parsedSupply = null;
    }
  }

  if (trimmedPrice.isEmpty) {
    priceError = l10n.createActorValidationPriceRequired;
  } else {
    final numberFormat = SystemNumberFormat.instance;
    final fractionDigits = numberFormat.fractionDigitCount(trimmedPrice);
    if (fractionDigits == null) {
      priceError = l10n.createActorValidationPriceInvalid;
    } else if (fractionDigits > createActorMintPriceMaxFractionDigits) {
      priceError = l10n.createActorValidationPriceMaxDecimals;
    } else {
      parsedPrice = numberFormat.parseDecimal(trimmedPrice);
      if (parsedPrice == null ||
          parsedPrice < createActorMintPriceMinUsdc ||
          parsedPrice > createActorMintPriceMaxUsdc) {
        priceError = l10n.createActorValidationPriceInvalid;
        parsedPrice = null;
      }
    }
  }

  return CreateActorFormValidationResult(
    errors: CreateActorFieldErrors(
      name: nameError,
      bio: bioError,
      totalSupply: totalSupplyError,
      price: priceError,
    ),
    totalSupply: parsedSupply,
    price: parsedPrice,
  );
}
