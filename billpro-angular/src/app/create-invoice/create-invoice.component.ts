import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { ToastService } from '../auth/toast.service';
import { ConfirmService } from '../ui/confirm.service';

interface Invoice {
  id: string;
  customer: string;
  amount: string;
  dueDate: string;
  status: 'Paid' | 'Due' | 'Overdue';
}

@Component({
  selector: 'app-create-invoice',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './create-invoice.component.html',
  styleUrl: './create-invoice.component.scss'
})
export class CreateInvoiceComponent {
  private router = inject(Router);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);

  invoices = signal<Invoice[]>([
    { id: 'i1', customer: 'Acme Corporation', amount: '$3,250.00', dueDate: '2026-05-30', status: 'Due' },
    { id: 'i2', customer: 'Greenfield Ventures', amount: '$1,180.00', dueDate: '2026-05-18', status: 'Overdue' },
    { id: 'i3', customer: 'Oceanic Imports', amount: '$5,520.00', dueDate: '2026-06-10', status: 'Paid' }
  ]);

  editInvoice(id: string): void {
    this.router.navigate(['/create-invoice', id, 'edit']);
  }

  async deleteInvoice(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this invoice?', {
      title: 'Delete Invoice',
      confirmText: 'Delete',
      cancelText: 'Cancel'
    });
    if (!confirmed) {
      return;
    }

    this.invoices.update(list => list.filter(invoice => invoice.id !== id));
    this.toast.success('Invoice deleted successfully.');
  }
}
