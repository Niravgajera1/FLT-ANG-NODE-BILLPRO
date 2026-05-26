/// Models for the Dashboard Summary API response.

class DashboardSummary {
  final DashboardKpis kpis;
  final List<SalesTrendItem> salesTrend;
  final SalesVsPurchase salesVsPurchase;
  final List<TopCustomer> topCustomers;
  final List<InvoiceStatusItem> invoiceStatus;
  final List<RecentSalesInvoice> recentSalesInvoices;
  final List<RecentPurchaseBill> recentPurchaseBills;
  final List<LowStockAlert> lowStockAlerts;
  final List<TopSellingProduct> topSellingProducts;

  DashboardSummary({
    required this.kpis,
    required this.salesTrend,
    required this.salesVsPurchase,
    required this.topCustomers,
    required this.invoiceStatus,
    required this.recentSalesInvoices,
    required this.recentPurchaseBills,
    required this.lowStockAlerts,
    required this.topSellingProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      kpis: DashboardKpis.fromJson(json['kpis'] ?? {}),
      salesTrend: (json['salesTrend'] as List<dynamic>?)
              ?.map((e) => SalesTrendItem.fromJson(e))
              .toList() ??
          [],
      salesVsPurchase:
          SalesVsPurchase.fromJson(json['salesVsPurchase'] ?? {}),
      topCustomers: (json['topCustomers'] as List<dynamic>?)
              ?.map((e) => TopCustomer.fromJson(e))
              .toList() ??
          [],
      invoiceStatus: (json['invoiceStatus'] as List<dynamic>?)
              ?.map((e) => InvoiceStatusItem.fromJson(e))
              .toList() ??
          [],
      recentSalesInvoices: (json['recentSalesInvoices'] as List<dynamic>?)
              ?.map((e) => RecentSalesInvoice.fromJson(e))
              .toList() ??
          [],
      recentPurchaseBills: (json['recentPurchaseBills'] as List<dynamic>?)
              ?.map((e) => RecentPurchaseBill.fromJson(e))
              .toList() ??
          [],
      lowStockAlerts: (json['lowStockAlerts'] as List<dynamic>?)
              ?.map((e) => LowStockAlert.fromJson(e))
              .toList() ??
          [],
      topSellingProducts: (json['topSellingProducts'] as List<dynamic>?)
              ?.map((e) => TopSellingProduct.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// ── KPIs ──────────────────────────────────────────────────────────────────────

class KpiValue {
  final double value;
  final double? change;
  final double? prevValue;
  final double? overdue;
  final int? count;

  KpiValue({
    required this.value,
    this.change,
    this.prevValue,
    this.overdue,
    this.count,
  });

  factory KpiValue.fromJson(Map<String, dynamic> json) {
    return KpiValue(
      value: (json['value'] ?? 0).toDouble(),
      change: json['change']?.toDouble(),
      prevValue: json['prevValue']?.toDouble(),
      overdue: json['overdue']?.toDouble(),
      count: json['count']?.toInt(),
    );
  }
}

class DashboardKpis {
  final KpiValue totalSales;
  final KpiValue totalPurchases;
  final KpiValue grossProfit;
  final KpiValue netReceivable;
  final KpiValue netPayable;
  final KpiValue totalInvoices;
  final KpiValue totalBills;
  final KpiValue inventoryValue;
  final KpiValue activeCustomers;
  final KpiValue activeVendors;
  final KpiValue overdueInvoices;
  final KpiValue gstPayable;

  DashboardKpis({
    required this.totalSales,
    required this.totalPurchases,
    required this.grossProfit,
    required this.netReceivable,
    required this.netPayable,
    required this.totalInvoices,
    required this.totalBills,
    required this.inventoryValue,
    required this.activeCustomers,
    required this.activeVendors,
    required this.overdueInvoices,
    required this.gstPayable,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalSales: KpiValue.fromJson(json['totalSales'] ?? {}),
      totalPurchases: KpiValue.fromJson(json['totalPurchases'] ?? {}),
      grossProfit: KpiValue.fromJson(json['grossProfit'] ?? {}),
      netReceivable: KpiValue.fromJson(json['netReceivable'] ?? {}),
      netPayable: KpiValue.fromJson(json['netPayable'] ?? {}),
      totalInvoices: KpiValue.fromJson(json['totalInvoices'] ?? {}),
      totalBills: KpiValue.fromJson(json['totalBills'] ?? {}),
      inventoryValue: KpiValue.fromJson(json['inventoryValue'] ?? {}),
      activeCustomers: KpiValue.fromJson(json['activeCustomers'] ?? {}),
      activeVendors: KpiValue.fromJson(json['activeVendors'] ?? {}),
      overdueInvoices: KpiValue.fromJson(json['overdueInvoices'] ?? {}),
      gstPayable: KpiValue.fromJson(json['gstPayable'] ?? {}),
    );
  }
}

// ── Sales Trend ───────────────────────────────────────────────────────────────

class SalesTrendItem {
  final int year;
  final int month;
  final double sales;
  final int invoices;
  final double taxAmount;

  SalesTrendItem({
    required this.year,
    required this.month,
    required this.sales,
    required this.invoices,
    required this.taxAmount,
  });

  factory SalesTrendItem.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? {};
    return SalesTrendItem(
      year: id['year'] ?? 0,
      month: id['month'] ?? 0,
      sales: (json['sales'] ?? 0).toDouble(),
      invoices: (json['invoices'] ?? 0).toInt(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
    );
  }
}

// ── Sales vs Purchase ─────────────────────────────────────────────────────────

class MonthlyTotal {
  final int year;
  final int month;
  final double total;

  MonthlyTotal({required this.year, required this.month, required this.total});

  factory MonthlyTotal.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? {};
    return MonthlyTotal(
      year: id['year'] ?? 0,
      month: id['month'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class SalesVsPurchase {
  final List<MonthlyTotal> salesData;
  final List<MonthlyTotal> purchaseData;

  SalesVsPurchase({required this.salesData, required this.purchaseData});

  factory SalesVsPurchase.fromJson(Map<String, dynamic> json) {
    return SalesVsPurchase(
      salesData: (json['salesData'] as List<dynamic>?)
              ?.map((e) => MonthlyTotal.fromJson(e))
              .toList() ??
          [],
      purchaseData: (json['purchaseData'] as List<dynamic>?)
              ?.map((e) => MonthlyTotal.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// ── Top Customers ─────────────────────────────────────────────────────────────

class TopCustomer {
  final String id;
  final String customerName;
  final double totalRevenue;
  final int invoiceCount;

  TopCustomer({
    required this.id,
    required this.customerName,
    required this.totalRevenue,
    required this.invoiceCount,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: json['_id'] ?? '',
      customerName: json['customerName'] ?? '',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      invoiceCount: (json['invoiceCount'] ?? 0).toInt(),
    );
  }
}

// ── Invoice Status ────────────────────────────────────────────────────────────

class InvoiceStatusItem {
  final String status;
  final int count;
  final double value;

  InvoiceStatusItem({
    required this.status,
    required this.count,
    required this.value,
  });

  factory InvoiceStatusItem.fromJson(Map<String, dynamic> json) {
    return InvoiceStatusItem(
      status: json['_id'] ?? '',
      count: (json['count'] ?? 0).toInt(),
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

// ── Recent Sales Invoices ─────────────────────────────────────────────────────

class RecentSalesInvoice {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double grandTotal;
  final String status;
  final double paidAmount;
  final double balanceDue;

  RecentSalesInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.invoiceDate,
    this.dueDate,
    required this.grandTotal,
    required this.status,
    required this.paidAmount,
    required this.balanceDue,
  });

  factory RecentSalesInvoice.fromJson(Map<String, dynamic> json) {
    return RecentSalesInvoice(
      id: json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'])
          : null,
      dueDate:
          json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceDue: (json['balanceDue'] ?? 0).toDouble(),
    );
  }
}

// ── Recent Purchase Bills ─────────────────────────────────────────────────────

class RecentPurchaseBill {
  final String id;
  final String billNumber;
  final String vendorBillNumber;
  final String vendorName;
  final DateTime? billDate;
  final DateTime? dueDate;
  final double grandTotal;
  final String status;
  final double paidAmount;
  final double balanceDue;

  RecentPurchaseBill({
    required this.id,
    required this.billNumber,
    required this.vendorBillNumber,
    required this.vendorName,
    this.billDate,
    this.dueDate,
    required this.grandTotal,
    required this.status,
    required this.paidAmount,
    required this.balanceDue,
  });

  factory RecentPurchaseBill.fromJson(Map<String, dynamic> json) {
    return RecentPurchaseBill(
      id: json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      vendorBillNumber: json['vendorBillNumber'] ?? '',
      vendorName: json['vendorName'] ?? '',
      billDate: json['billDate'] != null
          ? DateTime.tryParse(json['billDate'])
          : null,
      dueDate:
          json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      balanceDue: (json['balanceDue'] ?? 0).toDouble(),
    );
  }
}

// ── Low Stock Alerts ──────────────────────────────────────────────────────────

class LowStockAlert {
  final String id;
  final String name;
  final int currentStock;
  final int reorderLevel;

  LowStockAlert({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.reorderLevel,
  });

  factory LowStockAlert.fromJson(Map<String, dynamic> json) {
    return LowStockAlert(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      currentStock: (json['currentStock'] ?? 0).toInt(),
      reorderLevel: (json['reorderLevel'] ?? 0).toInt(),
    );
  }
}

// ── Top Selling Products ──────────────────────────────────────────────────────

class TopSellingProduct {
  final String id;
  final String name;
  final int totalQuantity;
  final double totalRevenue;
  final double avgUnitPrice;

  TopSellingProduct({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.avgUnitPrice,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      totalQuantity: (json['totalQuantity'] ?? 0).toInt(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      avgUnitPrice: (json['avgUnitPrice'] ?? 0).toDouble(),
    );
  }
}
