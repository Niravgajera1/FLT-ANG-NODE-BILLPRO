import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { ToastService } from '../../auth/toast.service';
import { AuthService } from '../../auth/auth.service';
import { API_URL } from '../../app.config';

interface CustomerSaveResponse {
  success: boolean;
  message: string;
  data?: unknown;
}

interface CustomerAddress {
  _id?: string;
  label?: string;
  line1?: string;
  line2?: string;
  city?: string;
  state?: string;
  stateCode?: string;
  pinCode?: string;
  country?: string;
  isDefault?: boolean;
}

interface Customer {
  _id?: string;
  name?: string;
  displayName?: string;
  customerType?: string;
  gstin?: string;
  pan?: string;
  isGSTRegistered?: boolean;
  contactPerson?: string;
  mobile?: string;
  email?: string;
  altMobile?: string;
  website?: string;
  addresses?: CustomerAddress[];
  paymentTerms?: string;
  creditLimit?: number;
  openingBalance?: number;
  openingBalanceDate?: string;
  discountPercent?: number;
  customerGroup?: string;
  tags?: string[];
  notes?: string;
  isActive?: boolean;
}

interface CustomerDetailResponse {
  success: boolean;
  message: string;
  data?: Customer;
}

@Component({
  selector: 'app-company-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './company-form.component.html',
  styleUrl: './company-form.component.scss'
})
export class CompanyFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);
  private toast = inject(ToastService);

  isLoading = signal(false);
  isSaving = signal(false);
  stateCodeDropdownIndex = signal<number | null>(null);
  stateCodeSearch = signal('');
  stateOptions = signal<Array<{ name: string; code: string }>>([
    { name: 'Andhra Pradesh', code: '37' },
    { name: 'Arunachal Pradesh', code: '12' },
    { name: 'Assam', code: '18' },
    { name: 'Bihar', code: '10' },
    { name: 'Chhattisgarh', code: '22' },
    { name: 'Goa', code: '30' },
    { name: 'Gujarat', code: '24' },
    { name: 'Haryana', code: '06' },
    { name: 'Himachal Pradesh', code: '02' },
    { name: 'Jharkhand', code: '20' },
    { name: 'Karnataka', code: '29' },
    { name: 'Kerala', code: '32' },
    { name: 'Madhya Pradesh', code: '23' },
    { name: 'Maharashtra', code: '27' },
    { name: 'Manipur', code: '14' },
    { name: 'Meghalaya', code: '17' },
    { name: 'Mizoram', code: '15' },
    { name: 'Nagaland', code: '13' },
    { name: 'Odisha', code: '21' },
    { name: 'Punjab', code: '03' },
    { name: 'Rajasthan', code: '08' },
    { name: 'Sikkim', code: '11' },
    { name: 'Tamil Nadu', code: '33' },
    { name: 'Telangana', code: '36' },
    { name: 'Tripura', code: '16' },
    { name: 'Uttar Pradesh', code: '09' },
    { name: 'Uttarakhand', code: '05' },
    { name: 'West Bengal', code: '19' },
    { name: 'Andaman & Nicobar Islands', code: '35' },
    { name: 'Chandigarh', code: '04' },
    { name: 'Dadra & Nagar Haveli and Daman & Diu', code: '26' },
    { name: 'Delhi', code: '07' },
    { name: 'Jammu & Kashmir', code: '01' },
    { name: 'Ladakh', code: '38' },
    { name: 'Lakshadweep', code: '31' },
    { name: 'Puducherry', code: '34' }
  ]);
  filteredStateOptions = computed(() => {
    const search = this.stateCodeSearch().trim().toLowerCase();
    return search
      ? this.stateOptions().filter(state =>
          `${state.name} - ${state.code}`.toLowerCase().includes(search)
        )
      : this.stateOptions();
  });
  pageTitle = 'Add Customer';
  submitText = 'Add Customer';
  private customerId: string | null = null;

  form: FormGroup = this.fb.group({
    name: ['', Validators.required],
    displayName: ['', Validators.required],
    customerType: ['B2B', Validators.required],
    gstin: ['', Validators.required],
    pan: ['', Validators.required],
    isGSTRegistered: [true],
    contactPerson: ['', Validators.required],
    mobile: ['', [Validators.required, Validators.pattern(/^[0-9]{10,15}$/)]],
    email: ['', [Validators.required, Validators.email]],
    altMobile: [''],
    website: [''],
    addresses: this.fb.array([
      this.createAddressGroup('Billing Address', true),
      this.createAddressGroup('Shipping Address', false)
    ]),
    paymentTerms: ['Net 30', Validators.required],
    creditLimit: [0, [Validators.required, Validators.min(0)]],
    openingBalance: [0, [Validators.required, Validators.min(0)]],
    openingBalanceDate: ['', Validators.required],
    discountPercent: [0, [Validators.required, Validators.min(0), Validators.max(100)]],
    customerGroup: [''],
    tags: [''],
    notes: [''],
    isActive: [true]
  });

  get addresses(): FormArray {
    return this.form.get('addresses') as FormArray;
  }

  ngOnInit(): void {
    this.customerId = this.route.snapshot.paramMap.get('id');
    if (this.customerId) {
      this.pageTitle = 'Edit Customer';
      this.submitText = 'Save Changes';
      this.loadCustomerDetails(this.customerId);
    }
  }

  addAddress(): void {
    this.addresses.push(this.createAddressGroup('Other Address', false));
  }

  removeAddress(index: number): void {
    if (this.addresses.length <= 1) {
      return;
    }
    this.addresses.removeAt(index);
    this.stateCodeDropdownIndex.set(null);
    this.stateCodeSearch.set('');
  }

  toggleStateCodeDropdown(index: number): void {
    const nextIndex = this.stateCodeDropdownIndex() === index ? null : index;
    this.stateCodeDropdownIndex.set(nextIndex);
    this.stateCodeSearch.set('');
  }

  selectStateCode(index: number, state: { name: string; code: string }): void {
    const addressGroup = this.addresses.at(index);
    addressGroup.patchValue({
      state: state.name,
      stateCode: state.code
    });
    addressGroup.markAsDirty();
    addressGroup.markAsTouched();
    this.stateCodeSearch.set('');
    this.stateCodeDropdownIndex.set(null);
  }

  selectedStateCodeLabel(index: number): string {
    const code = this.addresses.at(index)?.get('stateCode')?.value;
    return code ? this.getStateLabel(code) : 'Select a state';
  }

  cancel(): void {
    this.router.navigate(['/customer']);
  }

  async onSubmit(): Promise<void> {
    this.form.markAllAsTouched();
    if (this.form.invalid) {
      this.toast.error('Please fill in the required fields before saving.');
      return;
    }

    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    const url = this.customerId
      ? `${this.apiUrl}/api/v1/customers/${this.customerId}`
      : `${this.apiUrl}/api/v1/customers`;

    this.isSaving.set(true);
    try {
      const response = await firstValueFrom(
        this.http.request<CustomerSaveResponse>(this.customerId ? 'PUT' : 'POST', url, {
          body: this.buildPayload(),
          headers: new HttpHeaders({
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json'
          })
        })
      );

      if (!response?.success) {
        this.toast.error(response?.message || 'Could not save customer.');
        return;
      }

      this.toast.success(response.message || (this.customerId ? 'Customer updated successfully.' : 'Customer added successfully.'));
      this.router.navigate(['/customer']);
    } catch (error) {
      console.error('Customer save error', error);
      this.toast.error(this.getApiMessage(error, 'Could not save customer. Check your network and try again.'));
    } finally {
      this.isSaving.set(false);
    }
  }

  private async loadCustomerDetails(id: string): Promise<void> {
    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.get<CustomerDetailResponse>(`${this.apiUrl}/api/v1/customers/${id}`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` })
        })
      );

      if (!response?.success || !response.data) {
        this.toast.error(response?.message || 'Could not load customer details.');
        return;
      }

      this.patchCustomerForm(response.data);
    } catch (error) {
      console.error('Customer detail load error', error);
      this.toast.error(this.getApiMessage(error, 'Could not load customer details. Check your network and try again.'));
    } finally {
      this.isLoading.set(false);
    }
  }

  private patchCustomerForm(customer: Customer): void {
    while (this.addresses.length > 0) {
      this.addresses.removeAt(0);
    }

    const addresses = customer.addresses?.length
      ? customer.addresses
      : [{ label: 'Billing Address', isDefault: true }];

    addresses.forEach(address => this.addresses.push(this.createAddressGroup(
      address.label ?? 'Address',
      address.isDefault ?? false,
      address
    )));

    this.form.patchValue({
      name: customer.name ?? '',
      displayName: customer.displayName ?? '',
      customerType: customer.customerType ?? 'B2B',
      gstin: customer.gstin ?? '',
      pan: customer.pan ?? '',
      isGSTRegistered: customer.isGSTRegistered ?? false,
      contactPerson: customer.contactPerson ?? '',
      mobile: customer.mobile ?? '',
      email: customer.email ?? '',
      altMobile: customer.altMobile ?? '',
      website: customer.website ?? '',
      paymentTerms: customer.paymentTerms ?? 'Net 30',
      creditLimit: customer.creditLimit ?? 0,
      openingBalance: customer.openingBalance ?? 0,
      openingBalanceDate: this.toDateInputValue(customer.openingBalanceDate),
      discountPercent: customer.discountPercent ?? 0,
      customerGroup: customer.customerGroup ?? '',
      tags: customer.tags?.join(', ') ?? '',
      notes: customer.notes ?? '',
      isActive: customer.isActive ?? true
    });

    this.form.markAsPristine();
  }

  private createAddressGroup(label: string, isDefault: boolean, address?: CustomerAddress): FormGroup {
    return this.fb.group({
      _id: [address?._id ?? ''],
      label: [address?.label ?? label, Validators.required],
      line1: [address?.line1 ?? '', Validators.required],
      line2: [address?.line2 ?? ''],
      city: [address?.city ?? '', Validators.required],
      state: [address?.state ?? '', Validators.required],
      stateCode: [address?.stateCode ?? '', Validators.required],
      pinCode: [address?.pinCode ?? '', Validators.required],
      country: [address?.country ?? 'India', Validators.required],
      isDefault: [address?.isDefault ?? isDefault]
    });
  }

  private buildPayload() {
    const value = this.form.value;

    return {
      name: value.name,
      displayName: value.displayName,
      customerType: value.customerType,
      gstin: value.gstin,
      pan: value.pan,
      isGSTRegistered: value.isGSTRegistered,
      contactPerson: value.contactPerson,
      mobile: value.mobile,
      email: value.email,
      altMobile: value.altMobile,
      website: value.website,
      addresses: this.buildAddressesPayload(value.addresses ?? []),
      paymentTerms: value.paymentTerms,
      creditLimit: Number(value.creditLimit),
      openingBalance: Number(value.openingBalance),
      openingBalanceDate: value.openingBalanceDate
        ? new Date(value.openingBalanceDate).toISOString()
        : undefined,
      discountPercent: Number(value.discountPercent),
      customerGroup: value.customerGroup,
      tags: String(value.tags ?? '')
        .split(',')
        .map(tag => tag.trim())
        .filter(Boolean),
      notes: value.notes,
      isActive: value.isActive
    };
  }

  private buildAddressesPayload(addresses: CustomerAddress[]): CustomerAddress[] {
    return addresses.map(address => {
      const payload: CustomerAddress = {
        label: address.label,
        line1: address.line1,
        line2: address.line2,
        city: address.city,
        state: address.state,
        stateCode: address.stateCode,
        pinCode: address.pinCode,
        country: address.country,
        isDefault: address.isDefault
      };

      if (address._id) {
        payload._id = address._id;
      }

      return payload;
    });
  }

  private toDateInputValue(date?: string): string {
    if (!date) {
      return '';
    }

    return date.slice(0, 10);
  }

  private getStateLabel(code: string): string {
    const state = this.stateOptions().find(option => option.code === code);
    return state ? `${state.name} - ${state.code}` : code;
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
