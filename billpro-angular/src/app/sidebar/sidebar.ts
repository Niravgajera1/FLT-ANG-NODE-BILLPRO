import { Component, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, RouterLinkActive, RouterModule } from '@angular/router';
import { AuthService } from '../auth/auth.service';
import { ToastService } from '../auth/toast.service';

interface NavItem {
  label: string;
  icon: string;
  route: string;
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.html',
  styleUrl: './sidebar.scss',
})
export class Sidebar implements OnInit, OnDestroy {
  auth = inject(AuthService);
  private toast = inject(ToastService);

  collapsed = signal(false);

  readonly navItems: NavItem[] = [
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard' },
    { label: 'Customer Details', icon: 'company', route: '/customer' },
    { label: 'Vendor Details', icon: 'vendor', route: '/vendor' },
    { label: 'Product Details', icon: 'product', route: '/products' },
    { label: 'Create Invoice', icon: 'invoice', route: '/create-invoice' },
    { label: 'Purchase Bill', icon: 'purchase', route: '/purchase-bill' },
    { label: 'Product Categories', icon: 'category', route: '/category' },
  ];

  ngOnInit(): void {
    this.updateSidebarWidth();
  }

  ngOnDestroy(): void {
    document.documentElement.style.setProperty('--app-sidebar-width', '0px');
  }

  toggleSidebar() {
    this.collapsed.update(value => {
      const next = !value;
      document.documentElement.style.setProperty('--app-sidebar-width', next ? '5rem' : '16rem');
      return next;
    });
  }

  private updateSidebarWidth(): void {
    const width = this.collapsed() ? '5rem' : '16rem';
    document.documentElement.style.setProperty('--app-sidebar-width', width);
  }

  logout(): void {
    this.toast.success('You have been signed out. See you soon!');
    setTimeout(() => this.auth.logout(), 700);
  }
}
