import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../auth/auth.service';

import { ToastService } from '../auth/toast.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './dashboard.component.html'
})
export class DashboardComponent {
  auth = inject(AuthService);
  private toast = inject(ToastService);

  readonly stats = [
    { label: 'Total Revenue',   value: '₹12,48,500', change: '+12.5%', up: true,  icon: 'revenue' },
    { label: 'Invoices Sent',   value: '1,284',       change: '+8.2%',  up: true,  icon: 'invoice' },
    { label: 'Pending Dues',    value: '₹3,20,000',   change: '-4.1%',  up: false, icon: 'pending' },
    { label: 'Active Clients',  value: '348',         change: '+5.7%',  up: true,  icon: 'clients' },
  ];

  readonly recentInvoices = [
    { id: 'INV-2025-0081', client: 'Reliance Industries', amount: '₹45,000', status: 'Paid',    date: '12 May 2025' },
    { id: 'INV-2025-0080', client: 'Tata Consultancy',    amount: '₹1,20,000', status: 'Pending', date: '10 May 2025' },
    { id: 'INV-2025-0079', client: 'Infosys Ltd.',        amount: '₹78,500',  status: 'Paid',    date: '08 May 2025' },
    { id: 'INV-2025-0078', client: 'Wipro Technologies',  amount: '₹32,000',  status: 'Overdue', date: '01 May 2025' },
    { id: 'INV-2025-0077', client: 'HCL Technologies',    amount: '₹55,750',  status: 'Pending', date: '28 Apr 2025' },
  ];

  logout(): void {
    this.toast.success('You have been signed out. See you soon!');
    setTimeout(() => this.auth.logout(), 700);
  }

  get istGreeting(): string {
    const nowInIST = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }));
    const hour = nowInIST.getHours();

    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 16) {
      return 'Good afternoon';
    }
    if (hour < 20) {
      return 'Good evening';
    }
    return 'Good night';
  }

  statusClass(status: string): string {
    return {
      'Paid':    'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200',
      'Pending': 'bg-amber-50  text-amber-700  ring-1 ring-amber-200',
      'Overdue': 'bg-red-50    text-red-700    ring-1 ring-red-200',
    }[status] ?? '';
  }
}
