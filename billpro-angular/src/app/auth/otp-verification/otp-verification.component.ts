import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../auth.service';
import { SignupService } from '../signup.service';
import { ToastService } from '../toast.service';

@Component({
  selector: 'app-otp-verification',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './otp-verification.component.html'
})
export class OtpVerificationComponent {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private auth = inject(AuthService);
  private signupService = inject(SignupService);
  private toast = inject(ToastService);

  form: FormGroup = this.fb.group({
    otp: ['', [Validators.required, Validators.pattern(/^[0-9]{6}$/)]]
  });

  get otpCtrl() { return this.form.get('otp')!; }

  get signupData() {
    return this.signupService.pending();
  }

  onOtpInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const value = input.value.replace(/\D/g, '').slice(0, 6);
    this.otpCtrl.setValue(value, { emitEvent: false });
  }

  onSubmit(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    if (!this.signupData) {
      this.router.navigate(['/signup']);
      return;
    }

    if (!this.signupService.verifyOtp(this.form.value.otp)) {
      this.toast.error('The OTP is incorrect. Please try again.');
      return;
    }

    const signupData = this.signupService.pending();
    if (!signupData) {
      this.toast.error('Signup session expired. Please register again.');
      this.router.navigate(['/signup']);
      return;
    }

    const created = this.signupService.completeRegistration();
    if (!created) {
      this.toast.error('Unable to complete registration. Please try again.');
      return;
    }

    this.toast.success('Account verified and ready to use!');
    this.auth.login(signupData.email, signupData.password, false);
    this.router.navigate(['/dashboard']);
  }

  resendOtp(): void {
    const result = this.signupService.resendOtp();
    if (!result) {
      this.toast.error('No signup session found. Please start again.');
      this.router.navigate(['/signup']);
      return;
    }

    this.toast.info('A new OTP has been sent. Please check your inbox.');
  }

  cancel(): void {
    this.signupService.clear();
    this.router.navigate(['/login']);
  }
}
