import 'package:equatable/equatable.dart';
import '../../data/models/nurse_profile_model.dart';
import '../../data/models/verification_documents_model.dart';
import '../../data/models/device_settings_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final NurseProfileModel profile;
  final VerificationDocumentsModel? documents;
  final List<NotificationItemModel> notifications;
  final bool isUpdating;
  final String? updateSuccessMessage;

  const ProfileLoaded({
    required this.profile,
    this.documents,
    this.notifications = const [],
    this.isUpdating = false,
    this.updateSuccessMessage,
  });

  ProfileLoaded copyWith({
    NurseProfileModel? profile,
    VerificationDocumentsModel? documents,
    List<NotificationItemModel>? notifications,
    bool? isUpdating,
    String? updateSuccessMessage,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      documents: documents ?? this.documents,
      notifications: notifications ?? this.notifications,
      isUpdating: isUpdating ?? this.isUpdating,
      updateSuccessMessage: updateSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [profile, documents, notifications, isUpdating, updateSuccessMessage];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

