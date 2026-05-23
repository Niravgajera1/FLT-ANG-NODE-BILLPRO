import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { AuthService, BusinessInfo } from '../auth/auth.service';
import { API_URL } from '../app.config';
import { ToastService } from '../auth/toast.service';

type ProfileTab = 'user' | 'business';

interface CompanyResponse {
  success: boolean;
  message: string;
  data?: BusinessInfo;
}

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './profile.component.html'
})
export class ProfileComponent implements OnInit {
  auth = inject(AuthService);
  private fb = inject(FormBuilder);
  private http = inject(HttpClient);
  private toast = inject(ToastService);
  private apiUrl = inject(API_URL);

  activeTab = signal<ProfileTab>('user');
  editMode = signal(false);
  isLoading = signal(false);
  showAddCompanyForm = signal(false);
  businessCategoryOptions = signal<string[]>([]);
  businessTypeOptions = signal<string[]>([]);
  gstTypeOptions = signal<string[]>([]);
  stateCodeDropdownOpen = signal(false);
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

  companyForm: FormGroup = this.fb.group({
    legalName: ['', Validators.required],
    tradeName: ['', Validators.required],
    businessType: ['', Validators.required],
    pan: ['', Validators.required],
    gstin: ['', Validators.required],
    gstType: ['', Validators.required],
    isGSTRegistered: [false],
    fssaiNumber: ['', Validators.required],
    businessCategory: ['', Validators.required],
    industryType: ['', Validators.required],
    mobile: ['', [Validators.required, Validators.pattern(/^[0-9]{10,15}$/)]],
    email: ['', [Validators.required, Validators.email]],
    website: ['', Validators.required],
    registeredAddress: this.fb.group({
      line1: ['', Validators.required],
      line2: [''],
      city: ['', Validators.required],
      state: ['', Validators.required],
      stateCode: ['', Validators.required],
      pinCode: ['', Validators.required],
      country: ['', Validators.required]
    }),
    tcsEnabled: [false],
    tdsEnabled: [false],
    fyStartMonth: [4, [Validators.required, Validators.min(1), Validators.max(12)]],
    bankAccounts: this.fb.array([this.createBankAccountGroup()])
  });

  hasCompany = computed(() => {
    const current = this.auth.currentUser();
    return current?.hasCompany ?? false;
  });

  profile = computed(() => {
    const current = this.auth.currentUser();
    console.log(current);

    return {
      fullName: current?.fullName ?? current?.name ?? 'Unknown User',
      email: current?.email ?? 'Unknown email',
      mobile: current?.mobile ?? 'Not provided',
      role: current?.role ?? 'User',
      referralCode: current?.referralCode ?? 'Not provided',
      isEmailVerified: current?.isEmailVerified ?? false,
      isMobileVerified: current?.isMobileVerified ?? false,
      isActive: current?.isActive ?? false,
      loginAttempts: current?.loginAttempts ?? 0,
      onboardingCompleted: current?.onboardingCompleted ?? false,
      hasCompany: current?.hasCompany ?? false,
      companies: (current?.companies as any[]) ?? [],
      businessInfo: current?.businessInfo ?? {
        legalName: '',
        tradeName: '',
        businessType: '',
        gstin: '',
        pan: '',
        fssaiNumber: '',
        gstType: '',
        isGSTRegistered: false,
        tcsEnabled: false,
        tdsEnabled: false,
        rcmVendors: [],
        businessCategory: '',
        industryType: '',
        mobile: '',
        email: '',
        website: '',
        registeredAddress: {
          line1: '',
          line2: '',
          city: '',
          state: '',
          stateCode: '',
          pinCode: '',
          country: ''
        },
        fyStartMonth: undefined,
        bankAccounts: []
      } as BusinessInfo,
      createdAt: current?.createdAt,
      updatedAt: current?.updatedAt
    };
  });

  get bankAccounts(): FormArray {
    return this.companyForm.get('bankAccounts') as FormArray;
  }

  ngOnInit(): void {
    this.syncFormWithBusinessInfo();
    this.loadUserDetails().then(() => {
      if (this.hasCompany()) {
        this.loadCompanyDetails();
      }
    });
    this.loadBusinessCategories();
    this.loadBusinessTypes();
    this.loadGstTypes();
  }

  setTab(tab: ProfileTab): void {
    this.activeTab.set(tab);
    this.showAddCompanyForm.set(false);
    if (tab === 'user') {
      this.loadUserDetails();
    }
    if (tab === 'business' && this.hasCompany()) {
      this.loadCompanyDetails();
    }
  }

  private async loadUserDetails(): Promise<void> {
    try {
      await this.auth.refreshCurrentUser();
    } catch (error) {
      console.error('Unable to load user profile', error);
    }
  }

