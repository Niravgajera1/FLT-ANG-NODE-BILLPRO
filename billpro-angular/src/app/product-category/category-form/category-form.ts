import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  ReactiveFormsModule,
  Validators
} from '@angular/forms';

import {
  ActivatedRoute,
  Router,
  RouterModule
} from '@angular/router';

import {
  HttpClient,
  HttpHeaders,
  HttpParams
} from '@angular/common/http';

import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../auth/auth.service';
import { ToastService } from '../../auth/toast.service';
import { API_URL } from '../../app.config';


interface CategoryResponse {
  success: boolean;
  message: string;
  data?: {
    _id: string;
    name: string;
    description: string;
    isActive: boolean;
  };
}


@Component({
  selector: 'app-category-form',
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule
  ], templateUrl: './category-form.html',
  styleUrl: './category-form.scss',
})
export class CategoryForm {
private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private apiUrl = inject(API_URL);

  categoryId: string | null = null;

  pageTitle = 'Add Category';
  submitText = 'Add Category';

  isLoading = signal(false);
  isSaving = signal(false);

  form = this.fb.group({
    name: ['', Validators.required],
    description: [''],
    isActive: [true]
  });

  ngOnInit(): void {

    this.categoryId =
      this.route.snapshot.paramMap.get('id');

    if (this.categoryId) {

      this.pageTitle =
        'Edit Category';

      this.submitText =
        'Save Changes';

      this.loadDetails();
    }

  }

  async loadDetails() {

    const token =
      this.auth.getAuthToken();

    const companyId =
      this.getCompanyId();

    if (!token || !companyId)
      return;

    this.isLoading.set(true);

    try {

      const response =
        await firstValueFrom(

          this.http.get<CategoryResponse>(
            `${this.apiUrl}/api/v1/items/categories/details/${this.categoryId}`,
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

      if (!response.success) {

        this.toast.error(
          response.message
        );

        return;
      }

      this.form.patchValue({

        name:
          response.data?.name,

        description:
          response.data?.description,

        isActive:
          response.data?.isActive ?? true

      });

    }

    catch {

      this.toast.error(
        'Failed to load category'
      );

    }

    finally {

      this.isLoading.set(false);

    }

  }

  async onSubmit() {

    this.form.markAllAsTouched();

    if (this.form.invalid)
      return;

    const token =
      this.auth.getAuthToken();

    const companyId =
      this.getCompanyId();

    if (!token || !companyId)
      return;

    this.isSaving.set(true);

    try {

      const url =
        this.categoryId
          ? `${this.apiUrl}/api/v1/items/categories/update/${this.categoryId}`
          : `${this.apiUrl}/api/v1/items/categories/add`;

      const method =
        this.categoryId
          ? 'PUT'
          : 'POST';

      const response: any =
        await firstValueFrom(

          this.http.request(
            method,
            url,
            {
              body: {
                name:
                  this.form.value.name,

                description:
                  this.form.value.description,

                isActive:
                  this.form.value.isActive
              },

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

        );

      if (!response.success) {

        this.toast.error(
          response.message
        );

        return;

      }

      this.toast.success(
        response.message
      );

      this.router.navigate([
        '/category'
      ]);

    }

    catch {

      this.toast.error(
        'Failed to save category'
      );

    }

    finally {

      this.isSaving.set(false);

    }

  }

  cancel() {

    this.router.navigate([
      '/category'
    ]);

  }

  private getCompanyId(): string {

    try {

      const raw =
        localStorage.getItem(
          'billflow_auth_user'
        );

      const user =
        raw
          ? JSON.parse(raw)
          : null;

      return (
        user?.companies?.[0]
          ?.companyId?._id ||

        user?.companies?.[0]
          ?.companyId ||

        ''
      );

    }

    catch {

      return '';

    }

  }
}
