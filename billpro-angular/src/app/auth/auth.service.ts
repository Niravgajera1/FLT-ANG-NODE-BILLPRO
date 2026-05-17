import { Injectable, Inject, signal } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { Router } from '@angular/router';
import { API_URL } from '../app.config';

export interface CompanyAddress {
  line1?: string;
  line2?: string;
  city?: string;
  state?: string;
  stateCode?: string;
  pinCode?: string;
  country?: string;
}

export interface BankAccount {
  bankName?: string;
  accountHolderName?: string;
  accountNumber?: string;
  ifscCode?: string;
  accountType?: string;
  branchName?: string;
  branchAddress?: string;
  upiId?: string;
  isDefault?: boolean;
  _id?: string;
}

export interface BusinessInfo {
  _id?: string;
  ownerId?: string;
  legalName?: string;
  tradeName?: string;
  businessType?: string;
  gstin?: string;
  pan?: string;
  fssaiNumber?: string;
  gstType?: string;
  isGSTRegistered?: boolean;
  tcsEnabled?: boolean;
  tdsEnabled?: boolean;
  rcmVendors?: unknown[];
  businessCategory?: string;
  industryType?: string;
  mobile?: string;
  email?: string;
  website?: string;
  registeredAddress?: CompanyAddress;
  fyStartMonth?: number;
  bankAccounts?: BankAccount[];
  createdAt?: string;
  updatedAt?: string;
  __v?: number;
}

export interface User {
  _id?: string;
  email: string;
  fullName?: string;
  name: string;
  mobile?: string;
  role: string;
  referralCode?: string;
  isEmailVerified?: boolean;
  isMobileVerified?: boolean;
  isActive?: boolean;
  loginAttempts?: number;
  onboardingCompleted?: boolean;
  companies?: unknown[];
  businessInfo?: BusinessInfo;
  createdAt?: string;
  updatedAt?: string;
  __v?: number;
}

interface MockUser {
  email: string;
  password: string;
  name: string;
  role: string;
}

interface LoginApiResponse {
  success: boolean;
  message: string;
  data?: {
    accessToken?: string;
    user?: {
      _id?: string;
      fullName?: string;
      name?: string;
      email?: string;
      mobile?: string;
      role?: string;
      referralCode?: string;
      isEmailVerified?: boolean;
      isMobileVerified?: boolean;
      isActive?: boolean;
      loginAttempts?: number;
      onboardingCompleted?: boolean;
      companies?: unknown[];
      businessInfo?: BusinessInfo;
      createdAt?: string;
      updatedAt?: string;
      __v?: number;
    };
  };
}

interface MeApiResponse {
  success: boolean;
  message: string;
  data?: User;
}

interface SimpleApiResponse {
  success: boolean;
  message: string;
  data?: unknown;
}

interface PasswordResetOtpResponse {
  success: boolean;
  message: string;
  data?: {
    secretToken?: string;
    token?: string;
    resetToken?: string;
  };
}

const AUTH_KEY = 'billflow_auth_user';
const REMEMBER_KEY = 'billflow_remember';
const SIGNUP_SNAPSHOT_KEY = 'billflow_signup_snapshot';

const MOCK_USERS: MockUser[] = [
  {
    email: 'admin@test.com',
    password: '123456',
    name: 'Admin User',
    role: 'Administrator'
  }
];

@Injectable({ providedIn: 'root' })
export class AuthService {
  private _currentUser = signal<User | null>(this.loadUser());
  private _lastApiMessage = signal('');
  private _emailVerificationRequired = signal(false);

  readonly currentUser = this._currentUser.asReadonly();
  readonly lastApiMessage = this._lastApiMessage.asReadonly();
  readonly emailVerificationRequired = this._emailVerificationRequired.asReadonly();

  constructor(
    private router: Router,
    private http: HttpClient,
    @Inject(API_URL) private apiUrl: string
  ) {}

