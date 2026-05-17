import { Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';

export interface User {
  email: string;
  name: string;
  role: string;
}

interface MockUser {
  email: string;
  password: string;
  name: string;
  role: string;
}

const MOCK_USERS: MockUser[] = [
  {
    email: 'admin@test.com',
    password: '123456',
    name: 'Admin User',
    role: 'Administrator'
  }
];

const AUTH_KEY = 'billflow_auth_user';
const REMEMBER_KEY = 'billflow_remember';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private _currentUser = signal<User | null>(this.loadUser());

  readonly currentUser = this._currentUser.asReadonly();

  constructor(private router: Router) {}

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

  login(email: string, password: string, rememberMe: boolean): boolean {
    const matched = MOCK_USERS.find(
      u => u.email.toLowerCase() === email.toLowerCase() && u.password === password
    );

    if (!matched) return false;

    const user: User = { email: matched.email, name: matched.name, role: matched.role };
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

  getRememberedEmail(): string {
    return localStorage.getItem(REMEMBER_KEY) ?? '';
  }
}
