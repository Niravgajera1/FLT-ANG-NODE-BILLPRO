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
    phone: ['', [Validators.required, Validators.pattern(/^\+?[0-9]{7,15}$/)]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    confirmPassword: ['', [Validators.required]]
  });

  get fullNameCtrl() { return this.form.get('fullName')!; }
  get emailCtrl() { return this.form.get('email')!; }
  get phoneCtrl() { return this.form.get('phone')!; }
  get passwordCtrl() { return this.form.get('password')!; }
  get confirmPasswordCtrl() { return this.form.get('confirmPassword')!; }

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

    const { fullName, email, phone, password } = this.form.value;
    this.showLoading.set(true);

    const success = await this.signupService.register(fullName, email, phone, password);
    this.showLoading.set(false);

    if (!success) {
      this.toast.error('Signup failed. Please try again with a different email or check your network.');
      return;
    }

    this.toast.success('Registration successful. Enter the OTP to verify your account.');
    this.router.navigate(['/signup/verify']);
  }
}
