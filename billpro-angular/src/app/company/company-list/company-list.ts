import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../../auth/toast.service';
import { ConfirmService } from '../../ui/confirm.service';
import { AuthService } from '../../auth/auth.service';
import { API_URL } from '../../app.config';

interface CustomerAddress {
  label?: string;
  line1?: string;
  line2?: string;
  city?: string;
  state?: string;
  stateCode?: string;
  pinCode?: string;
  country?: string;
  isDefault?: boolean;
  _id?: string;
}

interface Customer {
  _id: string;
  customerCode: string;
  name: string;
  displayName?: string;
  customerType?: string;
  contactPerson?: string;
  mobile?: string;
  email?: string;
  addresses?: CustomerAddress[];
  paymentTerms?: string;
  creditLimit?: number;
  customerGroup?: string;
  isActive: boolean;
}

interface CustomerResponse {
  success: boolean;
  message: string;
  data?: Customer[];
  pagination?: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

interface CustomerToggleResponse {
  success: boolean;
  message: string;
  data?: Partial<Customer>;
}

interface StoredAuthUser {
  companies?: Array<{
    companyId?: unknown;
  }>;
}

@Component({
  selector: 'app-company-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './company-list.html',
  styleUrl: './company-list.scss',
})
export class CompanyList implements OnInit {
  private router = inject(Router);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);

  customers = signal<Customer[]>([]);
  isLoading = signal(false);
  searchTerm = signal('');
  totalCustomers = signal(0);
  togglingCustomerIds = signal<string[]>([]);

  filteredCustomers = computed(() => {
    const search = this.searchTerm().trim().toLowerCase();
    if (!search) {
      return this.customers();
    }

    return this.customers().filter(customer =>
      [
        customer.customerCode,
        customer.name,
        customer.displayName,
        customer.customerType,
        customer.contactPerson,
        customer.mobile,
        customer.email,
        customer.customerGroup,
        this.getAddressLabel(customer)
      ].some(value => (value ?? '').toLowerCase().includes(search))
    );
  });

  ngOnInit(): void {
    this.loadCustomers();
  }

  async loadCustomers(): Promise<void> {
    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.get<CustomerResponse>(`${this.apiUrl}/api/v1/customers`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` })
        })
      );

      if (!response?.success || !Array.isArray(response.data)) {
        this.toast.error(response?.message || 'Could not load customers.');
        this.customers.set([]);
        this.totalCustomers.set(0);
        return;
      }

      this.customers.set(response.data);
      this.totalCustomers.set(response.pagination?.total ?? response.data.length);
    } catch (error) {
      console.error('Unable to load customers', error);
      this.toast.error(this.getApiMessage(error, 'Could not load customers. Check your network and try again.'));
      this.customers.set([]);
      this.totalCustomers.set(0);
    } finally {
      this.isLoading.set(false);
    }
  }

  editCompany(id: string): void {
    this.router.navigate(['/customer', id, 'edit']);
  }

  async deleteCompany(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this customer?', {
      title: 'Delete Customer',
      confirmText: 'Delete',
      cancelText: 'Cancel'
    });
    if (!confirmed) {
      return;
    }

    this.customers.update(list => list.filter(customer => customer._id !== id));
    this.totalCustomers.update(total => Math.max(total - 1, 0));
    this.toast.success('Customer deleted successfully.');
  }

  async toggleCompanyStatus(customer: Customer): Promise<void> {
    if (this.isStatusToggling(customer._id)) {
      return;
    }

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

    this.togglingCustomerIds.update(ids => [...ids, customer._id]);
    try {
      const response = await firstValueFrom(
        this.http.patch<CustomerToggleResponse>(
          `${this.apiUrl}/api/v1/customers/${customer._id}/toggle-status`,
          {},
          {
            headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
            params: new HttpParams().set('companyId', companyId)
          }
        )
      );

      if (!response?.success) {
        this.toast.error(response?.message || 'Could not update customer status.');
        return;
      }

      const nextStatus = typeof response.data?.isActive === 'boolean'
        ? response.data.isActive
        : !customer.isActive;

      this.customers.update(list =>
        list.map(item => item._id === customer._id ? { ...item, isActive: nextStatus } : item)
      );
      this.toast.success(response.message || `Customer ${nextStatus ? 'activated' : 'deactivated'} successfully.`);
    } catch (error) {
      console.error('Unable to toggle customer status', error);
      this.toast.error(this.getApiMessage(error, 'Could not update customer status.'));
    } finally {
      this.togglingCustomerIds.update(ids => ids.filter(id => id !== customer._id));
    }
  }

  isStatusToggling(id: string): boolean {
    return this.togglingCustomerIds().includes(id);
  }

  getAddressLabel(customer: Customer): string {
    const address = customer.addresses?.find(item => item.isDefault) ?? customer.addresses?.[0];
    if (!address) {
      return 'N/A';
    }

    return [
      address.city,
      address.state,
      address.pinCode
    ].filter(Boolean).join(', ') || 'N/A';
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
      const id = record['_id'] ?? record['id'] ?? record['value'];
      return typeof id === 'string' ? id : '';
    }
    return '';
  }
}
