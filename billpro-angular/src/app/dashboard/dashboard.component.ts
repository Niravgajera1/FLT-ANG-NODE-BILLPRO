import { Component, Inject, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { BaseChartDirective, provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartOptions } from 'chart.js';
import { API_URL } from '../app.config';
import { AuthService } from '../auth/auth.service';
import { ToastService } from '../auth/toast.service';

interface StoredAuthUser {
  businessInfo?: {
    _id?: unknown;
    fyStartMonth?: number;
  };
  companies?: Array<{
    companyId?: unknown;
  }>;
}

interface DashboardApiResponse {
  success: boolean;
  message: string;
  data?: DashboardSummary;
}

interface DashboardSummary {
  kpis: DashboardKpis;
  salesTrend: MonthlySales[];
  salesVsPurchase: {
    salesData: MonthlyTotal[];
    purchaseData: MonthlyTotal[];
  };
  topCustomers: TopCustomer[];
  invoiceStatus: InvoiceStatus[];
  recentSalesInvoices: SalesInvoice[];
  recentPurchaseBills: PurchaseBill[];
  lowStockAlerts: LowStockAlert[];
  topSellingProducts: TopProduct[];
}

interface DashboardKpis {
  totalSales: KpiValue;
  totalPurchases: KpiValue;
  grossProfit: { value: number; change?: number | null };
  netReceivable: { value: number; overdue: number };
  netPayable: { value: number; overdue: number };
  totalInvoices: { value: number };
  totalBills: { value: number };
  inventoryValue: { value: number };
  activeCustomers: { value: number };
  activeVendors: { value: number };
  overdueInvoices: { count: number; value: number };
  gstPayable: { value: number };
}

interface KpiValue {
  value: number;
  change?: number | null;
  prevValue?: number;
}

interface MonthlyKey {
  year: number;
  month: number;
}

interface MonthlySales {
  _id: MonthlyKey;
  sales: number;
  invoices: number;
  taxAmount: number;
}

interface MonthlyTotal {
  _id: MonthlyKey;
  total: number;
}

interface TopCustomer {
  _id: string;
  customerName: string;
  totalRevenue: number;
  invoiceCount: number;
}

interface InvoiceStatus {
  _id: string;
  count: number;
  value: number;
}

interface SalesInvoice {
  _id: string;
  invoiceNumber: string;
  customerName: string;
  invoiceDate: string;
  dueDate: string;
  grandTotal: number;
  status: string;
  paidAmount: number;
  balanceDue: number;
}

interface PurchaseBill {
  _id: string;
  billNumber: string;
  vendorBillNumber: string;
  vendorName: string;
  billDate: string;
  dueDate: string;
  grandTotal: number;
  status: string;
  paidAmount: number;
  balanceDue: number;
}

interface LowStockAlert {
  _id?: string;
  name?: string;
  currentStock?: number;
  reorderLevel?: number;
}

interface TopProduct {
  _id: string;
  name: string;
  totalQuantity: number;
  totalRevenue: number;
  avgUnitPrice: number;
}

interface KpiCard {
  label: string;
  value: string;
  subLabel: string;
  tone: 'emerald' | 'blue' | 'amber' | 'red' | 'slate';
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, BaseChartDirective],
  templateUrl: './dashboard.component.html',
  providers: [provideCharts(withDefaultRegisterables())]
})
export class DashboardComponent implements OnInit {
  auth = inject(AuthService);
  private toast = inject(ToastService);
  private http = inject(HttpClient);

  summary = signal<DashboardSummary | null>(null);
  isLoading = signal(false);
  errorMessage = signal('');
  dateRangeLabel = signal('');

  readonly salesTrendType: ChartConfiguration<'line'>['type'] = 'line';
  readonly salesVsPurchaseType: ChartConfiguration<'bar'>['type'] = 'bar';

