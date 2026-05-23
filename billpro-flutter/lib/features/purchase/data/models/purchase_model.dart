class OptionModel {
  final String id;
  final String name;

  const OptionModel({required this.id, required this.name});

  factory OptionModel.fromJson(Map<String, dynamic> json) => OptionModel(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
      );
}

class PurchaseAddress {
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String stateCode;
  final String pinCode;
  final String country;

  const PurchaseAddress({
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.pinCode,
    this.country = 'India',
  });

  factory PurchaseAddress.fromJson(Map<String, dynamic> json) => PurchaseAddress(
        label: json['label'] ?? '',
        line1: json['line1'] ?? '',
        line2: json['line2'],
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        stateCode: json['stateCode'] ?? '',
        pinCode: json['pinCode'] ?? '',
        country: json['country'] ?? 'India',
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'line1': line1,
        if (line2 != null) 'line2': line2,
        'city': city,
        'state': state,
        'stateCode': stateCode,
        'pinCode': pinCode,
        'country': country,
      };
}

class PurchaseLineItem {
  final String id;
  final String itemId;
  final String itemName;
  final String? description;
  final String? hsnCode;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discountPercent;
  final double discountFlat;
  final double discountAmount;
  final double gstRate;
  final double cessRate;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;
  final double totalTax;
  final double lineTotal;
  final String? batchNumber;
  final String? batchExpiry;

  const PurchaseLineItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.description,
    this.hsnCode,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountFlat = 0,
    this.discountAmount = 0,
    this.gstRate = 0,
    this.cessRate = 0,
    this.taxableValue = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.cess = 0,
    this.totalTax = 0,
    this.lineTotal = 0,
    this.batchNumber,
    this.batchExpiry,
  });

  factory PurchaseLineItem.fromJson(Map<String, dynamic> json) => PurchaseLineItem(
        id: json['_id'] ?? '',
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
        description: json['description'],
        hsnCode: json['hsnCode'],
        quantity: (json['quantity'] ?? 0).toDouble(),
        unit: json['unit'] ?? 'pcs',
        unitPrice: (json['unitPrice'] ?? 0).toDouble(),
        discountPercent: (json['discountPercent'] ?? 0).toDouble(),
        discountFlat: (json['discountFlat'] ?? 0).toDouble(),
        discountAmount: (json['discountAmount'] ?? 0).toDouble(),
        gstRate: (json['gstRate'] ?? 0).toDouble(),
        cessRate: (json['cessRate'] ?? 0).toDouble(),
        taxableValue: (json['taxableValue'] ?? 0).toDouble(),
        cgst: (json['cgst'] ?? 0).toDouble(),
        sgst: (json['sgst'] ?? 0).toDouble(),
        igst: (json['igst'] ?? 0).toDouble(),
        cess: (json['cess'] ?? 0).toDouble(),
        totalTax: (json['totalTax'] ?? 0).toDouble(),
        lineTotal: (json['lineTotal'] ?? 0).toDouble(),
        batchNumber: json['batchNumber'],
        batchExpiry: json['batchExpiry'],
      );

  Map<String, dynamic> toJsonForCreate() => {
        'itemId': itemId,
        'itemName': itemName,
        if (description != null) 'description': description,
        if (hsnCode != null) 'hsnCode': hsnCode,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unit': unit,
        'gstRate': gstRate,
        'cessRate': cessRate,
        'discountPercent': discountPercent,
        'discountFlat': discountFlat,
        if (batchNumber != null) 'batchNumber': batchNumber,
        if (batchExpiry != null) 'batchExpiry': batchExpiry,
      };
}

