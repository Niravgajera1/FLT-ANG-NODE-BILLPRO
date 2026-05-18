class CompanyModel {
  final String id;
  final String legalName;
  final String tradeName;
  final String? gstin;
  final String? pan;
  final String? email;
  final String? mobile;
  final CompanyAddress? registeredAddress;

  const CompanyModel({
    required this.id,
    required this.legalName,
    required this.tradeName,
    this.gstin,
    this.pan,
    this.email,
    this.mobile,
    this.registeredAddress,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'] ?? json['id'] ?? '',
      legalName: json['legalName'] ?? '',
      tradeName: json['tradeName'] ?? '',
      gstin: json['gstin'],
      pan: json['pan'],
      email: json['email'],
      mobile: json['mobile'],
      registeredAddress: json['registeredAddress'] != null
          ? CompanyAddress.fromJson(json['registeredAddress'])
          : null,
    );
  }
}

class CompanyAddress {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? country;

  const CompanyAddress({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.pinCode,
    this.country,
  });

  factory CompanyAddress.fromJson(Map<String, dynamic> json) {
    return CompanyAddress(
      line1: json['line1'],
      line2: json['line2'],
      city: json['city'],
      state: json['state'],
      pinCode: json['pinCode'],
      country: json['country'],
    );
  }

  String get fullAddress {
    final parts = [line1, line2, city, state, pinCode, country]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
