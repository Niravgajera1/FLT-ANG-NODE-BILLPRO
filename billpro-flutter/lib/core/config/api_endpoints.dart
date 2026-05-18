class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String loginOtp = '/auth/login/otp';
  static const String loginOtpVerify = '/auth/login/otp/verify';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Companies
  static const String companies = '/companies';
  static String validateGstin(String gstin) =>
      '/companies/validate/gstin/$gstin';
  static String validateIfsc(String ifsc) => '/companies/validate/ifsc/$ifsc';
  static const String branches = '/companies/branches';
  static String updateBranch(String id) => '/companies/branches/$id';
  static const String bankAccounts = '/companies/bank-accounts';

  // Vendors
  static const String vendors = '/vendors';
  static String vendor(String id) => '/vendors/$id';

  // Customers
  static const String customers = '/customers';
  static String customer(String id) => '/customers/$id';

  // Items
  static const String items = '/items';
  static String item(String id) => '/items/$id';

  // Purchase
  static const String purchase = '/purchase';
  static String purchaseBill(String id) => '/purchase/$id';
  static const String purchaseOutstanding = '/purchase/outstanding';

  // Sales
  static const String sales = '/sales';
  static String salesInvoice(String id) => '/sales/$id';
  static String convertInvoice(String id) => '/sales/$id/convert';
  static const String salesAging = '/sales/aging';

  // Dashboard
  static const String dashboardKpis = '/dashboard/kpis';
  static const String salesTrend = '/dashboard/sales-trend';
  static const String salesVsPurchase = '/dashboard/sales-vs-purchase';
  static const String topCustomers = '/dashboard/top-customers';
  static const String invoiceStatus = '/dashboard/invoice-status';
  static const String gstSummary = '/dashboard/gst-summary';

  // Reports
  static const String salesRegisterExcel = '/reports/sales-register/excel';
  static const String purchaseRegisterExcel = '/reports/purchase-register/excel';
  static const String gstr1Json = '/reports/gstr1/json';
}
