import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators
} from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { ToastService } from '../../auth/toast.service';
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
  _id?: string;
  vendorCode?: string;
  name?: string;
  displayName?: string;
  contactPerson?: string;
  mobile?: string;
  email?: string;
  gstin?: string;
  pan?: string;
  paymentTerms?: string;
  creditLimit?: number;
  tags?: string[];
  notes?: string;
  billingAddress?: VendorAddress;
  isActive?: boolean;
}

@Component({
  selector: 'app-vendor-form',
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './vendor-form.html',
  styleUrl: './vendor-form.scss',
})

export class VendorFormComponent implements OnInit {

  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = inject(API_URL);
  private toast = inject(ToastService);

  isLoading = signal(false);
  isSaving = signal(false);

  pageTitle = 'Add Vendor';
  submitText = 'Add Vendor';

  private vendorId: string | null = null;

  form: FormGroup = this.fb.group({
    name: ['', Validators.required],
    displayName: ['', Validators.required],

    contactPerson: ['', Validators.required],
    mobile: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],

    gstin: [''],
    pan: [''],

    paymentTerms: ['Net 30'],
    creditLimit: [0],

    tags: [''],
    notes: [''],

    billingAddress: this.fb.group({
      line1: ['', Validators.required],
      line2: [''],
      city: ['', Validators.required],
      state: ['', Validators.required],
      stateCode: ['', Validators.required],
      pinCode: ['', Validators.required]
    }),

    isActive: [true]
  });

  ngOnInit(): void {
    this.vendorId = this.route.snapshot.paramMap.get('id');

    if (this.vendorId) {
      this.pageTitle = 'Edit Vendor';
      this.submitText = 'Save Changes';

      this.loadVendor(this.vendorId);
    }
  }

  async onSubmit(): Promise<void> {

    this.form.markAllAsTouched();

    if (this.form.invalid) {
      this.toast.error('Please fill all required fields');
      return;
    }

    const token = this.auth.getAuthToken();

    if (!token) {
      this.toast.error('Authentication token missing');
      return;
    }

    const companyId = this.getCompanyId();

    const url = this.vendorId
      ? `${this.apiUrl}/api/v1/vendors/${this.vendorId}`
      : `${this.apiUrl}/api/v1/vendors`;

    this.isSaving.set(true);

    try {

      const response = await firstValueFrom(
        this.http.request<any>(
          this.vendorId ? 'PUT' : 'POST',
          url,
          {
            body: this.buildPayload(),
            headers: new HttpHeaders({
              Authorization: `Bearer ${token}`,
              'Content-Type': 'application/json'
            }),
            params: new HttpParams().set('companyId', companyId)
          }
        )
      );

      if (!response?.success) {
        this.toast.error(response?.message || 'Unable to save vendor');
        return;
      }

      this.toast.success(
        this.vendorId
          ? 'Vendor updated successfully'
          : 'Vendor created successfully'
      );

      this.router.navigate(['/vendor']);

    } catch (error) {
      console.error(error);
      this.toast.error('Failed to save vendor');
    } finally {
      this.isSaving.set(false);
    }
  }

  async loadVendor(id: string): Promise<void> {

    const token = this.auth.getAuthToken();

    if (!token) {
      return;
    }

    this.isLoading.set(true);

    try {

      const companyId = this.getCompanyId();

      const response = await firstValueFrom(
        this.http.get<any>(
          `${this.apiUrl}/api/v1/vendors/${id}`,
          {
            headers: new HttpHeaders({
              Authorization: `Bearer ${token}`
            }),
            params: new HttpParams().set('companyId', companyId)
          }
        )
      );

      if (!response?.success || !response.data) {
        return;
      }

      this.patchForm(response.data);

    } catch (error) {
      console.error(error);
      this.toast.error('Unable to load vendor');
    } finally {
      this.isLoading.set(false);
    }
  }

  patchForm(vendor: Vendor): void {

    this.form.patchValue({
      name: vendor.name,
      displayName: vendor.displayName,

      contactPerson: vendor.contactPerson,
      mobile: vendor.mobile,
      email: vendor.email,

      gstin: vendor.gstin,
      pan: vendor.pan,

      paymentTerms: vendor.paymentTerms,
      creditLimit: vendor.creditLimit,

      tags: vendor.tags?.join(', '),
      notes: vendor.notes,

      billingAddress: {
        line1: vendor.billingAddress?.line1,
        line2: vendor.billingAddress?.line2,
        city: vendor.billingAddress?.city,
        state: vendor.billingAddress?.state,
        stateCode: vendor.billingAddress?.stateCode,
        pinCode: vendor.billingAddress?.pinCode
      },

      isActive: vendor.isActive
    });
  }

  buildPayload() {

    const value = this.form.value;

    return {
      name: value.name,
      displayName: value.displayName,

      contactPerson: value.contactPerson,
      mobile: value.mobile,
      email: value.email,

      gstin: value.gstin,
      pan: value.pan,

      paymentTerms: value.paymentTerms,
      creditLimit: Number(value.creditLimit),

      tags: String(value.tags ?? '')
        .split(',')
        .map((tag: string) => tag.trim())
        .filter(Boolean),

      notes: value.notes,

      billingAddress: value.billingAddress,

      isActive: value.isActive
    };
  }

  cancel(): void {
    this.router.navigate(['/vendor']);
  }

  private getCompanyId(): string {
    try {
      const raw = localStorage.getItem('billflow_auth_user');

      if (!raw) return '';

      const user = JSON.parse(raw);

      return user?.companies?.[0]?.companyId?._id
        || user?.companies?.[0]?.companyId
        || '';

    } catch {
      return '';
    }
  }
}
