import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../../auth/toast.service';
import { ConfirmService } from '../../ui/confirm.service';
import { AuthService } from '../../auth/auth.service';
import { API_URL } from '../../app.config';

interface VendorAddress {
  line1?: string;
  line2?: string;
  city?: string;
  state?: string;
  stateCode?: string;
  pinCode?: string;
}

interface Vendor {
  _id: string;
  vendorCode?: string;
  name?: string;
  displayName?: string;
  contactPerson?: string;
  mobile?: string;
  email?: string;
  creditLimit?: number;
  tags?: string[];
  billingAddress?: VendorAddress;
  isActive?: boolean;
}

interface VendorResponse {
  success: boolean;
  message: string;
  data?: Vendor[];
}

interface StoredAuthUser {
  companies?: Array<{
    companyId?: unknown;
  }>;
}

@Component({
  selector: 'app-vendor-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './vendor-list.html',
  styleUrl: './vendor-list.scss',
})
export class VendorList implements OnInit {
  togglingVendorIds = signal<string[]>([]);
  private router = inject(Router);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);

  vendors = signal<Vendor[]>([]);
  isLoading = signal(false);
  searchTerm = signal('');
  totalVendors = signal(0);

  filteredVendors = computed(() => {
    const search = this.searchTerm().trim().toLowerCase();

    if (!search) {
      return this.vendors();
    }

    return this.vendors().filter(vendor =>
      [
        vendor.vendorCode,
        vendor.name,
        vendor.displayName,
        vendor.contactPerson,
        vendor.mobile,
        vendor.email,
        vendor.tags?.join(', '),
        this.getAddressLabel(vendor)
      ].some(value => (value ?? '').toLowerCase().includes(search))
    );
  });

  ngOnInit(): void {
    this.loadVendors();
  }

  async loadVendors(): Promise<void> {
    const token = this.auth.getAuthToken();

    if (!token) {
      this.toast.error('Authentication token missing.');
      return;
    }

    const companyId = this.getCompanyId();

    this.isLoading.set(true);

    try {
      const response = await firstValueFrom(
        this.http.get<VendorResponse>(
          `${this.apiUrl}/api/v1/vendors`,
          {
            headers: new HttpHeaders({
              Authorization: `Bearer ${token}`
            }),
            params: new HttpParams().set('companyId', companyId)
          }
        )
      );

      if (!response?.success || !Array.isArray(response.data)) {
        this.toast.error(response?.message || 'Unable to load vendors');
        return;
      }

      this.vendors.set(response.data);
      this.totalVendors.set(response.data.length);

    } catch (error) {
      console.error(error);
      this.toast.error('Failed to load vendors');
    } finally {
      this.isLoading.set(false);
    }
  }

  editVendor(id: string): void {
    this.router.navigate(['/vendor', id, 'edit']);
  }

  async deleteVendor(id: string): Promise<void> {
    const confirmed = await this.confirm.show(
      'Are you sure you want to delete this vendor?',
      {
        title: 'Delete Vendor',
        confirmText: 'Delete',
        cancelText: 'Cancel'
      }
    );

    if (!confirmed) return;

    this.vendors.update(list =>
      list.filter(vendor => vendor._id !== id)
    );

    this.totalVendors.update(total => Math.max(total - 1, 0));

    this.toast.success('Vendor deleted successfully');
  }

  getAddressLabel(vendor: Vendor): string {
    const address = vendor.billingAddress;

    if (!address) {
      return 'N/A';
    }

    return [
      address.city,
      address.state,
      address.pinCode
    ].filter(Boolean).join(', ');
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

  async toggleVendorStatus(vendor: Vendor): Promise<void> {

    if (this.isStatusToggling(vendor._id)) {
      return;
    }

    const token = this.auth.getAuthToken();

    if (!token) {
      this.toast.error('Authentication token missing');
      return;
    }

    const companyId = this.getCompanyId();

    this.togglingVendorIds.update(ids => [...ids, vendor._id]);

    try {

      const response = await firstValueFrom(
        this.http.delete<any>(
          `${this.apiUrl}/api/v1/vendors/${vendor._id}`,
          {
            headers: new HttpHeaders({
              Authorization: `Bearer ${token}`
            }),
            params: new HttpParams().set('companyId', companyId)
          }
        )
      );

      if (!response?.success) {
        this.toast.error(response?.message || 'Unable to update status');
        return;
      }

      const nextStatus =
        typeof response.data?.isActive === 'boolean'
          ? response.data.isActive
          : !vendor.isActive;

      this.vendors.update(list =>
        list.map(item =>
          item._id === vendor._id
            ? { ...item, isActive: nextStatus }
            : item
        )
      );

      this.toast.success(
        `Vendor ${nextStatus ? 'activated' : 'deactivated'} successfully`
      );

    } catch (error) {
      console.error(error);
      this.toast.error('Failed to update vendor status');
    } finally {
      this.togglingVendorIds.update(ids =>
        ids.filter(id => id !== vendor._id)
      );
    }
  }

  isStatusToggling(id: string): boolean {
    return this.togglingVendorIds().includes(id);
  }
}