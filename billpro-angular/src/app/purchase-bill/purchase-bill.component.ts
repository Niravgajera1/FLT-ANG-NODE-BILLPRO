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

interface PurchaseBill {
  id: string;
  vendorId: string;
  vendorBillNumber: string;
  vendorBillDate: string;
  billDate: string;
  dueDate: string;
  placeOfSupply: string;
  paymentTerms: string;
  lineItems: number;
  total: number;
  status: 'Paid' | 'Due' | 'Overdue';
}

interface PurchaseApiResponse {
  success?: boolean;
  message?: string;
  data?: unknown;
  purchases?: unknown[];
}

@Component({
  selector: 'app-purchase-bill',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './purchase-bill.component.html',
  styleUrl: './purchase-bill.component.scss'
})
export class PurchaseBillComponent implements OnInit, OnDestroy {
  private router = inject(Router);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);
  private sanitizer = inject(DomSanitizer);

  bills = signal<PurchaseBill[]>([]);
  isLoading = signal(false);
  previewLoadingId = signal('');
  pdfPreviewUrl = signal<SafeResourceUrl | null>(null);
  search = signal('');
  status = signal('');
  private pdfObjectUrl = '';

  ngOnInit(): void {
    this.loadBills();
  }

  ngOnDestroy(): void {
    this.revokePdfObjectUrl();
  }

  dueCount(): number {
    return this.bills().filter(bill => bill.status === 'Due').length;
  }

  overdueCount(): number {
    return this.bills().filter(bill => bill.status === 'Overdue').length;
  }

  onSearch(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.search.set(input.value);
    this.loadBills();
  }

  async loadBills(): Promise<void> {
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
      .set('status', this.status())
      .set('search', this.search());

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.get<PurchaseApiResponse>(`${this.apiUrl}/api/v1/purchase`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params
        })
      );

      if (response?.success === false) {
        this.toast.error(response.message || 'Unable to load purchase bills.');
        return;
      }

      this.bills.set(this.extractBills(response).map(item => this.toBill(item)));
    } catch (error) {
      console.error('Get purchase bills API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load purchase bills.'));
    } finally {
      this.isLoading.set(false);
    }
  }

  editBill(id: string): void {
    this.router.navigate(['/purchase-bill', id, 'edit']);
  }

  async previewBill(id: string): Promise<void> {
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
        this.http.get(`${this.apiUrl}/api/v1/purchase/${id}/pdf`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params: new HttpParams().set('companyId', companyId),
          responseType: 'blob'
        })
      );

      this.revokePdfObjectUrl();
      this.pdfObjectUrl = URL.createObjectURL(blob);
      this.pdfPreviewUrl.set(this.sanitizer.bypassSecurityTrustResourceUrl(this.pdfObjectUrl));
    } catch (error) {
      console.error('Purchase bill PDF preview API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load purchase bill PDF.'));
    } finally {
      this.previewLoadingId.set('');
    }
  }

  closePreview(): void {
    this.pdfPreviewUrl.set(null);
    this.revokePdfObjectUrl();
  }

  async deleteBill(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this purchase bill?', {
      title: 'Delete Purchase Bill',
      confirmText: 'Delete',
      cancelText: 'Cancel'
    });
    if (!confirmed) {
      return;
    }

    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    const companyId = this.getCompanyId();
    try {
      await firstValueFrom(
        this.http.delete(`${this.apiUrl}/api/v1/purchase/${id}`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params: new HttpParams().set('companyId', companyId)
        })
      );
      this.bills.update(list => list.filter(bill => bill.id !== id));
      this.toast.success('Purchase bill deleted successfully.');
    } catch (error) {
      console.error('Delete purchase bill API error:', error);
      this.toast.error(this.getApiMessage(error, 'Could not delete purchase bill.'));
    }
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

  private extractBills(response: PurchaseApiResponse): unknown[] {
    if (Array.isArray(response)) return response;
    if (Array.isArray(response.purchases)) return response.purchases;
    if (Array.isArray(response.data)) return response.data;

    const data = response.data as Record<string, unknown> | undefined;
    if (Array.isArray(data?.['purchases'])) return data['purchases'];
    if (Array.isArray(data?.['bills'])) return data['bills'];
    if (Array.isArray(data?.['docs'])) return data['docs'];
    if (Array.isArray(data?.['results'])) return data['results'];
    if (Array.isArray(data?.['data'])) return data['data'];

    return [];
  }

  private toBill(item: unknown): PurchaseBill {
    const value = item as Record<string, unknown>;
    const lineItems = value['lineItems'];
    return {
      id: this.asString(value['_id'] ?? value['id']),
      vendorId: this.vendorLabel(value['vendorId'] ?? value['vendor']),
      vendorBillNumber: this.asString(value['vendorBillNumber']),
      vendorBillDate: this.formatDate(value['vendorBillDate']),
      billDate: this.formatDate(value['billDate']),
      dueDate: this.formatDate(value['dueDate']),
      placeOfSupply: this.asString(value['placeOfSupply']),
      paymentTerms: this.asString(value['paymentTerms']),
      lineItems: Array.isArray(lineItems) ? lineItems.length : this.asNumber(value['lineItems']),
      total: this.asNumber(value['grandTotal'] ?? value['total'] ?? value['totalAmount'] ?? value['netAmount']),
      status: this.toStatus(value['status'])
    };
  }

  private vendorLabel(value: unknown): string {
    if (typeof value === 'string') return value;
    if (value && typeof value === 'object') {
      const vendor = value as Record<string, unknown>;
      return this.asString(vendor['displayName'] ?? vendor['name'] ?? vendor['_id'] ?? vendor['id']);
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
