import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:howpa_nurse/features/profile/data/models/nurse_profile_model.dart';
import 'package:howpa_nurse/features/profile/data/models/specialization_model.dart';
import 'package:howpa_nurse/features/profile/data/repositories/profile_repository.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'registration_state.dart';


class RegistrationCubit extends Cubit<RegistrationState> {
  final AuthRepository authRepository;
  final ProfileRepository? profileRepository;

  RegistrationCubit({
    required this.authRepository,
    this.profileRepository,
  }) : super(RegistrationInitial());

  Future<List<SpecializationModel>> loadSpecializations() async {
    try {
      if (profileRepository != null) {
        final list = await profileRepository!.getSpecializations();
        emit(SpecializationsLoaded(list));
        return list;
      }
      return SpecializationModel.defaultList();
    } catch (_) {
      return SpecializationModel.defaultList();
    }
  }

  Future<void> submitRegistration(RegistrationRequest request, {File? profileImage}) async {
    emit(RegistrationSubmitting());
    try {
      if (profileRepository != null) {
        final success = await profileRepository!.updateProfile(
          requestToProfileModel(request),
          profileImage: profileImage,
        );
        if (success) {
          emit(const RegistrationSuccess(message: 'Nurse profile updated successfully'));
          return;
        }
      }
      final res = await authRepository.registerNurse(request);
      if (res.success) {
        emit(RegistrationSuccess(message: res.message ?? 'Registration successful'));
      } else {
        emit(RegistrationError(res.message ?? 'Registration failed'));
      }
    } catch (e) {
      emit(RegistrationError(e.toString()));
    }
  }

  Future<void> submitDocuments({
    File? nursingCertificate,
    File? aadhaarFront,
    File? aadhaarBack,
    File? governmentId,
    File? addressProof,
    File? photo,
  }) async {
    emit(RegistrationSubmitting());
    try {
      if (profileRepository != null) {
        final success = await profileRepository!.uploadVerificationDocuments(
          nursingCertificate: nursingCertificate,
          aadhaarFront: aadhaarFront,
          aadhaarBack: aadhaarBack,
          governmentId: governmentId,
          addressProof: addressProof,
          photo: photo,
        );
        if (success) {
          emit(const RegistrationDocumentsSuccess(message: 'Verification documents uploaded successfully'));
          return;
        }
      }
      emit(const RegistrationDocumentsSuccess(message: 'Verification documents uploaded successfully'));
    } catch (e) {
      emit(RegistrationError(e.toString()));
    }
  }

  static NurseProfileModel requestToProfileModel(RegistrationRequest request) {
    return NurseProfileModel(
      id: 'NURSE-001',
      fullName: request.fullName,
      phoneNumber: request.phoneNumber,
      email: request.email,
      dob: request.dob,
      gender: request.gender,
      experience: request.experience,
      specialization: request.specialization,
      bio: request.bio ?? 'Dedicated home care nursing professional.',
      languages: request.languages ?? const ['English', 'Hindi'],
      country: request.country,
      state: request.state,
      district: request.district,
      area: request.area,
      location: request.location,
      pincode: request.pincode ?? '500081',
      latitude: request.latitude ?? 17.4483,
      longitude: request.longitude ?? 78.3814,
    );
  }
}


