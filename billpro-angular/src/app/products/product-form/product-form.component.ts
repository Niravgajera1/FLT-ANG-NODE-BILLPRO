import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../../auth/toast.service';
import { AuthService } from '../../auth/auth.service';
import { API_URL } from '../../app.config';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';

interface OptionResponse {
  success: boolean;
  message: string;

  data?: Array<{
    id?: string;
    _id?: string;
    label?: string;
    name?: string;
    value?: string;
  }>;
}

interface ItemApiResponse {
  success: boolean;
  message: string;
  data?: unknown;
  item?: unknown;
}

interface StoredAuthUser {
  companies?: Array<{
    companyId?: unknown;
  }>;
}

@Component({
  selector: 'app-product-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './product-form.component.html',
  styleUrl: './product-form.component.scss'
})
export class ProductFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);


  form: FormGroup = this.fb.group({
    name: ['', Validators.required],
    description: [''],
    itemType: ['product', Validators.required],
    hsnCode: [''],
    sacCode: [''],
    category: ['', Validators.required],
    brand: [''],
    unit: ['pcs', Validators.required],
    sellingPrice: [0, [Validators.required, Validators.min(0)]],
    purchasePrice: [0, [Validators.required, Validators.min(0)]],
    mrp: [0, [Validators.required, Validators.min(0)]],
    priceInclGST: [false],
    gstRate: [18, [Validators.required, Validators.min(0)]],
    cessRate: [0, [Validators.required, Validators.min(0)]],
    isExempt: [false],
    itcEligibility: ['full', Validators.required],
    trackInventory: [true],
    openingStock: [0, [Validators.required, Validators.min(0)]],
    currentStock: [0, [Validators.required, Validators.min(0)]],
    reorderLevel: [0, [Validators.required, Validators.min(0)]],
    reorderQuantity: [0, [Validators.required, Validators.min(0)]],
    warehouseLocation: [''],
    batchTracking: [false],
    valuationMethod: ['WAC', Validators.required],
    avgCost: [0, [Validators.required, Validators.min(0)]],
    isActive: [true],
    is_selling: [true],
    notes: [''],
    companyId: ['', Validators.required],
    image: [null]
  });

  pageTitle = 'Add Product';
  submitText = 'Add Product';
  isSubmitting = signal(false);
  isLoading = signal(false);
  selectedImageName = signal('');
  private productId: string | null = null;

  categoryOptions = signal<
    Array<{
      id: string;
      label: string;
    }>
  >([]);


  ngOnInit(): void {

    const companyId =
      this.getCompanyId();

    if (companyId) {

      this.form.patchValue({
        companyId
      });

      this.loadCategories(
        companyId
      );

    }

    this.productId =
      this.route.snapshot.paramMap.get('id');

    if (this.productId) {

      this.pageTitle =
        'Edit Product';

      this.submitText =
        'Save Changes';

      this.loadProduct(
        this.productId
      );

    }

  }


  private async loadCategories(
    companyId: string
  ): Promise<void> {

    const token =
      this.auth.getAuthToken();

    if (!token)
      return;

    try {

      const response =
        await firstValueFrom(

          this.http.get<OptionResponse>(

            `${this.apiUrl}/api/v1/common/options/${companyId}`,

            {

              headers:
                new HttpHeaders({

                  Authorization:
                    `Bearer ${token}`

                }),

              params:
                new HttpParams()
                  .set(
                    'type',
                    '4'
                  )

            }

          )

        );

      if (
        !response.success
      ) {
        return;
      }

      this.categoryOptions.set(

        (response.data || [])

          .map(

            item => ({

              id:

                item.id ||

                item._id ||

                item.value ||

                '',

              label:

                item.label ||

                item.name ||

                ''

            })

          )

      );

    }

    catch (error) {

      console.error(
        'Category load failed',
        error
      );

    }
  }


  cancel(): void {
    this.router.navigate(['/products']);
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    this.form.patchValue({ image: file });
    this.selectedImageName.set(file?.name ?? '');
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.toast.error('Please fix the highlighted fields before saving.');
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

    this.isSubmitting.set(true);
    try {
      const options = {
        headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
        params: new HttpParams().set('companyId', companyId)
      };

      const request = this.productId
        ? this.http.put<ItemApiResponse>(`${this.apiUrl}/api/v1/items/${this.productId}`, this.toFormData(), options)
        : this.http.post<ItemApiResponse>(`${this.apiUrl}/api/v1/items`, this.toFormData(), options);

      const response = await firstValueFrom(request);

      if (!response?.success) {
        this.toast.error(response?.message || 'Unable to save product. Please try again.');
        return;
      }

      this.toast.success(response.message || (this.productId ? 'Product updated successfully.' : 'Product added successfully.'));
      this.router.navigate(['/products']);
    } catch (error) {
      console.error('Save item API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to save product. Please try again.'));
    } finally {
      this.isSubmitting.set(false);
    }
  }

  private async loadProduct(id: string): Promise<void> {
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

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.get<ItemApiResponse>(`${this.apiUrl}/api/v1/items/${id}`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params: new HttpParams().set('companyId', companyId)
        })
      );

      if (response?.success === false) {
        this.toast.error(response.message || 'Unable to load product details.');
        return;
      }

      const item = this.extractItem(response);
      if (!item) {
        this.toast.error('Product details not found.');
        return;
      }

      this.patchProduct(item);
    } catch (error) {
      console.error('Get item detail API error:', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load product details.'));
    } finally {
      this.isLoading.set(false);
    }
  }

  private extractItem(response: ItemApiResponse): Record<string, unknown> | null {
    if (response.item && typeof response.item === 'object') {
      return response.item as Record<string, unknown>;
    }

    if (response.data && typeof response.data === 'object' && !Array.isArray(response.data)) {
      const data = response.data as Record<string, unknown>;
      if (data['item'] && typeof data['item'] === 'object') {
        return data['item'] as Record<string, unknown>;
      }
      if (data['product'] && typeof data['product'] === 'object') {
        return data['product'] as Record<string, unknown>;
      }
      if (data['details'] && typeof data['details'] === 'object') {
        return data['details'] as Record<string, unknown>;
      }
      if (data['data'] && typeof data['data'] === 'object' && !Array.isArray(data['data'])) {
        return data['data'] as Record<string, unknown>;
      }
      return data;
    }

    return null;
  }

  private patchProduct(item: Record<string, unknown>): void {
    this.form.patchValue({
      name: this.asString(item['name']),
      description: this.asString(item['description']),
      itemType: this.asString(item['itemType']) || 'product',
      hsnCode: this.asString(item['hsnCode']),
      sacCode: this.asString(item['sacCode']),
      category: this.normalizeId(item['category'] ?? item['categoryId']),
      brand: this.asString(item['brand']),
      unit: this.asString(item['unit']) || 'pcs',
      sellingPrice: this.asNumber(item['sellingPrice']),
      purchasePrice: this.asNumber(item['purchasePrice']),
      mrp: this.asNumber(item['mrp']),
      priceInclGST: this.asBoolean(item['priceInclGST']),
      gstRate: this.asNumber(item['gstRate']),
      cessRate: this.asNumber(item['cessRate']),
      isExempt: this.asBoolean(item['isExempt']),
      itcEligibility: this.asString(item['itcEligibility']) || 'full',
      trackInventory: item['trackInventory'] !== false,
      openingStock: this.asNumber(item['openingStock']),
      currentStock: this.asNumber(item['currentStock']),
      reorderLevel: this.asNumber(item['reorderLevel']),
      reorderQuantity: this.asNumber(item['reorderQuantity']),
      warehouseLocation: this.asString(item['warehouseLocation']),
      batchTracking: this.asBoolean(item['batchTracking']),
      valuationMethod: this.asString(item['valuationMethod']) || 'WAC',
      avgCost: this.asNumber(item['avgCost']),
      isActive: item['isActive'] !== false,
      is_selling: this.asBoolean(item['is_selling'] ?? item['isSelling'] ?? item['is_Selling']),
      notes: this.asString(item['notes']),
      companyId: this.asString(item['companyId']) || this.getCompanyId()
    });
  }

  private toFormData(): FormData {
    const formData = new FormData();
    const values = this.form.value;

    Object.keys(values).forEach(key => {
      const value = values[key];
      if (key === 'image') {
        if (value instanceof File) {
          formData.append('image', value);
        }
        return;
      }

      formData.append(key, value ?? '');
    });

    return formData;
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
      return this.asString(record['_id'] ?? record['id'] ?? record['value']);
    }
    return '';
  }

  private asString(value: unknown): string {
    if (typeof value === 'string') return value;
    if (value && typeof value === 'object' && '_id' in value) {
      const id = (value as { _id?: unknown })._id;
      return typeof id === 'string' ? id : '';
    }
    return '';
  }

  private asNumber(value: unknown): number {
    if (typeof value === 'number') return value;
    if (typeof value === 'string') return Number(value) || 0;
    return 0;
  }

  private asBoolean(value: unknown): boolean {
    if (typeof value === 'boolean') return value;
    if (typeof value === 'string') return value === 'true';
    return false;
  }
}
