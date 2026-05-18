import { Component, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../auth/toast.service';
import { ConfirmService } from '../ui/confirm.service';
import { AuthService } from '../auth/auth.service';
import { API_URL } from '../app.config';

interface StoredAuthUser {
  companies?: Array<{
    companyId?: unknown;
  }>;
}

interface Invoice {
  id: string;
  customerId: string;
  invoiceType: string;
  customerPONumber: string;
  invoiceDate: string;
  dueDate: string;
  placeOfSupply: string;
  paymentTerms: string;
  lineItems: number;
  total: number;
  status: 'Paid' | 'Due' | 'Overdue';
}

interface SalesApiResponse {
  success?: boolean;
  message?: string;
  data?: unknown;
  sales?: unknown[];
}

@Component({
  selector: 'app-create-invoice',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './create-invoice.component.html',
  styleUrl: './create-invoice.component.scss'
})
export class CreateInvoiceComponent implements OnInit, OnDestroy {
  private router = inject(Router);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);
  private sanitizer = inject(DomSanitizer);

  invoices = signal<Invoice[]>([]);
  isLoading = signal(false);
  previewLoadingId = signal('');
  pdfPreviewUrl = signal<SafeResourceUrl | null>(null);
  search = signal('');
  invoiceType = signal('');
  status = signal('');
  private pdfObjectUrl = '';

  ngOnInit(): void {
    this.loadInvoices();
  }

  ngOnDestroy(): void {
    this.revokePdfObjectUrl();
  }

  dueCount(): number {
    return this.invoices().filter(invoice => invoice.status === 'Due').length;
  }

  overdueCount(): number {
    return this.invoices().filter(invoice => invoice.status === 'Overdue').length;
  }

  onSearch(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.search.set(input.value);
    this.loadInvoices();
  }

  async loadInvoices(): Promise<void> {
    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    const companyId = this.getCompanyId();
    if (!companyId) {
      this.toast.error('Company ID missing. Please complete company setup.');
      return;
    }

    const params = new HttpParams()
      .set('companyId', companyId)
      .set('invoiceType', this.invoiceType())
      .set('status', this.status())
      .set('search', this.search());

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.get<SalesApiResponse>(`${this.apiUrl}/api/v1/sales`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params
        })
      );

      if (response?.success === false) {
        this.toast.error(response.message || 'Unable to load invoices.');
        return;
      }

      this.invoices.set(this.extractSales(response).map(item => this.toInvoice(item)));
    } catch (error) {
      console.error('Get sales invoices API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load invoices.'));
    } finally {
      this.isLoading.set(false);
    }
  }

  editInvoice(id: string): void {
    this.router.navigate(['/create-invoice', id, 'edit']);
  }

  async previewInvoice(id: string): Promise<void> {
    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    const companyId = this.getCompanyId();
    if (!companyId) {
      this.toast.error('Company ID missing. Please complete company setup.');
      return;
    }

    this.previewLoadingId.set(id);
    try {
      const blob = await firstValueFrom(
        this.http.get(`${this.apiUrl}/api/v1/sales/${id}/pdf`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params: new HttpParams().set('companyId', companyId),
          responseType: 'blob'
        })
      );

      this.revokePdfObjectUrl();
      this.pdfObjectUrl = URL.createObjectURL(blob);
      this.pdfPreviewUrl.set(this.sanitizer.bypassSecurityTrustResourceUrl(this.pdfObjectUrl));
    } catch (error) {
      console.error('Invoice PDF preview API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load invoice PDF.'));
    } finally {
      this.previewLoadingId.set('');
    }
  }

  closePreview(): void {
    this.pdfPreviewUrl.set(null);
    this.revokePdfObjectUrl();
  }

  async deleteInvoice(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this invoice?', {
      title: 'Delete Invoice',
      confirmText: 'Delete',
      cancelText: 'Cancel'
    });
    if (!confirmed) {
      return;
    }

    this.invoices.update(list => list.filter(invoice => invoice.id !== id));
    this.toast.success('Invoice deleted successfully.');
  }

  private getCompanyId(): string {
    try {
      const raw = localStorage.getItem('billflow_auth_user');
      const user = raw ? JSON.parse(raw) as StoredAuthUser : null;
      return this.normalizeId(user?.companies?.[0]?.companyId);
    } catch {
      return '';
    }
  }

  private normalizeId(value: unknown): string {
    if (typeof value === 'string') return value;
    if (value && typeof value === 'object') {
      const record = value as Record<string, unknown>;
      return this.asString(record['_id'] ?? record['id'] ?? record['value']);
    }
    return '';
  }

  private extractSales(response: SalesApiResponse): unknown[] {
    if (Array.isArray(response)) return response;
    if (Array.isArray(response.sales)) return response.sales;
    if (Array.isArray(response.data)) return response.data;

    const data = response.data as Record<string, unknown> | undefined;
    if (Array.isArray(data?.['sales'])) return data['sales'];
    if (Array.isArray(data?.['invoices'])) return data['invoices'];
    if (Array.isArray(data?.['docs'])) return data['docs'];
    if (Array.isArray(data?.['results'])) return data['results'];
    if (Array.isArray(data?.['data'])) return data['data'];

    return [];
  }

  private toInvoice(item: unknown): Invoice {
    const value = item as Record<string, unknown>;
    const lineItems = value['lineItems'];
    return {
      id: this.asString(value['_id'] ?? value['id']),
      customerId: this.customerLabel(value['customerId'] ?? value['customer']),
      invoiceType: this.asString(value['invoiceType']),
      customerPONumber: this.asString(value['customerPONumber']),
      invoiceDate: this.formatDate(value['invoiceDate']),
      dueDate: this.formatDate(value['dueDate']),
      placeOfSupply: this.asString(value['placeOfSupply']),
      paymentTerms: this.asString(value['paymentTerms']),
      lineItems: Array.isArray(lineItems) ? lineItems.length : this.asNumber(value['lineItems']),
      total: this.asNumber(value['grandTotal'] ?? value['total'] ?? value['totalAmount'] ?? value['netAmount']),
      status: this.toStatus(value['status'])
    };
  }

  private customerLabel(value: unknown): string {
    if (typeof value === 'string') return value;
    if (value && typeof value === 'object') {
      const customer = value as Record<string, unknown>;
      return this.asString(customer['displayName'] ?? customer['name'] ?? customer['_id'] ?? customer['id']);
    }
    return '';
  }

  private toStatus(value: unknown): 'Paid' | 'Due' | 'Overdue' {
    const status = this.asString(value).toLowerCase();
    if (status === 'paid') return 'Paid';
    if (status === 'overdue') return 'Overdue';
    return 'Due';
  }

  private formatDate(value: unknown): string {
    if (typeof value !== 'string' || !value) return '';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toISOString().slice(0, 10);
  }

  private asString(value: unknown): string {
    return typeof value === 'string' ? value : '';
  }

  private asNumber(value: unknown): number {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') return Number(value) || 0;
    return 0;
  }

  private getApiMessage(error: unknown, fallback: string): string {
    if (error && typeof error === 'object' && 'error' in error) {
      const apiError = (error as { error?: { message?: unknown } }).error;
      if (typeof apiError?.message === 'string' && apiError.message.trim()) {
        return apiError.message;
      }
    }

    return fallback;
  }

  private revokePdfObjectUrl(): void {
    if (this.pdfObjectUrl) {
      URL.revokeObjectURL(this.pdfObjectUrl);
      this.pdfObjectUrl = '';
    }
  }
}