class PurchaseBillModel {
  final String id;
  final String companyId;
  final String createdBy;
  final String billNumber;
  final String? vendorBillNumber;
  final String? poReference;
  final String vendorId;
  final String vendorName;
  final String? vendorGSTIN;
  final PurchaseAddress? vendorAddress;
  final String? vendorBillDate;
  final String billDate;
  final String dueDate;
  final String supplyType;
  final String? placeOfSupply;
  final bool isRCM;
  final List<PurchaseLineItem> lineItems;
  final double subTotal;
  final double totalDiscount;
  final double totalTaxableValue;
  final double totalCGST;
  final double totalSGST;
  final double totalIGST;
  final double totalCess;
  final double totalTax;
  final double roundOff;
  final double grandTotal;
  final String? amountInWords;
  final double totalITC;
  final double blockedITC;
  final String status;
  final double paidAmount;
  final double balanceDue;
  final String? paymentTerms;
  final String? narration;
  final List<String> tags;
  final bool isVoid;
  final String? createdAt;
  final String? notes;
  final String? termsAndConditions;

  const PurchaseBillModel({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.billNumber,
    this.vendorBillNumber,
    this.poReference,
    required this.vendorId,
    required this.vendorName,
    this.vendorGSTIN,
    this.vendorAddress,
    this.vendorBillDate,
    required this.billDate,
    required this.dueDate,
    required this.supplyType,
    this.placeOfSupply,
    this.isRCM = false,
    required this.lineItems,
    this.subTotal = 0,
    this.totalDiscount = 0,
    this.totalTaxableValue = 0,
    this.totalCGST = 0,
    this.totalSGST = 0,
    this.totalIGST = 0,
    this.totalCess = 0,
    this.totalTax = 0,
    this.roundOff = 0,
    this.grandTotal = 0,
    this.amountInWords,
    this.totalITC = 0,
    this.blockedITC = 0,
    required this.status,
    this.paidAmount = 0,
    this.balanceDue = 0,
    this.paymentTerms,
    this.narration,
    this.tags = const [],
    this.isVoid = false,
    this.createdAt,
    this.notes,
    this.termsAndConditions,
  });

  factory PurchaseBillModel.fromJson(Map<String, dynamic> json) {
    String vendId = '';
    if (json['vendorId'] is Map) {
      vendId = json['vendorId']['_id'] ?? '';
    } else {
      vendId = json['vendorId']?.toString() ?? '';
    }

    return PurchaseBillModel(
      id: json['_id'] ?? '',
      companyId: json['companyId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      billNumber: json['billNumber'] ?? '',
      vendorBillNumber: json['vendorBillNumber'],
      poReference: json['poReference'],
      vendorId: vendId,
      vendorName: json['vendorName'] ?? '',
      vendorGSTIN: json['vendorGSTIN'],
      vendorAddress: json['vendorAddress'] != null
          ? PurchaseAddress.fromJson(json['vendorAddress'])
          : null,
      vendorBillDate: json['vendorBillDate'],
      billDate: json['billDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      supplyType: json['supplyType'] ?? '',
      placeOfSupply: json['placeOfSupply'],
      isRCM: json['isRCM'] ?? false,
      lineItems: (json['lineItems'] as List?)
              ?.map((e) => PurchaseLineItem.fromJson(e))
              .toList() ??
          [],
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      totalTaxableValue: (json['totalTaxableValue'] ?? 0).toDouble(),
      totalCGST: (json['totalCGST'] ?? 0).toDouble(),
      totalSGST: (json['totalSGST'] ?? 0).toDouble(),
      totalIGST: (json['totalIGST'] ?? 0).toDouble(),
      totalCess: (json['totalCess'] ?? 0).toDouble(),
      totalTax: (json['totalTax'] ?? 0).toDouble(),
      roundOff: (json['roundOff'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      amountInWords: json['amountInWords'],
      totalITC: (json['totalITC'] ?? 0).toDouble(),
      blockedITC: (json['blockedITC'] ?? 0).toDouble(),
      status: json['status'] ?? 'saved',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceDue: (json['balanceDue'] ?? 0).toDouble(),
      paymentTerms: json['paymentTerms'],
      narration: json['narration'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isVoid: json['isVoid'] ?? false,
      createdAt: json['createdAt'],
      notes: json['notes'],
      termsAndConditions: json['termsAndConditions'],
    );
  }
}
