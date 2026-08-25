import 'dart:convert';

class TelegramAccount {
  final String id;
  final int telegramUserId;
  final String phoneNumber;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? profilePhotoPath;
  final int? backupChannelId;
  final String sessionDir;
  final bool isActive;
  final DateTime createdAt;

  const TelegramAccount({
    required this.id,
    required this.telegramUserId,
    required this.phoneNumber,
    required this.firstName,
    this.lastName,
    this.username,
    this.profilePhotoPath,
    this.backupChannelId,
    required this.sessionDir,
    this.isActive = false,
    required this.createdAt,
  });

  String get displayName {
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName;
  }

  TelegramAccount copyWith({
    String? id,
    int? telegramUserId,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? username,
    String? profilePhotoPath,
    int? backupChannelId,
    String? sessionDir,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TelegramAccount(
      id: id ?? this.id,
      telegramUserId: telegramUserId ?? this.telegramUserId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      backupChannelId: backupChannelId ?? this.backupChannelId,
      sessionDir: sessionDir ?? this.sessionDir,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'telegramUserId': telegramUserId,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'profilePhotoPath': profilePhotoPath,
      'backupChannelId': backupChannelId,
      'sessionDir': sessionDir,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TelegramAccount.fromMap(Map<String, dynamic> map) {
    return TelegramAccount(
      id: map['id'] as String,
      telegramUserId: (map['telegramUserId'] as num).toInt(),
      phoneNumber: map['phoneNumber'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String?,
      username: map['username'] as String?,
      profilePhotoPath: map['profilePhotoPath'] as String?,
      backupChannelId: (map['backupChannelId'] as num?)?.toInt(),
      sessionDir: map['sessionDir'] as String,
      isActive: map['isActive'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory TelegramAccount.fromJson(String source) =>
      TelegramAccount.fromMap(json.decode(source) as Map<String, dynamic>);
}
