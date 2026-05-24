import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../auth/auth.service';
import { ToastService } from '../auth/toast.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule],
  template: `
<header class="bg-white border-b border-gray-200 sticky top-0 z-30">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
    <div class="flex items-center gap-3">
      <div class="w-9 h-9 rounded-xl flex items-center justify-center shadow-sm overflow-hidden bg-transparent">
        <img src="/assets/billqube-icon.png" alt="Billqube" class="w-7 h-7 object-contain" />
      </div>
      <div>
        <span class="text-lg font-extrabold text-gray-900 tracking-tight">BillQube</span>
        <span class="hidden sm:inline text-xs text-gray-400 font-medium ml-2">ERP Suite</span>
      </div>
    </div>

    <div class="flex items-center gap-3 relative">
      <button class="relative p-2 rounded-xl text-gray-500 hover:bg-gray-100 hover:text-gray-700 transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
        </svg>
        <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
      </button>

      <div class="relative">
        <button
          type="button"
          (click)="toggleMenu()"
          class="flex items-center gap-2.5 pl-3 border-l border-gray-200 rounded-xl focus:outline-none"
        >
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-sm font-bold">
            {{ auth.currentUser()?.name?.charAt(0) ?? 'A' }}
          </div>
          <div class="hidden sm:block text-left">
            <p class="text-sm font-semibold text-gray-800 leading-tight">{{ auth.currentUser()?.name }}</p>
            <p class="text-xs text-gray-400 leading-tight">{{ auth.currentUser()?.role }}</p>
          </div>
          <svg class="w-4 h-4 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 9l6 6 6-6" />
          </svg>
        </button>

        <div *ngIf="menuOpen()" class="absolute right-0 mt-3 w-48 rounded-2xl border border-gray-200 bg-white shadow-lg ring-1 ring-black ring-opacity-5 z-40">
          <button
            type="button"
            class="w-full flex items-center gap-3 px-4 py-3 text-left text-sm text-gray-700 hover:bg-gray-100 transition-colors"
            (click)="viewProfile()"
          >
            <svg class="w-4 h-4 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.121 17.804A9 9 0 1118.879 6.196 9 9 0 015.121 17.804z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            Profile
          </button>
          <button
            type="button"
            class="w-full flex items-center gap-3 px-4 py-3 text-left text-sm text-red-600 hover:bg-red-50 transition-colors"
            (click)="logout()"
          >
            <svg class="w-4 h-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8v8" />
            </svg>
            Logout
          </button>
        </div>
      </div>
    </div>
  </div>
</header>
  `,
  styles: [
    `:host { display: block; }`
  ]
})
export class HeaderComponent {
  auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);
  menuOpen = signal(false);

  toggleMenu(): void {
    this.menuOpen.update(value => !value);
  }

  viewProfile(): void {
    this.menuOpen.set(false);
    this.router.navigate(['/profile']);
  }

  logout(): void {
    this.menuOpen.set(false);
    this.toast.success('You have been signed out. See you soon!');
    setTimeout(() => this.auth.logout(), 700);
  }
}
