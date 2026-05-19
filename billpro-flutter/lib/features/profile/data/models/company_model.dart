class CompanyModel {
  final String id;
  final String? ownerId;
  final String legalName;
  final String tradeName;
  final String businessType;
  final String? businessCategory;
  final String? industryType;
  final String? gstin;
  final String? pan;
  final String? fssaiNumber;
  final String? gstType;
  final bool isGSTRegistered;
  final bool tcsEnabled;
  final bool tdsEnabled;
  final String? email;
  final String? mobile;
  final String? website;
  final CompanyAddress? registeredAddress;
  final int fyStartMonth;
  final List<BankAccount> bankAccounts;
  final String? createdAt;
  final String? updatedAt;

  const CompanyModel({
    required this.id,
    this.ownerId,
    required this.legalName,
    required this.tradeName,
    this.businessType = '',
    this.businessCategory,
    this.industryType,
    this.gstin,
    this.pan,
    this.fssaiNumber,
    this.gstType,
    this.isGSTRegistered = false,
    this.tcsEnabled = false,
    this.tdsEnabled = false,
    this.email,
    this.mobile,
    this.website,
    this.registeredAddress,
    this.fyStartMonth = 4,
    this.bankAccounts = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'] ?? json['id'] ?? '',
      ownerId: json['ownerId'],
      legalName: json['legalName'] ?? '',
      tradeName: json['tradeName'] ?? '',
      businessType: json['businessType'] ?? '',
      businessCategory: json['businessCategory'],
      industryType: json['industryType'],
      gstin: json['gstin'],
      pan: json['pan'],
      fssaiNumber: json['fssaiNumber'],
      gstType: json['gstType'],
      isGSTRegistered: json['isGSTRegistered'] ?? false,
      tcsEnabled: json['tcsEnabled'] ?? false,
      tdsEnabled: json['tdsEnabled'] ?? false,
      email: json['email'],
      mobile: json['mobile'],
      website: json['website'],
      registeredAddress: json['registeredAddress'] != null
          ? CompanyAddress.fromJson(json['registeredAddress'])
          : null,
      fyStartMonth: json['fyStartMonth'] ?? 4,
      bankAccounts: (json['bankAccounts'] as List<dynamic>?)
              ?.map((b) => BankAccount.fromJson(b))
              .toList() ??
          [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'legalName': legalName,
        'tradeName': tradeName,
        'businessType': businessType,
        'businessCategory': businessCategory,
        'industryType': industryType,
        'gstin': gstin,
        'pan': pan,
        'fssaiNumber': fssaiNumber,
        'gstType': gstType,
        'isGSTRegistered': isGSTRegistered,
        'tcsEnabled': tcsEnabled,
        'tdsEnabled': tdsEnabled,
        'email': email,
        'mobile': mobile,
        'website': website,
        'registeredAddress': registeredAddress?.toJson(),
        'fyStartMonth': fyStartMonth,
        'bankAccounts': bankAccounts.map((b) => b.toJson()).toList(),
      };
}

class CompanyAddress {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? stateCode;
  final String? pinCode;
  final String? country;

  const CompanyAddress({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.stateCode,
    this.pinCode,
    this.country,
  });

  factory CompanyAddress.fromJson(Map<String, dynamic> json) {
    return CompanyAddress(
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      state: json['state'],
      stateCode: json['stateCode'],
      pinCode: json['pinCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() => {
        'line1': line1 ?? '',
        'line2': line2 ?? '',
        'city': city ?? '',
        'state': state ?? '',
        'stateCode': stateCode ?? '',
        'pinCode': pinCode ?? '',
        'country': country ?? 'India',
      };

  String get fullAddress {
    final parts = [line1, line2, city, state, pinCode, country]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class BankAccount {
  final String? id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String? branchName;
  final String? branchAddress;
  final String? upiId;
  final bool isDefault;

  const BankAccount({
    this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.accountType = 'current',
    this.branchName,
    this.branchAddress,
    this.upiId,
    this.isDefault = false,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['_id'],
      bankName: json['bankName'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      accountType: json['accountType'] ?? 'current',
      branchName: json['branchName'],
      branchAddress: json['branchAddress'],
      upiId: json['upiId'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountType': accountType,
        'branchName': branchName ?? '',
        'branchAddress': branchAddress ?? '',
        'upiId': upiId ?? '',
        'isDefault': isDefault,
      };
}
