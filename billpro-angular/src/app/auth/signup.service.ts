import { Injectable, signal } from '@angular/core';
import { AuthService } from './auth.service';

export interface PendingSignup {
  fullName: string;
  email: string;
  phone: string;
  password: string;
  otp: string;
  otpSentAt: number;
}

@Injectable({ providedIn: 'root' })
export class SignupService {
  private readonly _pending = signal<PendingSignup | null>(null);
  readonly pending = this._pending.asReadonly();

  constructor(private auth: AuthService) {}

  register(fullName: string, email: string, phone: string, password: string): boolean {
    if (this.auth.emailExists(email)) {
      return false;
    }

    const otp = this.generateOtp();
    this._pending.set({
      fullName,
      email,
      phone,
      password,
      otp,
      otpSentAt: Date.now()
    });

    console.log(`Signup OTP for ${email}: ${otp}`);
    return true;
  }

  verifyOtp(code: string): boolean {
    const current = this._pending();
    return !!current && current.otp === code.trim();
  }

  resendOtp(): string | null {
    const current = this._pending();
    if (!current) return null;

    const otp = this.generateOtp();
    this._pending.set({ ...current, otp, otpSentAt: Date.now() });
    console.log(`Resent signup OTP for ${current.email}: ${otp}`);
    return otp;
  }

  completeRegistration(): boolean {
    const current = this._pending();
    if (!current) return false;
    const registered = this.auth.register(current.fullName, current.email, current.password);
    if (registered) {
      this._pending.set(null);
    }
    return registered;
  }

  clear(): void {
    this._pending.set(null);
  }

  private generateOtp(): string {
    return String(Math.floor(100000 + Math.random() * 900000));
  }
}
