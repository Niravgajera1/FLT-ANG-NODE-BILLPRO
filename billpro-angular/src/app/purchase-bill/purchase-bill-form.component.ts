import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../auth/toast.service';
import { AuthService } from '../auth/auth.service';
import { API_URL } from '../app.config';

interface PurchaseApiResponse {
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
  selector: 'app-purchase-bill-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './purchase-bill-form.component.html',
  styleUrl: './purchase-bill-form.component.scss'
})
export class PurchaseBillFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);

  form: FormGroup = this.fb.group({
    vendorId: ['', Validators.required],
    vendorBillNumber: [''],
    vendorBillDate: ['', Validators.required],
    billDate: ['', Validators.required],
    dueDate: ['', Validators.required],
    poReference: [''],
    placeOfSupply: ['', Validators.required],
    isRCM: [false],
    paymentTerms: ['Net 30'],
    narration: [''],
    tags: [''],
    lineItems: this.fb.array([this.createLineItem()]),
    notes: [''],
    termsAndConditions: ['']
  });

  pageTitle = 'Add Purchase Bill';
  submitText = 'Create Purchase Bill';
  isSubmitting = signal(false);
  isOptionsLoading = signal(false);
  vendorOptions = signal<CommonOption[]>([]);
  productOptions = signal<CommonOption[]>([]);
  private billId: string | null = null;

  ngOnInit(): void {
    this.loadOptions();
    this.billId = this.route.snapshot.paramMap.get('id');
    const today = this.toDateInputValue(new Date());
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 30);

    this.form.patchValue({
      vendorBillDate: today,
      billDate: today,
      dueDate: this.toDateInputValue(dueDate),
      notes: '',
      termsAndConditions: 'Payment is strictly due within 30 days of the bill date.'
    });

    if (this.billId) {
      this.pageTitle = 'Edit Purchase Bill';
      this.submitText = 'Save Changes';
      this.loadBillForEdit(this.billId);
    }
  }

  get lineItems(): FormArray {
    return this.form.get('lineItems') as FormArray;
  }

  cancel(): void {
    this.router.navigate(['/purchase-bill']);
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
    const cessRate = Number(item.get('cessRate')?.value) || 0;
    const discountPercent = Number(item.get('discountPercent')?.value) || 0;
    const discountFlat = Number(item.get('discountFlat')?.value) || 0;
    const gross = quantity * unitPrice;
    const discount = (gross * discountPercent / 100) + discountFlat;
    const taxable = Math.max(gross - discount, 0);
    return taxable + (taxable * (gstRate + cessRate) / 100);
  }

  billTotal(): number {
    return this.lineItems.controls.reduce((total, control) => total + this.lineTotal(control as FormGroup), 0);
  }

  async onSubmit(): Promise<void> {

    if (this.form.invalid) {

      this.form.markAllAsTouched();

      this.toast.error(
        'Please correct form errors.'
      );

      return;

    }

    const token =
      this.auth.getAuthToken();

    const companyId =
      this.getCompanyId();

    if (
      !token ||
      !companyId
    ) {

      this.toast.error(
        'Authentication failed.'
      );

      return;

    }

    this.isSubmitting.set(
      true
    );

    try {

      const payload =
        this.toPayload();

      const request =

        this.billId

          ?

          this.http.put<PurchaseApiResponse>(

            `${this.apiUrl}/api/v1/purchase/${this.billId}`,

            payload,

            {

              headers:
                new HttpHeaders({

                  Authorization:
                    `Bearer ${token}`,

                  'Content-Type':
                    'application/json'

                }),

              params:
                new HttpParams()

                  .set(
                    'companyId',
                    companyId
                  )

            }

          )

          :

          this.http.post<PurchaseApiResponse>(

            `${this.apiUrl}/api/v1/purchase`,

            payload,

            {

              headers:
                new HttpHeaders({

                  Authorization:
                    `Bearer ${token}`,

                  'Content-Type':
                    'application/json'

                }),

              params:
                new HttpParams()

                  .set(
                    'companyId',
                    companyId
                  )

            }

          );

      const response =
        await firstValueFrom(
          request
        );

      if (
        !response?.success
      ) {

        this.toast.error(
          response.message
          ||
          'Save failed'
        );

        return;

      }

      this.toast.success(

        response.message ||

        (

          this.billId

            ?

            'Purchase bill updated'

            :

            'Purchase bill created'

        )

      );

      this.router.navigate([
        '/purchase-bill'
      ]);

    }

    catch (error) {

      console.error(
        error
      );

      this.toast.error(

        this.getApiMessage(

          error,

          'Unable to save'

        )

      );

    }

    finally {

      this.isSubmitting.set(
        false
      );

    }

  }

  private async loadBillForEdit(
    id: string
  ) {

    const token =
      this.auth.getAuthToken();

    const companyId =
      this.getCompanyId();

    if (
      !token ||
      !companyId
    ) return;

    this.isSubmitting.set(
      true
    );

    try {

      const response: any =

        await firstValueFrom(

          this.http.get(

            `${this.apiUrl}/api/v1/purchase/${id}`,

            {

              headers:
                new HttpHeaders({

                  Authorization:
                    `Bearer ${token}`

                }),

              params:
                new HttpParams()

                  .set(
                    'companyId',
                    companyId
                  )

            }

          )

        );

      if (
        !response?.success
      ) {

        this.toast.error(
          response.message
        );

        return;

      }

      this.patchPurchase(

        response.data
        ||
        response

      );

    }

    catch (error) {

      this.toast.error(

        this.getApiMessage(

          error,

          'Unable to load bill'

        )

      );

    }

    finally {

      this.isSubmitting.set(
        false
      );

    }

  }

  private createLineItem(value?: Record<string, unknown>): FormGroup {
    return this.fb.group({
      itemId: [value?.['itemId'] ?? '', Validators.required],
      itemName: [value?.['itemName'] ?? '', Validators.required],
      description: [value?.['description'] ?? ''],
      hsnCode: [value?.['hsnCode'] ?? ''],
      quantity: [value?.['quantity'] ?? 1, [Validators.required, Validators.min(1)]],
      unitPrice: [value?.['unitPrice'] ?? 0, [Validators.required, Validators.min(0)]],
      unit: [value?.['unit'] ?? 'pcs', Validators.required],
      gstRate: [value?.['gstRate'] ?? 18, [Validators.required, Validators.min(0)]],
      cessRate: [value?.['cessRate'] ?? 0, [Validators.min(0)]],
      discountPercent: [value?.['discountPercent'] ?? 0, [Validators.min(0)]],
      discountFlat: [value?.['discountFlat'] ?? 0, [Validators.min(0)]],
      batchNumber: [value?.['batchNumber'] ?? ''],
      batchExpiry: [value?.['batchExpiry'] ? this.toDateInputValue(new Date(value['batchExpiry'] as string)) : '']
    });
  }

  private async loadOptions(): Promise<void> {
    const companyId = this.getCompanyId();
    if (!companyId) {
      return;
    }

    this.isOptionsLoading.set(true);
    try {
      const [products, vendors] = await Promise.all([
        this.loadCommonOptions(companyId, 1, 2),
        this.loadCommonOptions(companyId, 3)
      ]);

      this.productOptions.set(products);
      this.vendorOptions.set(vendors);
    } catch (error) {
      console.error('Common options API error:', error);
      this.toast.error(this.getApiMessage(error, 'Could not load vendor and product options.'));
    } finally {
      this.isOptionsLoading.set(false);
    }
  }

  private async loadCommonOptions(companyId: string, type: number, forType = 0): Promise<CommonOption[]> {
    const response = await firstValueFrom(
      this.http.get<CommonOptionsResponse>(`${this.apiUrl}/api/v1/common/options/${companyId}?type=${type}&forType=${forType}`, {
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
    if (Array.isArray(data?.['vendors'])) return data['vendors'];
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

  private toPayload() {

    const value =
      this.form.value;

    return {

      vendorId:
        value.vendorId,

      vendorBillNumber:
        value.vendorBillNumber,

      vendorBillDate:
        new Date(
          String(
            value.vendorBillDate
          )
        ).toISOString(),

      dueDate:
        new Date(
          String(
            value.dueDate
          )
        ).toISOString(),

      poReference:
        value.poReference,

      paymentTerms:
        value.paymentTerms,

      placeOfSupply:
        value.placeOfSupply,

      isRCM:
        value.isRCM,

      narration:
        value.narration,

      vendorAddress:
        value.vendorAddress,

      lineItems:

        (value.lineItems as any[])

          .map(

            item => ({

              itemId:
                item.itemId,

              itemName:
                item.itemName,

              description:
                item.description,

              quantity:
                Number(
                  item.quantity
                ),

              unitPrice:
                Number(
                  item.unitPrice
                ),

              discountPercent:
                Number(
                  item.discountPercent
                ) || 0,

              discountFlat:
                Number(
                  item.discountFlat
                ) || 0,

              gstRate:
                Number(
                  item.gstRate
                ) || 0

            })

          ),

      notes:
        value.notes,

      termsAndConditions:
        value.termsAndConditions

    };

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

  private patchPurchase(
    bill: any
  ) {

    this.form.patchValue({

      vendorId:
        bill.vendorId?._id
        ||
        bill.vendorId,

      vendorBillNumber:
        bill.vendorBillNumber,

      vendorBillDate:
        this.toDate(
          bill.vendorBillDate
        ),

      billDate:
        this.toDate(
          bill.billDate
        ),

      dueDate:
        this.toDate(
          bill.dueDate
        ),

      poReference:
        bill.poReference,

      placeOfSupply:
        bill.placeOfSupply,

      isRCM:
        bill.isRCM,

      paymentTerms:
        bill.paymentTerms,

      narration:
        bill.narration,

      notes:
        bill.notes,

      termsAndConditions:
        bill.termsAndConditions

    });

    this.lineItems.clear();

    (
      bill.lineItems
      ||
      []
    )

      .forEach(

        (item: any) => {

          this.lineItems.push(

            this.createLineItem({

              itemId:
                item.itemId?._id
                ||
                item.itemId,

              itemName:
                item.itemName,

              description:
                item.description,

              quantity:
                item.quantity,

              unitPrice:
                item.unitPrice,

              gstRate:
                item.gstRate,

              discountPercent:
                item.discountPercent,

              discountFlat:
                item.discountFlat

            })

          );

        }

      );

  }

  private toDate(
    value: string
  ) {

    if (
      !value
    )
      return '';

    return value
      .slice(
        0,
        10
      );

  }
}
