import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ToastService } from '../../auth/toast.service';

@Component({
  selector: 'app-company-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './company-form.component.html',
  styleUrl: './company-form.component.scss'
})
export class CompanyFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);

  form: FormGroup = this.fb.group({
    name: ['', Validators.required],
    industry: ['', Validators.required],
    location: ['', Validators.required],
    employees: [0, [Validators.required, Validators.min(1)]],
    status: ['Active', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    phone: ['', Validators.required]
  });

  pageTitle = 'Add Company';
  submitText = 'Add Company';
  private companyId: string | null = null;

  ngOnInit(): void {
    this.companyId = this.route.snapshot.paramMap.get('id');
    if (this.companyId) {
      this.pageTitle = 'Edit Company';
      this.submitText = 'Save Changes';
      this.form.patchValue({
        name: 'Acme Corporation',
        industry: 'Manufacturing',
        location: 'Austin, TX',
        employees: 124,
        status: 'Active',
        email: 'admin@acme.example',
        phone: '(512) 555-0199'
      });
    }
  }

  cancel(): void {
    this.router.navigate(['/company']);
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.toast.error('Please fill in the required fields before saving.');
      return;
    }

    this.toast.success(this.companyId ? 'Company updated successfully.' : 'Company added successfully.');
    this.router.navigate(['/company']);
  }
}
