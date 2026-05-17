import { Injectable, Inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { AuthService } from './auth.service';
import { API_URL } from '../app.config';

export interface PendingSignup {
  fullName: string;
  email: string;
  mobile: string;
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
  private readonly _lastApiMessage = signal('');
  readonly pending = this._pending.asReadonly();
  readonly lastApiMessage = this._lastApiMessage.asReadonly();

  constructor(
    private auth: AuthService,
    private http: HttpClient,
    @Inject(API_URL) private apiUrl: string
  ) {}

  async register(
    fullName: string,
    email: string,
    mobile: string,
    password: string,
    confirmPassword: string,
    acceptTerms: boolean,
    referralCode: string
  ): Promise<boolean> {
    this._lastApiMessage.set('');
    if (this.auth.emailExists(email)) {
      this._lastApiMessage.set('Email already exists.');
      return false;
    }

    const payload = {
      fullName,
      email,
      mobile,
      password,
      confirmPassword,
      acceptTerms,
      referralCode
    };
    try {
      const response = await firstValueFrom(
        this.http.post<SignupApiResponse>(`${this.apiUrl}/api/v1/auth/register`, payload)
      );

      if (!response?.success) {
        console.error('Signup failed:', response?.message);
        this._lastApiMessage.set(response?.message || 'Signup failed. Please try again.');
        return false;
      }

      localStorage.setItem(
        'billflow_signup_snapshot',
        JSON.stringify({ fullName, email, mobile, referralCode })
      );

      const otp = this.generateOtp();
      this._pending.set({
        fullName,
        email,
        mobile,
        password,
        otp,
        otpSentAt: Date.now(),
        identifier: email,
        purpose: 'email_verify',
        serverData: response.data
      });

      console.log(`Signup API succeeded for ${email}`);
      this._lastApiMessage.set(response.message || 'Registration successful. Enter the OTP to verify your account.');
      return true;
    } catch (error) {
      console.error('Signup API error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'Signup failed. Please try again with a different email or check your network.'));
      return false;
    }
  }

  async verifyOtp(code: string): Promise<boolean> {
    this._lastApiMessage.set('');
    const current = this._pending();
    if (!current) {
      this._lastApiMessage.set('Signup session expired. Please register again.');
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
        this._lastApiMessage.set(response?.message || 'The OTP is incorrect or verification failed. Please try again.');
        return false;
      }

      this._lastApiMessage.set(response.message || 'Account verified and ready to use!');
      return true;
    } catch (error) {
      console.error('OTP verification error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'The OTP is incorrect or verification failed. Please try again.'));
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

  private getApiMessage(error: unknown, fallback: string): string {
    if (error && typeof error === 'object' && 'error' in error) {
      const apiError = (error as { error?: { message?: unknown } }).error;
      if (typeof apiError?.message === 'string' && apiError.message.trim()) {
        return apiError.message;
      }
    }

    return fallback;
  }
}