  private async loadCompanyDetails(): Promise<void> {
    const token = this.auth.getAuthToken();
    if (!token) {
      return;
    }
    // const user = JSON.parse(localStorage.getItem('billflow_auth_user') || '{}');


    const url = `${this.apiUrl}/api/v1/companies`;
    const headers = new HttpHeaders({ Authorization: `Bearer ${token}` });

    try {
      const response = await firstValueFrom(
        this.http.get<CompanyResponse>(url, { headers })
      );

      if (response?.success && response.data) {
        const currentUser = this.auth.currentUser();
        if (currentUser) {
          this.auth.setCurrentUser({ ...currentUser, businessInfo: response.data });
          this.syncFormWithBusinessInfo();
        }
      }
    } catch (error) {
      console.error('Unable to fetch company details', error);
      this.toast.error(this.getApiMessage(error, 'Unable to fetch company details.'));
    }
  }

  private async loadBusinessCategories(): Promise<void> {
    try {
      const url = `${this.apiUrl}/api/v1/common/businessCategories`;
      const response = await firstValueFrom(
        this.http.get<{ success: boolean; message: string; data?: Array<string | { label?: string; value?: string; name?: string }> }>(url)
      );

      if (response?.success && Array.isArray(response.data)) {
        const mapped = response.data
          .map(item => typeof item === 'string'
            ? item
            : item.value ?? item.label ?? item.name ?? '')
          .filter(Boolean);
        this.businessCategoryOptions.set(mapped);
      }
    } catch (error) {
      console.error('Unable to load business categories', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load business categories.'));
    }
  }

  private async loadBusinessTypes(): Promise<void> {
    try {
      const url = `${this.apiUrl}/api/v1/common/businessTypes`;
      const response = await firstValueFrom(
        this.http.get<{ success: boolean; message: string; data?: Array<string | { label?: string; value?: string; name?: string }> }>(url)
      );

      if (response?.success && Array.isArray(response.data)) {
        const mapped = response.data
          .map(item => typeof item === 'string'
            ? item
            : item.value ?? item.label ?? item.name ?? '')
          .filter(Boolean);
        this.businessTypeOptions.set(mapped);
      }
    } catch (error) {
      console.error('Unable to load business types', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load business types.'));
    }
  }

  private async loadGstTypes(): Promise<void> {
    try {
      const url = `${this.apiUrl}/api/v1/common/gstTypes`;
      const response = await firstValueFrom(
        this.http.get<{ success: boolean; message: string; data?: Array<string | { label?: string; value?: string; name?: string }> }>(url)
      );

      if (response?.success && Array.isArray(response.data)) {
        const mapped = response.data
          .map(item => typeof item === 'string'
            ? item
            : item.value ?? item.label ?? item.name ?? '')
          .filter(Boolean);
        this.gstTypeOptions.set(mapped);
      }
    } catch (error) {
      console.error('Unable to load GST types', error);
      this.toast.error(this.getApiMessage(error, 'Unable to load GST types.'));
    }
  }

  startEdit(): void {
    this.editMode.set(true);
    this.syncFormWithBusinessInfo();
  }

  startAddCompany(): void {
    this.showAddCompanyForm.set(true);
    this.editMode.set(true);
    this.companyForm.reset();
    this.syncFormWithBusinessInfo();
  }

  cancelEdit(): void {
    this.editMode.set(false);
    this.showAddCompanyForm.set(false);
    this.stateCodeDropdownOpen.set(false);
    this.stateCodeSearch.set('');
    this.companyForm.markAsPristine();
  }

  toggleStateCodeDropdown(): void {
    this.stateCodeDropdownOpen.update(open => !open);
  }

  openStateCodeDropdown(): void {
    this.stateCodeDropdownOpen.set(true);
  }

  selectStateCode(state: { name: string; code: string }): void {
    const addressGroup = this.companyForm.get('registeredAddress');
    addressGroup?.patchValue({
      state: state.name,
      stateCode: state.code
    });
    addressGroup?.markAsDirty();
    addressGroup?.markAsTouched();
    this.stateCodeSearch.set('');
    this.stateCodeDropdownOpen.set(false);
  }

  private createBankAccountGroup() {
    return this.fb.group({
      bankName: ['', Validators.required],
      accountHolderName: ['', Validators.required],
      accountNumber: ['', Validators.required],
      ifscCode: ['', Validators.required],
      accountType: ['current', Validators.required],
      branchName: ['', Validators.required],
      branchAddress: ['', Validators.required],
      upiId: ['', Validators.required],
      isDefault: [true]
    });
  }

  private syncFormWithBusinessInfo(): void {
    const business = this.profile().businessInfo;
    const bankAccounts = Array.isArray(business?.bankAccounts) && business.bankAccounts.length > 0
      ? business.bankAccounts
      : [this.createBankAccountGroup().value];

    while (this.bankAccounts.length > 0) {
      this.bankAccounts.removeAt(0);
    }
    bankAccounts.forEach(account => this.bankAccounts.push(this.fb.group({
      bankName: [account.bankName ?? '', Validators.required],
      accountHolderName: [account.accountHolderName ?? '', Validators.required],
      accountNumber: [account.accountNumber ?? '', Validators.required],
      ifscCode: [account.ifscCode ?? '', Validators.required],
      accountType: [account.accountType ?? 'current', Validators.required],
      branchName: [account.branchName ?? '', Validators.required],
      branchAddress: [account.branchAddress ?? '', Validators.required],
      upiId: [account.upiId ?? '', Validators.required],
      isDefault: [account.isDefault ?? true]
    })));

    this.companyForm.patchValue({
      legalName: business?.legalName ?? '',
      tradeName: business?.tradeName ?? '',
      businessType: business?.businessType ?? '',
      pan: business?.pan ?? '',
      gstin: business?.gstin ?? '',
      gstType: business?.gstType ?? 'regular',
      isGSTRegistered: business?.isGSTRegistered ?? false,
      fssaiNumber: business?.fssaiNumber ?? '',
      businessCategory: business?.businessCategory ?? '',
      industryType: business?.industryType ?? '',
      mobile: business?.mobile ?? '',
      email: business?.email ?? '',
      website: business?.website ?? '',
      registeredAddress: {
        line1: business?.registeredAddress?.line1 ?? '',
        line2: business?.registeredAddress?.line2 ?? '',
        city: business?.registeredAddress?.city ?? '',
        state: business?.registeredAddress?.state ?? this.getStateName(business?.registeredAddress?.stateCode) ?? '',
        stateCode: business?.registeredAddress?.stateCode ?? '',
        pinCode: business?.registeredAddress?.pinCode ?? '',
        country: business?.registeredAddress?.country ?? ''
      },
      tcsEnabled: business?.tcsEnabled ?? false,
      tdsEnabled: business?.tdsEnabled ?? false,
      fyStartMonth: business?.fyStartMonth ?? 4
    });
  }

  async saveBusinessInfo(): Promise<void> {
    this.companyForm.markAllAsTouched();
    if (this.companyForm.invalid) {
      this.toast.error('Please fix the highlighted fields to save your business details.');
      return;
    }

    const token = this.auth.getAuthToken();
    if (!token) {
      this.toast.error('Authentication token missing. Please login again.');
      return;
    }

    const payload = {
      ...this.companyForm.value,
      registeredAddress: this.companyForm.value.registeredAddress,
      bankAccounts: this.companyForm.value.bankAccounts
    };

    const currentBusinessId = this.profile().businessInfo?._id;
    const url = `${this.apiUrl}/api/v1/companies`;
    const headers = new HttpHeaders({
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json'
    });

    this.isLoading.set(true);
    try {
      const response = await firstValueFrom(
        this.http.request<CompanyResponse>(currentBusinessId ? 'PUT' : 'POST', url, {
          body: payload,
          headers
        })
      );

      if (!response?.success || !response.data) {
        this.toast.error(response?.message || 'Failed to save company details.');
        return;
      }

      const currentUser = this.auth.currentUser();
      if (currentUser) {
        this.auth.setCurrentUser({ ...currentUser, businessInfo: response.data, hasCompany: true });
      }

      this.editMode.set(false);
      this.showAddCompanyForm.set(false);
      this.toast.success(response.message || 'Business details saved successfully.');
    } catch (error) {
      console.error('Business save error', error);
      this.toast.error(this.getApiMessage(error, 'Could not save business details. Check your network and try again.'));
    } finally {
      this.isLoading.set(false);
    }
  }

  getStateLabel(code?: string): string {
    if (!code) {
      return 'N/A';
    }

    const state = this.stateOptions().find(option => option.code === code);
    return state ? `${state.name} - ${state.code}` : code;
  }

  selectedStateCodeLabel(): string {
    const code = this.companyForm.get('registeredAddress.stateCode')?.value;
    return code ? this.getStateLabel(code) : 'Select a state';
  }

  maskAccountNumber(accountNumber?: string): string {
    if (!accountNumber) {
      return 'N/A';
    }

    const visibleDigits = accountNumber.slice(-4);
    return visibleDigits ? `•••• ${visibleDigits}` : accountNumber;
  }

  private getStateName(code?: string): string | undefined {
    return this.stateOptions().find(option => option.code === code)?.name;
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
