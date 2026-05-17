import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { SignupService } from '../signup.service';
import { ToastService } from '../toast.service';

@Component({
  selector: 'app-signup',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './signup.component.html'
})
export class SignupComponent {
  private fb = inject(FormBuilder);
  private signupService = inject(SignupService);
  private router = inject(Router);
  private toast = inject(ToastService);

  showLoading = signal(false);

  form: FormGroup = this.fb.group({
    fullName: ['', [Validators.required, Validators.minLength(3)]],
    email: ['', [Validators.required, Validators.email]],
    mobile: ['', [Validators.required, Validators.pattern(/^\+?[0-9]{7,15}$/)]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    confirmPassword: ['', [Validators.required]],
    acceptTerms: [false, [Validators.requiredTrue]],
    referralCode: ['']
  });

  get fullNameCtrl() { return this.form.get('fullName')!; }
  get emailCtrl() { return this.form.get('email')!; }
  get mobileCtrl() { return this.form.get('mobile')!; }
  get passwordCtrl() { return this.form.get('password')!; }
  get confirmPasswordCtrl() { return this.form.get('confirmPassword')!; }
  get acceptTermsCtrl() { return this.form.get('acceptTerms')!; }
  get referralCodeCtrl() { return this.form.get('referralCode')!; }

  get confirmPasswordError(): string {
    const ctrl = this.confirmPasswordCtrl;
    if (!ctrl.touched || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Please confirm your password.';
    if (this.passwordCtrl.value !== ctrl.value) return 'Passwords do not match.';
    return '';
  }

  async onSubmit(): Promise<void> {
    this.form.markAllAsTouched();

    if (this.form.invalid || this.passwordCtrl.value !== this.confirmPasswordCtrl.value) {
      if (this.passwordCtrl.value !== this.confirmPasswordCtrl.value) {
        this.toast.error('Passwords must match.');
      }
      return;
    }

    const {
      fullName,
      email,
      mobile,
      password,
      confirmPassword,
      acceptTerms,
      referralCode
    } = this.form.value;
    this.showLoading.set(true);

    const success = await this.signupService.register(
      fullName,
      email,
      mobile,
      password,
      confirmPassword,
      acceptTerms,
      referralCode
    );
    this.showLoading.set(false);
    const message = this.signupService.lastApiMessage();

    if (!success) {
      this.toast.error(message || 'Signup failed. Please try again with a different email or check your network.');
      return;
    }

    this.toast.success(message || 'Registration successful. Enter the OTP to verify your account.');
    this.router.navigate(['/signup/verify']);
  }
}
