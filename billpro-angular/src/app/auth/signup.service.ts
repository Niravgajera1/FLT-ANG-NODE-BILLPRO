import { Injectable, Inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { AuthService } from './auth.service';
import { API_URL } from '../app.config';

export interface PendingSignup {
  fullName: string;
  email: string;
  phone: string;
  password: string;
  otp: string;
  otpSentAt: number;
  identifier: string;
  purpose: string;
  serverData?: unknown;
}

interface SignupApiResponse {
  success: boolean;
  message: string;
  data?: unknown;
}

@Injectable({ providedIn: 'root' })
export class SignupService {
  private readonly _pending = signal<PendingSignup | null>(null);
  readonly pending = this._pending.asReadonly();

  constructor(
    private auth: AuthService,
    private http: HttpClient,
    @Inject(API_URL) private apiUrl: string
  ) {}

  async register(fullName: string, email: string, phone: string, password: string): Promise<boolean> {
    if (this.auth.emailExists(email)) {
      return false;
    }

    const payload = { fullName, email, phone, password };
    try {
      const response = await firstValueFrom(
        this.http.post<SignupApiResponse>(`${this.apiUrl}/api/v1/auth/register`, payload)
      );

      if (!response?.success) {
        console.error('Signup failed:', response?.message);
        return false;
      }

      const otp = this.generateOtp();
      this._pending.set({
        fullName,
        email,
        phone,
        password,
        otp,
        otpSentAt: Date.now(),
        identifier: email,
        purpose: 'email_verify',
        serverData: response.data
      });

      console.log(`Signup API succeeded for ${email}`);
      return true;
    } catch (error) {
      console.error('Signup API error:', error);
      return false;
    }
  }

  async verifyOtp(code: string): Promise<boolean> {
    const current = this._pending();
    if (!current) {
      return false;
    }

    try {
      const response = await firstValueFrom(
        this.http.post<SignupApiResponse>(`${this.apiUrl}/api/v1/auth/verify-otp`, {
          identifier: current.identifier,
          otp: code.trim(),
          purpose: current.purpose
        })
      );

      if (!response?.success) {
        console.error('OTP verification failed:', response?.message);
        return false;
      }

      return true;
    } catch (error) {
      console.error('OTP verification error:', error);
      return false;
    }
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
