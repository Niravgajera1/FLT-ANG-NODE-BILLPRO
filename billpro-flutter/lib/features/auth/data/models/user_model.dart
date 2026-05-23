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
  // Extra info from nested object (populated when API returns full company object)
  final String? legalName;
  final String? tradeName;

  const UserCompany({
    required this.companyId,
    required this.role,
    this.isOwner = false,
    this.legalName,
    this.tradeName,
  });

  factory UserCompany.fromJson(Map<String, dynamic> json) {
    // companyId can be a plain String OR a nested object like
    // {"_id": "...", "legalName": "...", "tradeName": "..."}
    final rawCompanyId = json['companyId'];
    String extractedId = '';
    String? legalName;
    String? tradeName;

    if (rawCompanyId is Map<String, dynamic>) {
      extractedId = rawCompanyId['_id']?.toString() ?? '';
      legalName = rawCompanyId['legalName']?.toString();
      tradeName = rawCompanyId['tradeName']?.toString();
    } else if (rawCompanyId is String) {
      extractedId = rawCompanyId;
    }

    return UserCompany(
      companyId: extractedId,
      role: json['role']?.toString() ?? '',
      isOwner: json['isOwner'] ?? false,
      legalName: legalName,
      tradeName: tradeName,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'role': role,
        'isOwner': isOwner,
        if (legalName != null) 'legalName': legalName,
        if (tradeName != null) 'tradeName': tradeName,
      };
}
