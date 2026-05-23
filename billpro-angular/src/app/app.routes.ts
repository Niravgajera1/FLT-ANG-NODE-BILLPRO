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
    path: 'forgot-password',
    canActivate: [loginGuard],
    loadComponent: () =>
      import('./auth/forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent)
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./dashboard/dashboard.component').then(m => m.DashboardComponent)
  },
  {
    path: 'profile',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./profile/profile.component').then(m => m.ProfileComponent)
  },
  {
    path: 'customer',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./company/company-list/company-list').then(m => m.CompanyList)
  },
  {
    path: 'customer/add',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./company/company-form/company-form.component').then(m => m.CompanyFormComponent)
  },
  {
    path: 'customer/:id/edit',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./company/company-form/company-form.component').then(m => m.CompanyFormComponent)
  },

  {
    path: 'vendor',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./vendor/vendor-list/vendor-list').then(m => m.VendorList)
  },
  {
    path: 'vendor/add',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./vendor/vendor-form/vendor-form').then(m => m.VendorFormComponent)
  },
  {
    path: 'vendor/:id/edit',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./vendor/vendor-form/vendor-form').then(m => m.VendorFormComponent)
  },

  { path: 'company', redirectTo: 'customer', pathMatch: 'full' },
  { path: 'company/add', redirectTo: 'customer/add', pathMatch: 'full' },
  { path: 'company/:id/edit', redirectTo: 'customer/:id/edit', pathMatch: 'full' },
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
