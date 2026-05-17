import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../auth.service';
import { ToastService } from '../toast.service';

type ResetStep = 'email' | 'otp' | 'password';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './forgot-password.component.html'
})
export class ForgotPasswordComponent {
  private fb = inject(FormBuilder);
  private auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);

  step = signal<ResetStep>('email');
  isLoading = signal(false);
  showPassword = signal(false);
  showConfirmPassword = signal(false);
  private secretToken = signal('');

  emailForm: FormGroup = this.fb.group({
    email: ['', [Validators.required, Validators.email]]
  });

  otpForm: FormGroup = this.fb.group({
    otp: ['', [Validators.required, Validators.pattern(/^[0-9]{6}$/)]]
  });

  passwordForm: FormGroup = this.fb.group(
    {
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', [Validators.required]]
    },
    { validators: this.passwordsMatch }
  );

  get emailCtrl() { return this.emailForm.get('email')!; }
  get otpCtrl() { return this.otpForm.get('otp')!; }
  get passwordCtrl() { return this.passwordForm.get('password')!; }
  get confirmPasswordCtrl() { return this.passwordForm.get('confirmPassword')!; }

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
    if (ctrl.errors['required']) return 'New password is required.';
    if (ctrl.errors['minlength']) return 'Password must be at least 6 characters.';
    return '';
  }

  get confirmPasswordError(): string {
    const ctrl = this.confirmPasswordCtrl;
    if (!ctrl.touched) return '';
    if (ctrl.errors?.['required']) return 'Please confirm your password.';
    if (this.passwordForm.errors?.['passwordMismatch']) return 'Passwords do not match.';
    return '';
  }

  get currentEmail(): string {
    return this.emailCtrl.value;
  }

  togglePassword(): void {
    this.showPassword.update(value => !value);
  }

  toggleConfirmPassword(): void {
    this.showConfirmPassword.update(value => !value);
  }

  onOtpInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const value = input.value.replace(/\D/g, '').slice(0, 6);
    this.otpCtrl.setValue(value, { emitEvent: false });
  }

  async sendOtp(): Promise<void> {
    this.emailForm.markAllAsTouched();
    if (this.emailForm.invalid) return;

    this.isLoading.set(true);
    const sent = await this.auth.sendForgotPasswordOtp(this.currentEmail);
    const message = this.auth.lastApiMessage();
    this.isLoading.set(false);

    if (!sent) {
      this.toast.error(message || 'Could not send OTP. Please try again.');
      return;
    }

    this.step.set('otp');
    this.toast.success(message || 'OTP sent successfully. Please check your email.');
  }

  async verifyOtp(): Promise<void> {
    this.otpForm.markAllAsTouched();
    if (this.otpForm.invalid) return;

    this.isLoading.set(true);
    const token = await this.auth.verifyForgotPasswordOtp(this.currentEmail, this.otpCtrl.value);
    const message = this.auth.lastApiMessage();
    this.isLoading.set(false);

    if (!token) {
      this.toast.error(message || 'The OTP is incorrect or verification failed. Please try again.');
      return;
    }

    this.secretToken.set(token);
    this.step.set('password');
    this.toast.success(message || 'OTP verified successfully.');
  }

  async resetPassword(): Promise<void> {
    this.passwordForm.markAllAsTouched();
    if (this.passwordForm.invalid) return;

    const token = this.secretToken();
    if (!token) {
      this.toast.error('Reset session expired. Please verify OTP again.');
      this.step.set('otp');
      return;
    }

    const { password, confirmPassword } = this.passwordForm.value;
    this.isLoading.set(true);
    const reset = await this.auth.resetPassword(token, password, confirmPassword);
    const message = this.auth.lastApiMessage();
    this.isLoading.set(false);

    if (!reset) {
      this.toast.error(message || 'Could not reset password. Please try again.');
      return;
    }

    this.toast.success(message || 'Password reset successfully. Please sign in.');
    this.router.navigate(['/login'], { queryParams: { email: this.currentEmail } });
  }

  resendOtp(): void {
    this.sendOtp();
  }

  backToEmail(): void {
    this.step.set('email');
    this.otpForm.reset();
    this.secretToken.set('');
  }

  private passwordsMatch(control: AbstractControl): ValidationErrors | null {
    const password = control.get('password')?.value;
    const confirmPassword = control.get('confirmPassword')?.value;
    return password && confirmPassword && password !== confirmPassword ? { passwordMismatch: true } : null;
  }
}
