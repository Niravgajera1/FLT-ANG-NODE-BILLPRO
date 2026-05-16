// ─── User Roles ───────────────────────────────────────────────────────────────
const ROLES = {
  SUPER_ADMIN: 'super_admin',
  COMPANY_ADMIN: 'company_admin',
  ACCOUNTANT: 'accountant',
  SALES_EXECUTIVE: 'sales_executive',
  PURCHASE_MANAGER: 'purchase_manager',
  VIEWER: 'viewer',
};

// ─── Permissions ──────────────────────────────────────────────────────────────
const PERMISSIONS = {
  MANAGE_COMPANY: 'manage_company',
  MANAGE_USERS: 'manage_users',
  CREATE_PURCHASE_BILL: 'create_purchase_bill',
  CREATE_SALES_INVOICE: 'create_sales_invoice',
  VIEW_REPORTS: 'view_reports',
  EXPORT_DATA: 'export_data',
  DELETE_BILLS: 'delete_bills',
  VIEW_DASHBOARD: 'view_dashboard',
  MANAGE_ITEMS: 'manage_items',
  MANAGE_VENDORS_CUSTOMERS: 'manage_vendors_customers',
};

// ─── Role → Permissions Map ───────────────────────────────────────────────────
const ROLE_PERMISSIONS = {
  [ROLES.SUPER_ADMIN]: Object.values(PERMISSIONS),
  [ROLES.COMPANY_ADMIN]: Object.values(PERMISSIONS),
  [ROLES.ACCOUNTANT]: [
    PERMISSIONS.CREATE_PURCHASE_BILL,
    PERMISSIONS.CREATE_SALES_INVOICE,
    PERMISSIONS.VIEW_REPORTS,
    PERMISSIONS.EXPORT_DATA,
    PERMISSIONS.VIEW_DASHBOARD,
    PERMISSIONS.MANAGE_ITEMS,
    PERMISSIONS.MANAGE_VENDORS_CUSTOMERS,
  ],
  [ROLES.SALES_EXECUTIVE]: [
    PERMISSIONS.CREATE_SALES_INVOICE,
    PERMISSIONS.EXPORT_DATA,
    PERMISSIONS.MANAGE_VENDORS_CUSTOMERS,
  ],
  [ROLES.PURCHASE_MANAGER]: [
    PERMISSIONS.CREATE_PURCHASE_BILL,
    PERMISSIONS.EXPORT_DATA,
    PERMISSIONS.MANAGE_ITEMS,
    PERMISSIONS.MANAGE_VENDORS_CUSTOMERS,
  ],
  [ROLES.VIEWER]: [
    PERMISSIONS.VIEW_REPORTS,
    PERMISSIONS.EXPORT_DATA,
    PERMISSIONS.VIEW_DASHBOARD,
  ],
};

// ─── GST ──────────────────────────────────────────────────────────────────────
const GST_RATES = [0, 5, 12, 18, 28];

const GST_TYPES = {
  REGULAR: 'regular',
  COMPOSITION: 'composition',
  UNREGISTERED: 'unregistered',
};

const SUPPLY_TYPES = {
  INTRA_STATE: 'intra_state',   // CGST + SGST
  INTER_STATE: 'inter_state',   // IGST
  EXPORT: 'export',             // Zero-rated
};

const ITC_TYPES = {
  FULL: 'full',
  PARTIAL: 'partial',
  BLOCKED: 'blocked',
};

// ─── Invoice Types ────────────────────────────────────────────────────────────
const INVOICE_TYPES = {
  TAX_INVOICE: 'tax_invoice',
  BILL_OF_SUPPLY: 'bill_of_supply',
  EXPORT_INVOICE: 'export_invoice',
  PROFORMA: 'proforma',
  DELIVERY_CHALLAN: 'delivery_challan',
  CREDIT_NOTE: 'credit_note',
  DEBIT_NOTE: 'debit_note',
  RECEIPT_VOUCHER: 'receipt_voucher',
};

// ─── Bill Status ──────────────────────────────────────────────────────────────
const BILL_STATUS = {
  DRAFT: 'draft',
  SAVED: 'saved',
  PAID: 'paid',
  PARTIALLY_PAID: 'partially_paid',
  OVERDUE: 'overdue',
  CANCELLED: 'cancelled',
  VOID: 'void',
};

// ─── Business Types ───────────────────────────────────────────────────────────
const BUSINESS_TYPES = [
  'Proprietorship',
  'Partnership',
  'Private Limited',
  'LLP',
  'Public Limited',
  'HUF',
  'Trust',
  'Other',
];

// ─── Indian States ────────────────────────────────────────────────────────────
const INDIAN_STATES = [
  { name: 'Andhra Pradesh', code: '37' },
  { name: 'Arunachal Pradesh', code: '12' },
  { name: 'Assam', code: '18' },
  { name: 'Bihar', code: '10' },
  { name: 'Chhattisgarh', code: '22' },
  { name: 'Goa', code: '30' },
  { name: 'Gujarat', code: '24' },
  { name: 'Haryana', code: '06' },
  { name: 'Himachal Pradesh', code: '02' },
  { name: 'Jharkhand', code: '20' },
  { name: 'Karnataka', code: '29' },
  { name: 'Kerala', code: '32' },
  { name: 'Madhya Pradesh', code: '23' },
  { name: 'Maharashtra', code: '27' },
  { name: 'Manipur', code: '14' },
  { name: 'Meghalaya', code: '17' },
  { name: 'Mizoram', code: '15' },
  { name: 'Nagaland', code: '13' },
  { name: 'Odisha', code: '21' },
  { name: 'Punjab', code: '03' },
  { name: 'Rajasthan', code: '08' },
  { name: 'Sikkim', code: '11' },
  { name: 'Tamil Nadu', code: '33' },
  { name: 'Telangana', code: '36' },
  { name: 'Tripura', code: '16' },
  { name: 'Uttar Pradesh', code: '09' },
  { name: 'Uttarakhand', code: '05' },
  { name: 'West Bengal', code: '19' },
  { name: 'Andaman & Nicobar Islands', code: '35' },
  { name: 'Chandigarh', code: '04' },
  { name: 'Dadra & Nagar Haveli and Daman & Diu', code: '26' },
  { name: 'Delhi', code: '07' },
  { name: 'Jammu & Kashmir', code: '01' },
  { name: 'Ladakh', code: '38' },
  { name: 'Lakshadweep', code: '31' },
  { name: 'Puducherry', code: '34' },
];

// ─── Payment Terms ────────────────────────────────────────────────────────────
const PAYMENT_TERMS = [
  'Due on Receipt',
  'Net 7',
  'Net 15',
  'Net 30',
  'Net 60',
  'Net 90',
];

// ─── File Upload ──────────────────────────────────────────────────────────────
const ALLOWED_MIME_TYPES = {
  IMAGES: ['image/jpeg', 'image/png', 'image/webp'],
  DOCUMENTS: ['application/pdf', 'image/jpeg', 'image/png'],
  IMPORTS: [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/csv',
  ],
};

module.exports = {
  ROLES,
  PERMISSIONS,
  ROLE_PERMISSIONS,
  GST_RATES,
  GST_TYPES,
  SUPPLY_TYPES,
  ITC_TYPES,
  INVOICE_TYPES,
  BILL_STATUS,
  BUSINESS_TYPES,
  INDIAN_STATES,
  PAYMENT_TERMS,
  ALLOWED_MIME_TYPES,
};
