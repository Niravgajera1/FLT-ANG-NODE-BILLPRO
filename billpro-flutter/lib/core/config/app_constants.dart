class AppConstants {
  AppConstants._();

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String activeCompanyIdKey = 'active_company_id';
  static const String userKey = 'user_data';

  // Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleCompanyAdmin = 'company_admin';
  static const String roleAccountant = 'accountant';
  static const String roleSalesExecutive = 'sales_executive';
  static const String rolePurchaseManager = 'purchase_manager';
  static const String roleViewer = 'viewer';

  // GST Rates
  static const List<int> gstRates = [0, 5, 12, 18, 28];

  // GST Types
  static const String gstRegular = 'regular';
  static const String gstComposition = 'composition';
  static const String gstUnregistered = 'unregistered';

  // Supply Types
  static const String supplyIntraState = 'intra_state';
  static const String supplyInterState = 'inter_state';
  static const String supplyExport = 'export';

  // Invoice Types
  static const String invoiceTax = 'tax_invoice';
  static const String invoiceProforma = 'proforma';
  static const String invoiceBillOfSupply = 'bill_of_supply';
  static const String invoiceExport = 'export_invoice';
  static const String invoiceDeliveryChallan = 'delivery_challan';
  static const String invoiceCreditNote = 'credit_note';
  static const String invoiceDebitNote = 'debit_note';

  // Bill Status
  static const String statusDraft = 'draft';
  static const String statusSaved = 'saved';
  static const String statusPaid = 'paid';
  static const String statusPartiallyPaid = 'partially_paid';
  static const String statusOverdue = 'overdue';
  static const String statusCancelled = 'cancelled';
  static const String statusVoid = 'void';

  // Business Types
  static const List<String> businessTypes = [
    'Proprietorship',
    'Partnership',
    'Private Limited',
    'LLP',
    'Public Limited',
    'HUF',
    'Trust',
    'Other',
  ];

  // Payment Terms
  static const List<String> paymentTerms = [
    'Due on Receipt',
    'Net 7',
    'Net 15',
    'Net 30',
    'Net 60',
    'Net 90',
  ];

  // Units
  static const List<String> units = [
    'pcs',
    'kg',
    'gm',
    'ltr',
    'ml',
    'mtr',
    'ft',
    'box',
    'dozen',
    'pair',
    'set',
    'nos',
  ];
}
