import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../auth/toast.service';
import { AuthService } from '../auth/auth.service';
import { API_URL } from '../app.config';

interface SalesApiResponse {
  success: boolean;
  message: string;
  data?: unknown;
}

interface StoredAuthUser {
  companies?: Array<{
    companyId?: unknown;
  }>;
}

interface CommonOption {
  id: string;
  label: string;
  name?: string;
  sellingPrice?: number;
  unitPrice?: number;
  unit?: string;
  gstRate?: number;
}

interface CommonOptionsResponse {
  success?: boolean;
  message?: string;
  data?: unknown;
  options?: unknown[];
}

@Component({
  selector: 'app-invoice-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './invoice-form.component.html',
  styleUrl: './invoice-form.component.scss'
})
export class InvoiceFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);

  form: FormGroup = this.fb.group({
    customerId: ['', Validators.required],
    invoiceType: ['tax_invoice', Validators.required],
    customerPONumber: [''],
    invoiceDate: ['', Validators.required],
    dueDate: ['', Validators.required],
    placeOfSupply: ['', Validators.required],
    dispatchFrom: [''],
    paymentTerms: ['Net 30'],
    billingAddress: this.createAddressGroup({
      label: 'Office Address',
      line1: '101, Business Heights',
      line2: 'S.G. Road',
      city: 'Ahmedabad',
      state: 'Gujarat',
      stateCode: '24',
      pinCode: '380054',
      country: 'India'
    }),
    shippingAddress: this.createAddressGroup({
      label: 'Warehouse Address',
      line1: 'Warehouse Block B',
      line2: 'Sanand GIDC',
      city: 'Ahmedabad',
      state: 'Gujarat',
      stateCode: '24',
      pinCode: '382110',
      country: 'India'
    }),
    lineItems: this.fb.array([this.createLineItem()]),
    notes: [''],
    termsAndConditions: ['']
  });

  pageTitle = 'Add Invoice';
  submitText = 'Add Invoice';
  isSubmitting = signal(false);
  isOptionsLoading = signal(false);
  customerOptions = signal<CommonOption[]>([]);
  productOptions = signal<CommonOption[]>([]);
  private invoiceId: string | null = null;

  ngOnInit(): void {
    this.loadOptions();
    this.invoiceId = this.route.snapshot.paramMap.get('id');
    const today = this.toDateInputValue(new Date());
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 30);

    this.form.patchValue({
      invoiceDate: today,
      dueDate: this.toDateInputValue(dueDate),
      notes: 'Thank you for your business!',
      termsAndConditions: 'Payment is strictly due within 30 days of the invoice date.'
    });

    if (this.invoiceId) {
      this.pageTitle = 'Edit Invoice';
      this.submitText = 'Save Changes';
      this.form.patchValue({
        customerId: '6a099177af60543817e3929f',
        invoiceType: 'tax_invoice',
        customerPONumber: 'PO-998877',
        placeOfSupply: 'Gujarat',
        dispatchFrom: 'Warehouse A',
        paymentTerms: 'Net 30'
      });
      this.lineItems.clear();
      this.lineItems.push(this.createLineItem({
        itemId: '664c134b0d3ab33c14a87d02',
        itemName: 'Premium Wireless Mouse',
        quantity: 2,
        unitPrice: 1500,
        unit: 'pcs',
        gstRate: 18,
        discountPercent: 10,
        discountFlat: 0
      }));
      this.lineItems.push(this.createLineItem({
        itemId: '664c138f0d3ab33c14a87e50',
        itemName: 'Ergonomic Office Keyboard',
        quantity: 1,
        unitPrice: 2500,
        unit: 'pcs',
        gstRate: 18,
        discountPercent: 0,
        discountFlat: 200
      }));
    }
  }

  get lineItems(): FormArray {
    return this.form.get('lineItems') as FormArray;
  }

  cancel(): void {
    this.router.navigate(['/create-invoice']);
  }

  addLineItem(): void {
    this.lineItems.push(this.createLineItem());
  }

  onProductSelected(index: number): void {
    const itemGroup = this.lineItems.at(index) as FormGroup;
    const selected = this.productOptions().find(option => option.id === itemGroup.get('itemId')?.value);
    if (!selected) {
      return;
    }

    itemGroup.patchValue({
      itemName: selected.name || selected.label,
      unitPrice: selected.sellingPrice ?? selected.unitPrice ?? itemGroup.get('unitPrice')?.value,
      unit: selected.unit || itemGroup.get('unit')?.value,
      gstRate: selected.gstRate ?? itemGroup.get('gstRate')?.value
    });
  }

  removeLineItem(index: number): void {
    if (this.lineItems.length === 1) {
      this.toast.error('At least one line item is required.');
      return;
    }

    this.lineItems.removeAt(index);
  }

  lineTotal(item: FormGroup): number {
    const quantity = Number(item.get('quantity')?.value) || 0;
    const unitPrice = Number(item.get('unitPrice')?.value) || 0;
    const gstRate = Number(item.get('gstRate')?.value) || 0;
    const discountPercent = Number(item.get('discountPercent')?.value) || 0;
    const discountFlat = Number(item.get('discountFlat')?.value) || 0;
    const gross = quantity * unitPrice;
    const discount = (gross * discountPercent / 100) + discountFlat;
    const taxable = Math.max(gross - discount, 0);
    return taxable + (taxable * gstRate / 100);
  }

  invoiceTotal(): number {
    return this.lineItems.controls.reduce((total, control) => total + this.lineTotal(control as FormGroup), 0);
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.toast.error('Please correct the form errors before submitting.');
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
      const response = await firstValueFrom(
        this.http.post<SalesApiResponse>(`${this.apiUrl}/api/v1/sales`, this.toPayload(), {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` }),
          params: new HttpParams().set('companyId', companyId)
        })
      );

      if (!response?.success) {
        this.toast.error(response?.message || 'Could not create invoice.');
        return;
      }

      this.toast.success(response.message || 'Invoice created successfully.');
      this.router.navigate(['/create-invoice']);
    } catch (error) {
      console.error('Create sales invoice API error:', error);
      this.toast.error(this.getApiMessage(error, 'Could not create invoice.'));
    } finally {
      this.isSubmitting.set(false);
    }
  }

  private createLineItem(value?: Record<string, unknown>): FormGroup {
    return this.fb.group({
      itemId: [value?.['itemId'] ?? '', Validators.required],
      itemName: [value?.['itemName'] ?? '', Validators.required],
      quantity: [value?.['quantity'] ?? 1, [Validators.required, Validators.min(1)]],
      unitPrice: [value?.['unitPrice'] ?? 0, [Validators.required, Validators.min(0)]],
      unit: [value?.['unit'] ?? 'pcs', Validators.required],
      gstRate: [value?.['gstRate'] ?? 18, [Validators.required, Validators.min(0)]],
      discountPercent: [value?.['discountPercent'] ?? 0, [Validators.min(0)]],
      discountFlat: [value?.['discountFlat'] ?? 0, [Validators.min(0)]]
    });
  }

  private async loadOptions(): Promise<void> {
    const companyId = this.getCompanyId();
    if (!companyId) {
      return;
    }

    this.isOptionsLoading.set(true);
    try {
      const [products, customers] = await Promise.all([
        this.loadCommonOptions(companyId, 1),
        this.loadCommonOptions(companyId, 2)
      ]);

      this.productOptions.set(products);
      this.customerOptions.set(customers);
    } catch (error) {
      console.error('Common options API error:', error);
      this.toast.error(this.getApiMessage(error, 'Could not load customer and product options.'));
    } finally {
      this.isOptionsLoading.set(false);
    }
  }

  private async loadCommonOptions(companyId: string, type: 1 | 2): Promise<CommonOption[]> {
    const response = await firstValueFrom(
      this.http.get<CommonOptionsResponse>(`${this.apiUrl}/api/v1/common/options/${companyId}?type=${type}`, {
        withCredentials: true
      })
    );

    if (response?.success === false) {
      throw new Error(response.message || 'Could not load options.');
    }

    return this.extractOptions(response).map(option => this.toOption(option));
  }

  private extractOptions(response: CommonOptionsResponse): unknown[] {
    if (Array.isArray(response)) return response;
    if (Array.isArray(response.options)) return response.options;
    if (Array.isArray(response.data)) return response.data;

    const data = response.data as Record<string, unknown> | undefined;
    if (Array.isArray(data?.['options'])) return data['options'];
    if (Array.isArray(data?.['items'])) return data['items'];
    if (Array.isArray(data?.['customers'])) return data['customers'];
    if (Array.isArray(data?.['products'])) return data['products'];
    if (Array.isArray(data?.['data'])) return data['data'];

    return [];
  }

  private toOption(option: unknown): CommonOption {
    const value = option as Record<string, unknown>;
    const id = this.asString(value['_id'] ?? value['id'] ?? value['value']);
    const name = this.asString(value['name'] ?? value['itemName'] ?? value['displayName'] ?? value['label']);
    return {
      id,
      label: name || id,
      name,
      sellingPrice: this.asOptionalNumber(value['sellingPrice']),
      unitPrice: this.asOptionalNumber(value['unitPrice'] ?? value['price']),
      unit: this.asString(value['unit']),
      gstRate: this.asOptionalNumber(value['gstRate'])
    };
  }

  private toPayload(): Record<string, unknown> {
    const value = this.form.value;
    return {
      companyId: this.getCompanyId(),
      customerId: value.customerId,
      invoiceType: value.invoiceType,
      customerPONumber: value.customerPONumber,
      invoiceDate: new Date(value.invoiceDate).toISOString(),
      dueDate: new Date(value.dueDate).toISOString(),
      placeOfSupply: value.placeOfSupply,
      dispatchFrom: value.dispatchFrom,
      paymentTerms: value.paymentTerms,
      lineItems: value.lineItems.map((item: Record<string, unknown>) => {
        const payload: Record<string, unknown> = {
          itemId: item['itemId'],
          itemName: item['itemName'],
          quantity: Number(item['quantity']) || 0,
          unitPrice: Number(item['unitPrice']) || 0,
          unit: item['unit'],
          gstRate: Number(item['gstRate']) || 0
        };
        const discountPercent = Number(item['discountPercent']) || 0;
        const discountFlat = Number(item['discountFlat']) || 0;
        if (discountPercent > 0) payload['discountPercent'] = discountPercent;
        if (discountFlat > 0) payload['discountFlat'] = discountFlat;
        return payload;
      }),
      billingAddress: value.billingAddress,
      shippingAddress: value.shippingAddress,
      notes: value.notes,
      termsAndConditions: value.termsAndConditions
    };
  }

  private createAddressGroup(value?: Record<string, unknown>): FormGroup {
    return this.fb.group({
      label: [value?.['label'] ?? ''],
      line1: [value?.['line1'] ?? '', Validators.required],
      line2: [value?.['line2'] ?? ''],
      city: [value?.['city'] ?? '', Validators.required],
      state: [value?.['state'] ?? '', Validators.required],
      stateCode: [value?.['stateCode'] ?? ''],
      pinCode: [value?.['pinCode'] ?? '', Validators.required],
      country: [value?.['country'] ?? 'India', Validators.required]
    });
  }

  private toDateInputValue(date: Date): string {
    return date.toISOString().slice(0, 10);
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

  private asString(value: unknown): string {
    return typeof value === 'string' ? value : '';
  }

  private normalizeId(value: unknown): string {
    if (typeof value === 'string') {
      return value;
    }

    if (value && typeof value === 'object') {
      const record = value as Record<string, unknown>;
      return this.asString(record['_id'] ?? record['id'] ?? record['value']);
    }

    return '';
  }

  private asOptionalNumber(value: unknown): number | undefined {
    if (typeof value === 'number') return value;
    if (typeof value === 'string' && value.trim()) return Number(value) || 0;
    return undefined;
  }
}
