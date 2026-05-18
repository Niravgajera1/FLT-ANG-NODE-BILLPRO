import 'dart:convert';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final String role;
  final bool isEmailVerified;
  final bool isMobileVerified;
  final bool isActive;
  final String? activeCompanyId;
  final bool onboardingCompleted;
  final List<UserCompany> companies;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.role,
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    this.isActive = true,
    this.activeCompanyId,
    this.onboardingCompleted = false,
    this.companies = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      role: json['role'] ?? 'company_admin',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isMobileVerified: json['isMobileVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      activeCompanyId: json['activeCompanyId'],
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      companies: (json['companies'] as List<dynamic>?)
              ?.map((c) => UserCompany.fromJson(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'role': role,
        'isEmailVerified': isEmailVerified,
        'isMobileVerified': isMobileVerified,
        'isActive': isActive,
        'activeCompanyId': activeCompanyId,
        'onboardingCompleted': onboardingCompleted,
        'companies': companies.map((c) => c.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source));
}

class UserCompany {
  final String companyId;
  final String role;
  final bool isOwner;

  const UserCompany({
    required this.companyId,
    required this.role,
    this.isOwner = false,
  });

  factory UserCompany.fromJson(Map<String, dynamic> json) => UserCompany(
        companyId: json['companyId'] ?? '',
        role: json['role'] ?? '',
        isOwner: json['isOwner'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'role': role,
        'isOwner': isOwner,
      };
}
