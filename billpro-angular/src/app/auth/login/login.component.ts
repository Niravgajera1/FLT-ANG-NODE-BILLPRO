import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../auth.service';
import { ToastService } from '../toast.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './login.component.html'
})
export class LoginComponent implements OnInit {
  private fb = inject(FormBuilder);
  private auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);

  showPassword = signal(false);
  isLoading = signal(false);
  isOtpLoading = signal(false);
  showEmailVerification = signal(false);
  otpSent = signal(false);
  private pendingCredentials = signal<{ email: string; password: string; rememberMe: boolean } | null>(null);

  form: FormGroup = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    rememberMe: [false]
  });
  otpForm: FormGroup = this.fb.group({
    otp: ['', [Validators.required, Validators.pattern(/^[0-9]{6}$/)]]
  });

  ngOnInit(): void {
    const remembered = this.auth.getRememberedEmail();
    if (remembered) {
      this.form.patchValue({ email: remembered, rememberMe: true });
    }
  }

  get emailCtrl() { return this.form.get('email')!; }
  get passwordCtrl() { return this.form.get('password')!; }
  get otpCtrl() { return this.otpForm.get('otp')!; }

  get emailError(): string {
    const ctrl = this.emailCtrl;
    if (!ctrl.touched || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Email is required.';
    if (ctrl.errors['email']) return 'Please enter a valid email address.';
    return '';
  }

  get passwordError(): string {
    const ctrl = this.passwordCtrl;
    if (!ctrl.touched || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Password is required.';
    if (ctrl.errors['minlength']) return 'Password must be at least 6 characters.';
    return '';
  }

  togglePassword(): void {
    this.showPassword.update(v => !v);
  }

  onOtpInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const value = input.value.replace(/\D/g, '').slice(0, 6);
    this.otpCtrl.setValue(value, { emitEvent: false });
  }

  async onSubmit(): Promise<void> {
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    this.isLoading.set(true);

    const { email, password, rememberMe } = this.form.value;
    const success = await this.auth.authenticate(email, password, rememberMe);
    const message = this.auth.lastApiMessage();

    if (success) {
      this.toast.success(message || 'Welcome back! Redirecting to dashboard...');
      this.isLoading.set(false);
      this.router.navigate(['/dashboard']);
    } else {
      this.toast.error(message || 'Invalid email or password. Please try again.');
      this.isLoading.set(false);
      if (this.auth.emailVerificationRequired()) {
        this.pendingCredentials.set({ email, password, rememberMe });
        this.showEmailVerification.set(true);
        this.otpSent.set(false);
      } else {
        this.passwordCtrl.reset();
      }
    }
  }

  async generateOtp(): Promise<void> {
    const email = this.pendingCredentials()?.email ?? this.emailCtrl.value;
    if (!email || this.emailCtrl.invalid) {
      this.emailCtrl.markAsTouched();
      return;
    }

    this.isOtpLoading.set(true);
    const sent = await this.auth.generateEmailVerificationOtp(email);
    const message = this.auth.lastApiMessage();
    this.isOtpLoading.set(false);

    if (!sent) {
      this.toast.error(message || 'Could not generate OTP. Please try again.');
      return;
    }

    this.otpSent.set(true);
    this.toast.success(message || 'OTP sent successfully. Please check your email.');
  }

  async verifyOtp(): Promise<void> {
    this.otpForm.markAllAsTouched();
    if (this.otpForm.invalid) {
      return;
    }

    const credentials = this.pendingCredentials();
    if (!credentials) {
      this.toast.error('Login session expired. Please enter your credentials again.');
      this.showEmailVerification.set(false);
      return;
    }

    this.isOtpLoading.set(true);
    const verified = await this.auth.verifyEmailOtp(credentials.email, this.otpCtrl.value);
    let message = this.auth.lastApiMessage();

    if (!verified) {
      this.isOtpLoading.set(false);
      this.toast.error(message || 'The OTP is incorrect or verification failed. Please try again.');
      return;
    }

    const loggedIn = await this.auth.authenticate(credentials.email, credentials.password, credentials.rememberMe);
    message = this.auth.lastApiMessage();
    this.isOtpLoading.set(false);

    if (!loggedIn) {
      this.toast.error(message || 'Email verified, but login failed. Please try signing in again.');
      return;
    }

    this.toast.success(message || 'Email verified. Redirecting to dashboard...');
    this.router.navigate(['/dashboard']);
  }

  cancelVerification(): void {
    this.showEmailVerification.set(false);
    this.otpSent.set(false);
    this.pendingCredentials.set(null);
    this.otpForm.reset();
  }
}
