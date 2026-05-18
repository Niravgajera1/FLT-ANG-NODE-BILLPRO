import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
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

interface Product {
  id: string;
  name: string;
  itemType: string;
  category: string;
  brand: string;
  unit: string;
  sellingPrice: number;
  gstRate: number;
  currentStock: number;
  reorderLevel: number;
  isActive: boolean;
}

interface ItemsApiResponse {
  success?: boolean;
  message?: string;
  data?: unknown;
  items?: unknown[];
}

interface ItemDeleteResponse {
  success?: boolean;
  message?: string;
}

@Component({
  selector: 'app-products',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './products.component.html',
  styleUrl: './products.component.scss'
})
export class ProductsComponent implements OnInit {
  private router = inject(Router);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);

  products = signal<Product[]>([]);
  isLoading = signal(false);
  search = signal('');

  ngOnInit(): void {
    this.loadProducts();
  }

  lowStockCount(): number {
    return this.products().filter(product => product.currentStock <= product.reorderLevel).length;
  }

  inactiveCount(): number {
    return this.products().filter(product => !product.isActive).length;
  }

  onSearch(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.search.set(input.value);
    this.loadProducts();
  }

  async loadProducts(): Promise<void> {
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
      .set('page', '1')
      .set('limit', '20')
      .set('search', this.search())
      .set('itemType', 'product');

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.get<ItemsApiResponse>(`${this.apiUrl}/api/v1/items`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params
        })
      );

      if (response?.success === false) {
        this.toast.error(response.message || 'Unable to load products.');
        return;
      }

      this.products.set(this.extractItems(response).map(item => this.toProduct(item)));
    } catch (error) {
      console.error('Get items API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load products.'));
    } finally {
      this.isLoading.set(false);
    }
  }

  editProduct(id: string): void {
    this.router.navigate(['/products', id, 'edit']);
  }

  async deleteProduct(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this product?', {
      title: 'Delete Product',
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
    if (!companyId) {
      this.toast.error('Company ID missing. Please complete company setup.');
      return;
    }

    try {
      const response = await firstValueFrom(
        this.http.delete<ItemDeleteResponse>(`${this.apiUrl}/api/v1/items/${id}`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params: new HttpParams().set('companyId', companyId)
        })
      );

      if (response?.success === false) {
        this.toast.error(response.message || 'Unable to delete product.');
        return;
      }

      this.products.update(list => list.filter(product => product.id !== id));
      this.toast.success(response?.message || 'Product deleted successfully.');
    } catch (error) {
      console.error('Delete item API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to delete product.'));
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

  private extractItems(response: ItemsApiResponse): unknown[] {
    if (Array.isArray(response)) return response;
    if (Array.isArray(response.items)) return response.items;
    if (Array.isArray(response.data)) return response.data;

    const data = response.data as Record<string, unknown> | undefined;
    if (Array.isArray(data?.['items'])) return data['items'];
    if (Array.isArray(data?.['docs'])) return data['docs'];
    if (Array.isArray(data?.['results'])) return data['results'];
    if (Array.isArray(data?.['data'])) return data['data'];

    return [];
  }

  private toProduct(item: unknown): Product {
    const value = item as Record<string, unknown>;
    return {
      id: this.asString(value['_id'] ?? value['id']),
      name: this.asString(value['name']),
      itemType: this.asString(value['itemType']),
      category: this.asString(value['category']),
      brand: this.asString(value['brand']) || '-',
      unit: this.asString(value['unit']),
      sellingPrice: this.asNumber(value['sellingPrice']),
      gstRate: this.asNumber(value['gstRate']),
      currentStock: this.asNumber(value['currentStock']),
      reorderLevel: this.asNumber(value['reorderLevel']),
      isActive: value['isActive'] !== false
    };
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
}