  readonly chartOptions: ChartOptions<'line' | 'bar'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        labels: {
          boxWidth: 10,
          boxHeight: 10,
          usePointStyle: true
        }
      }
    },
    scales: {
      x: {
        grid: {
          display: false
        }
      },
      y: {
        beginAtZero: true,
        ticks: {
          callback: value => this.compactCurrency(Number(value))
        }
      }
    }
  };

  salesTrendData: ChartData<'line'> = {
    labels: [],
    datasets: [
      {
        label: 'Sales',
        data: [],
        borderColor: '#2563eb',
        backgroundColor: 'rgba(37, 99, 235, 0.14)',
        fill: true,
        tension: 0.35,
        pointRadius: 4,
        pointBackgroundColor: '#2563eb'
      },
      {
        label: 'Tax',
        data: [],
        borderColor: '#0f766e',
        backgroundColor: 'rgba(15, 118, 110, 0.1)',
        fill: true,
        tension: 0.35,
        pointRadius: 4,
        pointBackgroundColor: '#0f766e'
      }
    ]
  };

  salesVsPurchaseData: ChartData<'bar'> = {
    labels: [],
    datasets: [
      {
        label: 'Sales',
        data: [],
        backgroundColor: '#2563eb',
        borderRadius: 8
      },
      {
        label: 'Purchases',
        data: [],
        backgroundColor: '#f59e0b',
        borderRadius: 8
      }
    ]
  };

  constructor(@Inject(API_URL) private apiUrl: string) {}

  ngOnInit(): void {
    this.loadSummary();
  }

  async loadSummary(): Promise<void> {
    const token = this.auth.getAuthToken();
    const companyId = this.getCompanyId();

    if (!token || !companyId) {
      this.errorMessage.set('Login and company details are required to load the dashboard.');
      return;
    }

    const fyStartMonth = this.getFyStartMonth();
    const { startDate, endDate } = this.getFiscalDateRange(fyStartMonth);
    this.dateRangeLabel.set(`${this.formatShortDate(startDate)} - ${this.formatShortDate(endDate)}`);
    this.isLoading.set(true);
    this.errorMessage.set('');

    try {
      const response = await firstValueFrom(
        this.http.get<DashboardApiResponse>(`${this.apiUrl}/api/v1/dashboard/summary`, {
          headers: new HttpHeaders({
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
            'x-company-id': companyId
          }),
          params: new HttpParams()
            .set('fyStartMonth', fyStartMonth)
            .set('startDate', startDate)
            .set('endDate', endDate),
          withCredentials: true
        })
      );

      if (!response?.success || !response.data) {
        throw new Error(response?.message || 'Dashboard summary could not be loaded.');
      }

      this.summary.set(response.data);
      this.updateCharts(response.data);
    } catch (error) {
      const message = this.getApiMessage(error, 'Unable to load dashboard summary.');
      this.errorMessage.set(message);
      this.toast.error(message);
    } finally {
      this.isLoading.set(false);
    }
  }

  get kpiCards(): KpiCard[] {
    const kpis = this.summary()?.kpis;
    if (!kpis) return [];

    return [
      {
        label: 'Total Sales',
        value: this.currency(kpis.totalSales.value),
        subLabel: this.changeLabel(kpis.totalSales.change, kpis.totalSales.prevValue),
        tone: 'emerald'
      },
      {
        label: 'Total Purchases',
        value: this.currency(kpis.totalPurchases.value),
        subLabel: this.changeLabel(kpis.totalPurchases.change, kpis.totalPurchases.prevValue),
        tone: 'amber'
      },
      {
        label: 'Gross Profit',
        value: this.currency(kpis.grossProfit.value),
        subLabel: kpis.grossProfit.value >= 0 ? 'Profit this period' : 'Loss this period',
        tone: kpis.grossProfit.value >= 0 ? 'emerald' : 'red'
      },
      {
        label: 'GST Payable',
        value: this.currency(kpis.gstPayable.value),
        subLabel: 'Estimated tax liability',
        tone: 'blue'
      },
      {
        label: 'Net Receivable',
        value: this.currency(kpis.netReceivable.value),
        subLabel: `${this.currency(kpis.netReceivable.overdue)} overdue`,
        tone: 'blue'
      },
      {
        label: 'Net Payable',
        value: this.currency(kpis.netPayable.value),
        subLabel: `${this.currency(kpis.netPayable.overdue)} overdue`,
        tone: 'amber'
      },
      {
        label: 'Invoices / Bills',
        value: `${kpis.totalInvoices.value} / ${kpis.totalBills.value}`,
        subLabel: 'Sales invoices and purchase bills',
        tone: 'slate'
      },
      {
        label: 'Customers / Vendors',
        value: `${kpis.activeCustomers.value} / ${kpis.activeVendors.value}`,
        subLabel: 'Active business contacts',
        tone: 'slate'
      }
    ];
  }

  currency(value: number | null | undefined): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 2
    }).format(Number(value) || 0);
  }

  compactCurrency(value: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      notation: 'compact',
      maximumFractionDigits: 1
    }).format(value || 0);
  }

  formatDate(value: string): string {
    return new Intl.DateTimeFormat('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    }).format(new Date(value));
  }

  statusClass(status: string): string {
    const normalized = status.toLowerCase();
    if (normalized.includes('paid')) return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200';
    if (normalized.includes('overdue') || normalized.includes('cancel')) return 'bg-red-50 text-red-700 ring-1 ring-red-200';
    if (normalized.includes('save') || normalized.includes('draft')) return 'bg-blue-50 text-blue-700 ring-1 ring-blue-200';
    return 'bg-amber-50 text-amber-700 ring-1 ring-amber-200';
  }

  toneClass(tone: KpiCard['tone']): string {
    return {
      emerald: 'bg-emerald-50 text-emerald-700 ring-emerald-100',
      blue: 'bg-blue-50 text-blue-700 ring-blue-100',
      amber: 'bg-amber-50 text-amber-700 ring-amber-100',
      red: 'bg-red-50 text-red-700 ring-red-100',
      slate: 'bg-slate-50 text-slate-700 ring-slate-100'
    }[tone];
  }

  logout(): void {
    this.toast.success('You have been signed out. See you soon!');
    setTimeout(() => this.auth.logout(), 700);
  }

  get istGreeting(): string {
    const nowInIST = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }));
    const hour = nowInIST.getHours();

    if (hour < 12) return 'Good morning';
    if (hour < 16) return 'Good afternoon';
    if (hour < 20) return 'Good evening';
    return 'Good night';
  }

  private updateCharts(summary: DashboardSummary): void {
    const trendLabels = summary.salesTrend.map(item => this.monthLabel(item._id));
    this.salesTrendData = {
      labels: trendLabels,
      datasets: [
        { ...this.salesTrendData.datasets[0], data: summary.salesTrend.map(item => item.sales) },
        { ...this.salesTrendData.datasets[1], data: summary.salesTrend.map(item => item.taxAmount) }
      ]
    };

    const allKeys = new Map<string, MonthlyKey>();
    [...summary.salesVsPurchase.salesData, ...summary.salesVsPurchase.purchaseData].forEach(item => {
      allKeys.set(this.monthKey(item._id), item._id);
    });
    const keys = [...allKeys.values()].sort((a, b) => a.year - b.year || a.month - b.month);
    const salesMap = new Map(summary.salesVsPurchase.salesData.map(item => [this.monthKey(item._id), item.total]));
    const purchaseMap = new Map(summary.salesVsPurchase.purchaseData.map(item => [this.monthKey(item._id), item.total]));

    this.salesVsPurchaseData = {
      labels: keys.map(key => this.monthLabel(key)),
      datasets: [
        { ...this.salesVsPurchaseData.datasets[0], data: keys.map(key => salesMap.get(this.monthKey(key)) ?? 0) },
        { ...this.salesVsPurchaseData.datasets[1], data: keys.map(key => purchaseMap.get(this.monthKey(key)) ?? 0) }
      ]
    };
  }

  private getCompanyId(): string {
    try {
      const raw = localStorage.getItem('billflow_auth_user');
      const user = raw ? JSON.parse(raw) as StoredAuthUser : null;
      return this.normalizeId(user?.companies?.[0]?.companyId) || this.normalizeId(user?.businessInfo?._id);
    } catch {
      return '';
    }
  }

  private getFyStartMonth(): number {
    try {
      const raw = localStorage.getItem('billflow_auth_user');
      const user = raw ? JSON.parse(raw) as StoredAuthUser : null;
      return user?.businessInfo?.fyStartMonth || this.auth.currentUser()?.businessInfo?.fyStartMonth || 4;
    } catch {
      return this.auth.currentUser()?.businessInfo?.fyStartMonth || 4;
    }
  }

  private getFiscalDateRange(fyStartMonth: number): { startDate: string; endDate: string } {
    const today = new Date();
    const startYear = today.getMonth() + 1 >= fyStartMonth ? today.getFullYear() : today.getFullYear() - 1;
    return {
      startDate: this.toDateParam(new Date(startYear, fyStartMonth - 1, 1)),
      endDate: this.toDateParam(today)
    };
  }

  private toDateParam(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatShortDate(value: string): string {
    return new Intl.DateTimeFormat('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    }).format(new Date(value));
  }

  private monthLabel(key: MonthlyKey): string {
    return new Intl.DateTimeFormat('en-IN', {
      month: 'short',
      year: '2-digit'
    }).format(new Date(key.year, key.month - 1, 1));
  }

  private monthKey(key: MonthlyKey): string {
    return `${key.year}-${String(key.month).padStart(2, '0')}`;
  }

  private changeLabel(change?: number | null, previous?: number): string {
    if (typeof change === 'number') {
      const sign = change > 0 ? '+' : '';
      return `${sign}${change.toFixed(1)}% vs previous period`;
    }

    if (typeof previous === 'number') {
      return `${this.currency(previous)} previous period`;
    }

    return 'No previous period data';
  }

  private normalizeId(value: unknown): string {
    if (typeof value === 'string') return value;
    if (value && typeof value === 'object') {
      const record = value as Record<string, unknown>;
      return this.asString(record['_id'] ?? record['id'] ?? record['value']);
    }
    return '';
  }

  private asString(value: unknown): string {
    return typeof value === 'string' ? value : '';
  }

  private getApiMessage(error: unknown, fallback: string): string {
    if (error instanceof Error && error.message) {
      return error.message;
    }

    if (error && typeof error === 'object' && 'error' in error) {
      const apiError = (error as { error?: { message?: unknown } }).error;
      if (typeof apiError?.message === 'string' && apiError.message.trim()) {
        return apiError.message;
      }
    }

    return fallback;
  }
}
