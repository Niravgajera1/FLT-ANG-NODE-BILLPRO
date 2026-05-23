import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { ToastService } from '../../auth/toast.service';
import { ConfirmService } from '../../ui/confirm.service';
import { AuthService } from '../../auth/auth.service';
import { API_URL } from '../../app.config';

interface ProductCategory {
  _id: string;
  companyId: string;
  name: string;
  description: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

interface CategoryResponse {
  success: boolean;
  message: string;
  data?: ProductCategory[];
  pagination?: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

interface StoredAuthUser {
  companies?: Array<{
    companyId?: unknown;
  }>;
}

@Component({
  selector: 'app-category-list',
  imports: [CommonModule, RouterLink],
  templateUrl: './category-list.html',
  styleUrl: './category-list.scss',
})
export class CategoryList {
  private http = inject(HttpClient);
  private router = inject(Router);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);
  private apiUrl = inject(API_URL);

  categories = signal<ProductCategory[]>([]);
  searchTerm = signal('');
  isLoading = signal(false);
  totalCategories = signal(0);

  filteredCategories = computed(() => {
    const search = this.searchTerm().toLowerCase().trim();

    if (!search) return this.categories();

    return this.categories().filter(x =>
      [
        x.name,
        x.description
      ].some(v => (v || '').toLowerCase().includes(search))
    );
  });

  ngOnInit(): void {
    this.loadCategories();
  }

  async loadCategories() {
    const token = this.auth.getAuthToken();
    const companyId = this.getCompanyId();

    if (!token || !companyId) {
      this.toast.error('Missing authentication');
      return;
    }

    this.isLoading.set(true);

    try {

      const params = new HttpParams()
        .set('page', '1')
        .set('limit', '20')
        .set('search', this.searchTerm())
        .set('companyId', companyId);

      const res = await firstValueFrom(
        this.http.get<CategoryResponse>(
          `${this.apiUrl}/api/v1/items/categories/list`,
          {
            params,
            headers: new HttpHeaders({
              Authorization: `Bearer ${token}`
            })
          }
        )
      );

      if (!res.success) {
        this.toast.error(res.message);
        return;
      }

      this.categories.set(res.data || []);
      this.totalCategories.set(
        res.pagination?.total ?? res.data?.length ?? 0
      );

    } catch (err) {
      console.error(err);
      this.toast.error('Failed to load categories');
    } finally {
      this.isLoading.set(false);
    }
  }

  editCategory(id: string) {
    this.router.navigate(['/category', id, 'edit']);
  }

  async deleteCategory(id: string) {

    const confirmed = await this.confirm.show(
      'Delete this category?',
      {
        title: 'Delete Category',
        confirmText: 'Delete',
        cancelText: 'Cancel'
      }
    );

    if (!confirmed) return;

    this.categories.update(x =>
      x.filter(c => c._id !== id)
    );

    this.totalCategories.update(v =>
      Math.max(0, v - 1)
    );

    this.toast.success('Category removed');
  }

  private getCompanyId(): string {

    try {

      const raw =
        localStorage.getItem('billflow_auth_user');

      const user =
        raw
          ? JSON.parse(raw)
          : null;

      const value =
        user?.companies?.[0]?.companyId;

      if (typeof value === 'string')
        return value;

      if (typeof value === 'object')
        return value?._id || '';

      return '';

    } catch {
      return '';
    }

  }
}
