class CustomerAddress {
  final String label;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String stateCode;
  final String pinCode;
  final String country;
  final bool isDefault;

  const CustomerAddress({
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.pinCode,
    required this.country,
    required this.isDefault,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        label: json['label'] ?? '',
        line1: json['line1'] ?? '',
        line2: json['line2'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        stateCode: json['stateCode'] ?? '',
        pinCode: json['pinCode'] ?? '',
        country: json['country'] ?? 'India',
        isDefault: json['isDefault'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'stateCode': stateCode,
        'pinCode': pinCode,
        'country': country,
        'isDefault': isDefault,
      };

  CustomerAddress copyWith({
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? stateCode,
    String? pinCode,
    String? country,
    bool? isDefault,
  }) =>
      CustomerAddress(
        label: label ?? this.label,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        stateCode: stateCode ?? this.stateCode,
        pinCode: pinCode ?? this.pinCode,
        country: country ?? this.country,
        isDefault: isDefault ?? this.isDefault,
      );
}

class CustomerModel {
  final String id;
  final String name;
  final String displayName;
  final String customerType; // B2B | B2C
  final String? gstin;
  final String? pan;
  final bool isGSTRegistered;
  final String? contactPerson;
  final String? mobile;
  final String? email;
  final String? altMobile;
  final String? website;
  final List<CustomerAddress> addresses;
  final String? paymentTerms;
  final double creditLimit;
  final double openingBalance;
  final String? openingBalanceDate;
  final double discountPercent;
  final String? customerGroup;
  final List<String> tags;
  final String? notes;
  final bool isActive;
  final String? customerCode;
  final String? createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.customerType,
    this.gstin,
    this.pan,
    this.isGSTRegistered = false,
    this.contactPerson,
    this.mobile,
    this.email,
    this.altMobile,
    this.website,
    this.addresses = const [],
    this.paymentTerms,
    this.creditLimit = 0,
    this.openingBalance = 0,
    this.openingBalanceDate,
    this.discountPercent = 0,
    this.customerGroup,
    this.tags = const [],
    this.notes,
    this.isActive = true,
    this.customerCode,
    this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        displayName: json['displayName'] ?? '',
        customerType: json['customerType'] ?? 'B2B',
        gstin: json['gstin'],
        pan: json['pan'],
        isGSTRegistered: json['isGSTRegistered'] ?? false,
        contactPerson: json['contactPerson'],
        mobile: json['mobile'],
        email: json['email'],
        altMobile: json['altMobile'],
        website: json['website'],
        addresses: (json['addresses'] as List<dynamic>?)
                ?.map((a) => CustomerAddress.fromJson(a))
                .toList() ??
            [],
        paymentTerms: json['paymentTerms'],
        creditLimit: (json['creditLimit'] ?? 0).toDouble(),
        openingBalance: (json['openingBalance'] ?? 0).toDouble(),
        openingBalanceDate: json['openingBalanceDate'],
        discountPercent: (json['discountPercent'] ?? 0).toDouble(),
        customerGroup: json['customerGroup'],
        tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
        notes: json['notes'],
        isActive: json['isActive'] ?? true,
        customerCode: json['customerCode'],
        createdAt: json['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'customerType': customerType,
        if (gstin != null && gstin!.isNotEmpty) 'gstin': gstin,
        if (pan != null && pan!.isNotEmpty) 'pan': pan,
        'isGSTRegistered': isGSTRegistered,
        if (contactPerson != null && contactPerson!.isNotEmpty)
          'contactPerson': contactPerson,
        if (mobile != null && mobile!.isNotEmpty) 'mobile': mobile,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (altMobile != null && altMobile!.isNotEmpty) 'altMobile': altMobile,
        if (website != null && website!.isNotEmpty) 'website': website,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        if (paymentTerms != null && paymentTerms!.isNotEmpty)
          'paymentTerms': paymentTerms,
        'creditLimit': creditLimit,
        'openingBalance': openingBalance,
        if (openingBalanceDate != null) 'openingBalanceDate': openingBalanceDate,
        'discountPercent': discountPercent,
        if (customerGroup != null && customerGroup!.isNotEmpty)
          'customerGroup': customerGroup,
        'tags': tags,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'isActive': isActive,
      };

  CustomerModel copyWith({bool? isActive}) => CustomerModel(
        id: id,
        name: name,
        displayName: displayName,
        customerType: customerType,
        gstin: gstin,
        pan: pan,
        isGSTRegistered: isGSTRegistered,
        contactPerson: contactPerson,
        mobile: mobile,
        email: email,
        altMobile: altMobile,
        website: website,
        addresses: addresses,
        paymentTerms: paymentTerms,
        creditLimit: creditLimit,
        openingBalance: openingBalance,
        openingBalanceDate: openingBalanceDate,
        discountPercent: discountPercent,
        customerGroup: customerGroup,
        tags: tags,
        notes: notes,
        isActive: isActive ?? this.isActive,
        customerCode: customerCode,
        createdAt: createdAt,
      );

  CustomerAddress? get defaultAddress =>
      addresses.where((a) => a.isDefault).isNotEmpty
          ? addresses.firstWhere((a) => a.isDefault)
          : (addresses.isNotEmpty ? addresses.first : null);
}