  private loadUser(): User | null {
    try {
      const stored = localStorage.getItem(AUTH_KEY);
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  }

  isLoggedIn(): boolean {
    return this._currentUser() !== null;
  }

  emailExists(email: string): boolean {
    return MOCK_USERS.some(u => u.email.toLowerCase() === email.toLowerCase());
  }

  register(name: string, email: string, password: string, role = 'User'): boolean {
    if (this.emailExists(email)) {
      return false;
    }

    MOCK_USERS.push({ email, password, name, role });
    return true;
  }

  async authenticate(email: string, password: string, rememberMe: boolean): Promise<boolean> {
    this._lastApiMessage.set('');
    this._emailVerificationRequired.set(false);
    try {
      const response = await firstValueFrom(
        this.http.post<LoginApiResponse>(`${this.apiUrl}/api/v1/auth/login`, {
          email,
          password
        })
      );

      if (!response?.success) {
        console.error('Login API failed:', response?.message);
        this._lastApiMessage.set(response?.message || 'Invalid email or password. Please try again.');
        this._emailVerificationRequired.set(this.isEmailVerificationMessage(response?.message));
        return false;
      }

      const apiUser = response.data?.user;
      const savedSnapshot = this.loadSignupSnapshot();
      const user: User = {
        _id: apiUser?._id,
        email: apiUser?.email ?? email,
        fullName: apiUser?.fullName ?? apiUser?.name ?? email,
        name: apiUser?.fullName ?? apiUser?.name ?? email,
        mobile: apiUser?.mobile ?? savedSnapshot?.mobile,
        role: apiUser?.role ?? 'User',
        referralCode: apiUser?.referralCode ?? savedSnapshot?.referralCode,
        isEmailVerified: apiUser?.isEmailVerified,
        isMobileVerified: apiUser?.isMobileVerified,
        isActive: apiUser?.isActive,
        loginAttempts: apiUser?.loginAttempts,
        onboardingCompleted: apiUser?.onboardingCompleted,
        companies: apiUser?.companies,
        businessInfo: (apiUser as any)?.businessInfo as BusinessInfo | undefined,
        createdAt: apiUser?.createdAt,
        updatedAt: apiUser?.updatedAt,
        __v: apiUser?.__v
      };

      this._currentUser.set(user);
      localStorage.setItem(AUTH_KEY, JSON.stringify(user));

      if (rememberMe) {
        localStorage.setItem(REMEMBER_KEY, email);
      } else {
        localStorage.removeItem(REMEMBER_KEY);
      }

      if (response.data?.accessToken) {
        localStorage.setItem('billflow_auth_token', response.data.accessToken);
      }

      this._lastApiMessage.set(response.message || 'Welcome back! Redirecting to dashboard.');
      return true;
    } catch (error) {
      console.error('Login API error:', error);
      const message = this.getApiMessage(error, 'Invalid email or password. Please try again.');
      this._lastApiMessage.set(message);
      this._emailVerificationRequired.set(this.isEmailVerificationMessage(message));
      return false;
    }
  }

  async generateEmailVerificationOtp(email: string): Promise<boolean> {
    this._lastApiMessage.set('');
    try {
      const response = await firstValueFrom(
        this.http.post<SimpleApiResponse>(`${this.apiUrl}/api/v1/auth/resend-otp`, {
          email: email
        })
      );

      if (!response?.success) {
        this._lastApiMessage.set(response?.message || 'Could not generate OTP. Please try again.');
        return false;
      }

      this._lastApiMessage.set(response.message || 'OTP sent successfully. Please check your email.');
      return true;
    } catch (error) {
      console.error('Generate email verification OTP error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'Could not generate OTP. Please try again.'));
      return false;
    }
  }

  async verifyEmailOtp(email: string, otp: string): Promise<boolean> {
    this._lastApiMessage.set('');
    try {
      const response = await firstValueFrom(
        this.http.post<SimpleApiResponse>(`${this.apiUrl}/api/v1/auth/verify-otp`, {
          identifier: email,
          otp: otp.trim(),
          purpose: 'email_verify'
        })
      );

      if (!response?.success) {
        this._lastApiMessage.set(response?.message || 'The OTP is incorrect or verification failed. Please try again.');
        return false;
      }

      this._lastApiMessage.set(response.message || 'Email verified successfully.');
      this._emailVerificationRequired.set(false);
      return true;
    } catch (error) {
      console.error('Email OTP verification error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'The OTP is incorrect or verification failed. Please try again.'));
      return false;
    }
  }

  async sendForgotPasswordOtp(email: string): Promise<boolean> {
    this._lastApiMessage.set('');
    try {
      const response = await firstValueFrom(
        this.http.post<SimpleApiResponse>(`${this.apiUrl}/api/v1/auth/forgot-password`, {
          email
        })
      );

      if (!response?.success) {
        this._lastApiMessage.set(response?.message || 'Could not send OTP. Please try again.');
        return false;
      }

      this._lastApiMessage.set(response.message || 'OTP sent successfully. Please check your email.');
      return true;
    } catch (error) {
      console.error('Forgot password OTP error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'Could not send OTP. Please try again.'));
      return false;
    }
  }

  async verifyForgotPasswordOtp(email: string, otp: string): Promise<string | null> {
    this._lastApiMessage.set('');
    try {
      const response = await firstValueFrom(
        this.http.post<PasswordResetOtpResponse>(`${this.apiUrl}/api/v1/auth/verify-otp?type=1`, {
          identifier: email,
          otp: otp.trim(),
          purpose: 'password_reset'
        })
      );

      if (!response?.success) {
        this._lastApiMessage.set(response?.message || 'The OTP is incorrect or verification failed. Please try again.');
        return null;
      }

      const secretToken = response.data?.secretToken ?? response.data?.token ?? response.data?.resetToken;
      if (!secretToken) {
        this._lastApiMessage.set('OTP verified, but reset token was not returned. Please try again.');
        return null;
      }

      this._lastApiMessage.set(response.message || 'OTP verified successfully.');
      return secretToken;
    } catch (error) {
      console.error('Forgot password OTP verification error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'The OTP is incorrect or verification failed. Please try again.'));
      return null;
    }
  }

  async resetPassword(secretToken: string, password: string, confirmPassword: string): Promise<boolean> {
    this._lastApiMessage.set('');
    try {
      const response = await firstValueFrom(
        this.http.post<SimpleApiResponse>(`${this.apiUrl}/api/v1/auth/reset-password`, {
          token: secretToken,
          password,
          confirmPassword
        })
      );

      if (!response?.success) {
        this._lastApiMessage.set(response?.message || 'Could not reset password. Please try again.');
        return false;
      }

      this._lastApiMessage.set(response.message || 'Password reset successfully. Please sign in with your new password.');
      return true;
    } catch (error) {
      console.error('Reset password error:', error);
      this._lastApiMessage.set(this.getApiMessage(error, 'Could not reset password. Please try again.'));
      return false;
    }
  }

  async refreshCurrentUser(): Promise<void> {
    const token = this.getAuthToken();
    if (!token) {
      return;
    }

    try {
      const response = await firstValueFrom(
        this.http.get<MeApiResponse>(`${this.apiUrl}/api/v1/auth/me`, {
          headers: new HttpHeaders({ Authorization: `Bearer ${token}` })
        })
      );

      if (response?.success && response.data) {
        const apiUser = response.data;
        const user: User = {
          _id: apiUser._id,
          email: apiUser.email,
          fullName: apiUser.fullName ?? apiUser.name ?? apiUser.email,
          name: apiUser.fullName ?? apiUser.name ?? apiUser.email,
          mobile: apiUser.mobile,
          role: apiUser.role,
          referralCode: apiUser.referralCode,
          isEmailVerified: apiUser.isEmailVerified,
          isMobileVerified: apiUser.isMobileVerified,
          isActive: apiUser.isActive,
          loginAttempts: apiUser.loginAttempts,
          onboardingCompleted: apiUser.onboardingCompleted,
          companies: apiUser.companies,
          businessInfo: apiUser.businessInfo,
          createdAt: apiUser.createdAt,
          updatedAt: apiUser.updatedAt,
          __v: apiUser.__v
        };

        this.setCurrentUser(user);
      }
    } catch (error) {
      console.error('Refresh user API error:', error);
    }
  }

  private loadSignupSnapshot(): { mobile?: string; referralCode?: string } | null {
    try {
      const raw = localStorage.getItem(SIGNUP_SNAPSHOT_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  login(email: string, password: string, rememberMe: boolean): boolean {
    const matched = MOCK_USERS.find(
      u => u.email.toLowerCase() === email.toLowerCase() && u.password === password
    );

    if (!matched) return false;

    const user: User = {
      email: matched.email,
      name: matched.name,
      fullName: matched.name,
      role: matched.role,
      isActive: true,
      loginAttempts: 0,
      onboardingCompleted: false,
      companies: []
    };
    this._currentUser.set(user);
    localStorage.setItem(AUTH_KEY, JSON.stringify(user));

    if (rememberMe) {
      localStorage.setItem(REMEMBER_KEY, email);
    } else {
      localStorage.removeItem(REMEMBER_KEY);
    }

    return true;
  }

  logout(): void {
    this._currentUser.set(null);
    localStorage.removeItem(AUTH_KEY);
    this.router.navigate(['/login']);
  }

  getAuthToken(): string | null {
    return localStorage.getItem('billflow_auth_token');
  }

  setCurrentUser(user: User): void {
    this._currentUser.set(user);
    localStorage.setItem(AUTH_KEY, JSON.stringify(user));
  }

  getRememberedEmail(): string {
    return localStorage.getItem(REMEMBER_KEY) ?? '';
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

  private isEmailVerificationMessage(message?: string): boolean {
    return (message ?? '').toLowerCase().includes('verify your email');
  }
}
