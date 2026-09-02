import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/nurse_profile_model.dart';
import '../../data/models/device_settings_model.dart';
import '../../data/models/verification_documents_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(ProfileInitial());

  Future<void> fetchProfile() async {
    emit(ProfileLoading());
    try {
      final profile = await repository.getProfile();
      VerificationDocumentsModel docs = const VerificationDocumentsModel(nurseId: '');
      List<NotificationItemModel> notifications = [];

      try {
        docs = await repository.getDocuments();
      } catch (_) {}

      try {
        notifications = await repository.getNotifications();
      } catch (_) {}

      emit(ProfileLoaded(
        profile: profile,
        documents: docs,
        notifications: notifications,
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile(NurseProfileModel profile, {File? imageFile}) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;
    emit(current.copyWith(isUpdating: true));
    try {
      await repository.updateProfile(profile, profileImage: imageFile);
      emit(current.copyWith(
        profile: profile,
        isUpdating: false,
        updateSuccessMessage: 'Profile updated successfully!',
      ));
    } catch (e) {
      emit(current.copyWith(isUpdating: false));
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    try {
      await repository.uploadAvatar(imageFile);
      await fetchProfile();
    } catch (_) {}
  }

  Future<bool> updateSettings(DeviceSettingsModel settings) async {
    try {
      return await repository.updateSettings(settings);
    } catch (_) {
      return false;
    }
  }
}

