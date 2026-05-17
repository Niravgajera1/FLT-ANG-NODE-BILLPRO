import { Routes } from '@angular/router';
import { authGuard, loginGuard } from './auth/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    canActivate: [loginGuard],
    loadComponent: () =>
      import('./auth/login/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'signup',
    canActivate: [loginGuard],
    loadComponent: () =>
      import('./auth/signup/signup.component').then(m => m.SignupComponent)
  },
  {
    path: 'signup/verify',
    canActivate: [loginGuard],
    loadComponent: () =>
      import('./auth/otp-verification/otp-verification.component').then(m => m.OtpVerificationComponent)
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./dashboard/dashboard.component').then(m => m.DashboardComponent)
  },
  {
    path: 'company',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./company/company-list/company-list').then(m => m.CompanyList)
  },
  {
    path: 'company/add',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./company/company-form/company-form.component').then(m => m.CompanyFormComponent)
  },
  {
    path: 'company/:id/edit',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./company/company-form/company-form.component').then(m => m.CompanyFormComponent)
  },
  {
    path: 'products',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./products/products.component').then(m => m.ProductsComponent)
  },
  {
    path: 'products/add',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./products/product-form/product-form.component').then(m => m.ProductFormComponent)
  },
  {
    path: 'products/:id/edit',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./products/product-form/product-form.component').then(m => m.ProductFormComponent)
  },
  {
    path: 'create-invoice',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./create-invoice/create-invoice.component').then(m => m.CreateInvoiceComponent)
  },
  {
    path: 'create-invoice/add',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./create-invoice/invoice-form.component').then(m => m.InvoiceFormComponent)
  },
  {
    path: 'create-invoice/:id/edit',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./create-invoice/invoice-form.component').then(m => m.InvoiceFormComponent)
  },
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: '**', redirectTo: 'login' }
];
