class OptionModel {
  final String id;
  final String name;

  const OptionModel({required this.id, required this.name});

  factory OptionModel.fromJson(Map<String, dynamic> json) => OptionModel(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
      );
}

class InvoiceAddress {
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String stateCode;
  final String pinCode;
  final String country;

  const InvoiceAddress({
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.pinCode,
    this.country = 'India',
  });

  factory InvoiceAddress.fromJson(Map<String, dynamic> json) => InvoiceAddress(
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

class InvoiceLineItem {
  final String id;
  final String itemId;
  final String itemName;
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

  const InvoiceLineItem({
    required this.id,
    required this.itemId,
    required this.itemName,
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
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) => InvoiceLineItem(
        id: json['_id'] ?? '',
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
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
      );

  Map<String, dynamic> toJsonForCreate() => {
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unit': unit,
        'gstRate': gstRate,
        'discountPercent': discountPercent,
        'discountFlat': discountFlat,
      };
}

class SalesInvoiceModel {
  final String id;
  final String companyId;
  final String createdBy;
  final String invoiceNumber;
  final String invoiceType;
  final String? customerPONumber;
  final String customerId; // From object if needed
  final String customerName;
  final String? customerGSTIN;
  final InvoiceAddress? billingAddress;
  final InvoiceAddress? shippingAddress;
  final String invoiceDate;
  final String dueDate;
  final String supplyType;
  final String? placeOfSupply;
  final String? dispatchFrom;
  final bool isRCM;
  final bool isExport;
  final List<InvoiceLineItem> lineItems;
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
  final String status;
  final double paidAmount;
  final double balanceDue;
  final String? paymentTerms;
  final String? termsAndConditions;
  final String? notes;
  final bool isVoid;
  final String? createdAt;

  const SalesInvoiceModel({
    required this.id,
    required this.companyId,
    required this.createdBy,
    required this.invoiceNumber,
    required this.invoiceType,
    this.customerPONumber,
    required this.customerId,
    required this.customerName,
    this.customerGSTIN,
    this.billingAddress,
    this.shippingAddress,
    required this.invoiceDate,
    required this.dueDate,
    required this.supplyType,
    this.placeOfSupply,
    this.dispatchFrom,
    this.isRCM = false,
    this.isExport = false,
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
    required this.status,
    this.paidAmount = 0,
    this.balanceDue = 0,
    this.paymentTerms,
    this.termsAndConditions,
    this.notes,
    this.isVoid = false,
    this.createdAt,
  });

  factory SalesInvoiceModel.fromJson(Map<String, dynamic> json) {
    String custId = '';
    if (json['customerId'] is Map) {
      custId = json['customerId']['_id'] ?? '';
    } else {
      custId = json['customerId']?.toString() ?? '';
    }

    return SalesInvoiceModel(
      id: json['_id'] ?? '',
      companyId: json['companyId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceType: json['invoiceType'] ?? 'tax_invoice',
      customerPONumber: json['customerPONumber'],
      customerId: custId,
      customerName: json['customerName'] ?? '',
      customerGSTIN: json['customerGSTIN'],
      billingAddress: json['billingAddress'] != null
          ? InvoiceAddress.fromJson(json['billingAddress'])
          : null,
      shippingAddress: json['shippingAddress'] != null
          ? InvoiceAddress.fromJson(json['shippingAddress'])
          : null,
      invoiceDate: json['invoiceDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      supplyType: json['supplyType'] ?? '',
      placeOfSupply: json['placeOfSupply'],
      dispatchFrom: json['dispatchFrom'],
      isRCM: json['isRCM'] ?? false,
      isExport: json['isExport'] ?? false,
      lineItems: (json['lineItems'] as List?)
              ?.map((e) => InvoiceLineItem.fromJson(e))
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
      status: json['status'] ?? 'saved',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceDue: (json['balanceDue'] ?? 0).toDouble(),
      paymentTerms: json['paymentTerms'],
      termsAndConditions: json['termsAndConditions'],
      notes: json['notes'],
      isVoid: json['isVoid'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}
