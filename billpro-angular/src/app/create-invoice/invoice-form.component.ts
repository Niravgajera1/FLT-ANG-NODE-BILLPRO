import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ToastService } from '../auth/toast.service';

@Component({
  selector: 'app-invoice-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './invoice-form.component.html',
  styleUrl: './invoice-form.component.scss'
})
export class InvoiceFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);

  form: FormGroup = this.fb.group({
    customer: ['', Validators.required],
    amount: ['', [Validators.required, Validators.pattern(/^\$?\d+(?:\.\d{2})?$/)]],
    dueDate: ['', Validators.required],
    status: ['Due', Validators.required],
    notes: ['']
  });

  pageTitle = 'Add Invoice';
  submitText = 'Add Invoice';
  private invoiceId: string | null = null;

  ngOnInit(): void {
    this.invoiceId = this.route.snapshot.paramMap.get('id');
    if (this.invoiceId) {
      this.pageTitle = 'Edit Invoice';
      this.submitText = 'Save Changes';
      this.form.patchValue({
        customer: 'Greenfield Ventures',
        amount: '$1,180.00',
        dueDate: '2026-05-18',
        status: 'Overdue',
        notes: 'Second reminder sent.'
      });
    }
  }

  cancel(): void {
    this.router.navigate(['/create-invoice']);
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.toast.error('Please correct the form errors before submitting.');
      return;
    }

    this.toast.success(this.invoiceId ? 'Invoice updated successfully.' : 'Invoice created successfully.');
    this.router.navigate(['/create-invoice']);
  }
}
