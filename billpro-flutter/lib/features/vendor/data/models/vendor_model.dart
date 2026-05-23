class VendorAddress {
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String stateCode;
  final String pinCode;
  final String country;

  const VendorAddress({
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.pinCode,
    required this.country,
  });

  factory VendorAddress.fromJson(Map<String, dynamic> json) =>
      VendorAddress(
        line1: json['line1'] ?? '',
        line2: json['line2'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        stateCode: json['stateCode'] ?? '',
        pinCode: json['pinCode'] ?? '',
        country: json['country'] ?? 'India',
      );

  Map<String, dynamic> toJson() => {
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'stateCode': stateCode,
        'pinCode': pinCode,
        'country': country,
      };

  VendorAddress copyWith({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? stateCode,
    String? pinCode,
    String? country,
  }) =>
      VendorAddress(
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        stateCode: stateCode ?? this.stateCode,
        pinCode: pinCode ?? this.pinCode,
        country: country ?? this.country,
      );
}

class VendorModel {
  final String id;
  final String name;
  final String displayName;
  final String? vendorCode;
  final String? gstin;
  final String? pan;
  final bool isGSTRegistered;
  final String? contactPerson;
  final String? mobile;
  final String? email;
  final VendorAddress registeredAddress;
  final VendorAddress billingAddress;
  final String? paymentTerms;
  final double creditLimit;
  final double openingBalance;
  final bool isRCMApplicable;
  final List<String> tags;
  final String? notes;
  final bool isActive;
  final String? createdAt;

  const VendorModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.vendorCode,
    this.gstin,
    this.pan,
    required this.isGSTRegistered,
    this.contactPerson,
    this.mobile,
    this.email,
    required this.registeredAddress,
    required this.billingAddress,
    this.paymentTerms,
    required this.creditLimit,
    required this.openingBalance,
    required this.isRCMApplicable,
    required this.tags,
    this.notes,
    required this.isActive,
    this.createdAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        displayName: json['displayName'] ?? '',
        vendorCode: json['vendorCode'],
        gstin: json['gstin'],
        pan: json['pan'],
        isGSTRegistered: json['isGSTRegistered'] ?? false,
        contactPerson: json['contactPerson'],
        mobile: json['mobile'],
        email: json['email'],
        registeredAddress: json['registeredAddress'] != null 
          ? VendorAddress.fromJson(json['registeredAddress'])
          : const VendorAddress(line1: '', line2: '', city: '', state: '', stateCode: '', pinCode: '', country: 'India'),
        billingAddress: json['billingAddress'] != null 
          ? VendorAddress.fromJson(json['billingAddress'])
          : const VendorAddress(line1: '', line2: '', city: '', state: '', stateCode: '', pinCode: '', country: 'India'),
        paymentTerms: json['paymentTerms'],
        creditLimit: (json['creditLimit'] ?? 0).toDouble(),
        openingBalance: (json['openingBalance'] ?? 0).toDouble(),
        isRCMApplicable: json['isRCMApplicable'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
        notes: json['notes'],
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'gstin': gstin,
        'pan': pan,
        'isGSTRegistered': isGSTRegistered,
        'contactPerson': contactPerson,
        'mobile': mobile,
        'email': email,
        'registeredAddress': registeredAddress.toJson(),
        'billingAddress': billingAddress.toJson(),
        'paymentTerms': paymentTerms,
        'creditLimit': creditLimit,
        'openingBalance': openingBalance,
        'isRCMApplicable': isRCMApplicable,
        'tags': tags,
        'notes': notes,
        'isActive': isActive,
      };

  VendorModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? vendorCode,
    String? gstin,
    String? pan,
    bool? isGSTRegistered,
    String? contactPerson,
    String? mobile,
    String? email,
    VendorAddress? registeredAddress,
    VendorAddress? billingAddress,
    String? paymentTerms,
    double? creditLimit,
    double? openingBalance,
    bool? isRCMApplicable,
    List<String>? tags,
    String? notes,
    bool? isActive,
    String? createdAt,
  }) =>
      VendorModel(
        id: id ?? this.id,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        vendorCode: vendorCode ?? this.vendorCode,
        gstin: gstin ?? this.gstin,
        pan: pan ?? this.pan,
        isGSTRegistered: isGSTRegistered ?? this.isGSTRegistered,
        contactPerson: contactPerson ?? this.contactPerson,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        registeredAddress: registeredAddress ?? this.registeredAddress,
        billingAddress: billingAddress ?? this.billingAddress,
        paymentTerms: paymentTerms ?? this.paymentTerms,
        creditLimit: creditLimit ?? this.creditLimit,
        openingBalance: openingBalance ?? this.openingBalance,
        isRCMApplicable: isRCMApplicable ?? this.isRCMApplicable,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}
