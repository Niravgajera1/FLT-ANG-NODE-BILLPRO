import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { ToastService } from '../../auth/toast.service';
import { ConfirmService } from '../../ui/confirm.service';

interface Company {
  id: string;
  name: string;
  industry: string;
  location: string;
  employees: number;
  status: 'Active' | 'Inactive';
}

@Component({
  selector: 'app-company-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './company-list.html',
  styleUrl: './company-list.scss',
})
export class CompanyList {
  private router = inject(Router);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);

  companies = signal<Company[]>([
    {
      id: '1',
      name: 'Acme Corporation',
      industry: 'Manufacturing',
      location: 'Austin, TX',
      employees: 124,
      status: 'Active'
    },
    {
      id: '2',
      name: 'Greenfield Ventures',
      industry: 'Agriculture',
      location: 'Des Moines, IA',
      employees: 58,
      status: 'Active'
    },
    {
      id: '3',
      name: 'Oceanic Imports',
      industry: 'Retail',
      location: 'Miami, FL',
      employees: 34,
      status: 'Inactive'
    }
  ]);

  editCompany(id: string): void {
    this.router.navigate(['/company', id, 'edit']);
  }

  async deleteCompany(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this company?', {
      title: 'Delete Company',
      confirmText: 'Delete',
      cancelText: 'Cancel'
    });
    if (!confirmed) {
      return;
    }

    this.companies.update(list => list.filter(company => company.id !== id));
    this.toast.success('Company deleted successfully.');
  }
}
