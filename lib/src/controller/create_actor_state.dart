import 'package:equatable/equatable.dart';

import '../core/result.dart';
import '../model/models.dart';
import '../utils/create_actor_form_validator.dart';

class CreateActorState extends Equatable {
  final List<Actor> availableMaterials;
  final bool isMaterialsLoading;
  final ApiError? materialsError;
  final Actor? selectedMaterial;
  final String name;
  final String bio;
  final ActorCollectionPricingMode pricingMode;
  final int? totalSupply;
  final String price;
  final bool isSubmitting;
  final bool isSuccess;
  final String? issuedActorId;
  final String? issuedActorName;
  final ActorCollection? previewCollection;
  final ApiError? submitError;
  final bool showValidationErrors;
  final CreateActorFieldErrors fieldErrors;

  const CreateActorState({
    this.availableMaterials = const [],
    this.isMaterialsLoading = false,
    this.materialsError,
    this.selectedMaterial,
    this.name = '',
    this.bio = '',
    this.pricingMode = ActorCollectionPricingMode.bondingCurve,
    this.totalSupply,
    this.price = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.issuedActorId,
    this.issuedActorName,
    this.previewCollection,
    this.submitError,
    this.showValidationErrors = false,
    this.fieldErrors = CreateActorFieldErrors.empty,
  });

  String get errorMessage => submitError?.userMessage ?? '';

  /// The actorCollectionId returned by prepareActorCollection API.
  int? get actorCollectionId => int.tryParse(issuedActorId ?? '');

  CreateActorState copyWith({
    List<Actor>? availableMaterials,
    bool? isMaterialsLoading,
    ApiError? materialsError,
    bool clearMaterialsError = false,
    Actor? selectedMaterial,
    bool clearSelectedMaterial = false,
    String? name,
    String? bio,
    ActorCollectionPricingMode? pricingMode,
    int? totalSupply,
    String? price,
    bool? isSubmitting,
    bool? isSuccess,
    String? issuedActorId,
    String? issuedActorName,
    ActorCollection? previewCollection,
    bool clearPreviewCollection = false,
    ApiError? submitError,
    bool clearSubmitError = false,
    bool? showValidationErrors,
    CreateActorFieldErrors? fieldErrors,
  }) {
    return CreateActorState(
      availableMaterials: availableMaterials ?? this.availableMaterials,
      isMaterialsLoading: isMaterialsLoading ?? this.isMaterialsLoading,
      materialsError: clearMaterialsError
          ? null
          : (materialsError ?? this.materialsError),
      selectedMaterial: clearSelectedMaterial
          ? null
          : (selectedMaterial ?? this.selectedMaterial),
      name: name ?? this.name,
      bio: bio ?? this.bio,
      pricingMode: pricingMode ?? this.pricingMode,
      totalSupply: totalSupply ?? this.totalSupply,
      price: price ?? this.price,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      issuedActorId: issuedActorId ?? this.issuedActorId,
      issuedActorName: issuedActorName ?? this.issuedActorName,
      previewCollection: clearPreviewCollection
          ? null
          : (previewCollection ?? this.previewCollection),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [
    availableMaterials,
    isMaterialsLoading,
    materialsError,
    selectedMaterial,
    name,
    bio,
    pricingMode,
    totalSupply,
    price,
    isSubmitting,
    isSuccess,
    issuedActorId,
    issuedActorName,
    previewCollection,
    submitError,
    showValidationErrors,
    fieldErrors,
  ];
}
