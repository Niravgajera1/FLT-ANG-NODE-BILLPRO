import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { ToastService } from '../../auth/toast.service';

@Component({
  selector: 'app-product-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './product-form.component.html',
  styleUrl: './product-form.component.scss'
})
export class ProductFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);

  form: FormGroup = this.fb.group({
    name: ['', Validators.required],
    sku: ['', Validators.required],
    category: ['', Validators.required],
    price: ['', [Validators.required, Validators.pattern(/^\$?\d+(?:\.\d{2})?$/)]],
    stock: [0, [Validators.required, Validators.min(0)]],
    status: ['In stock', Validators.required],
    supplier: ['', Validators.required]
  });

  pageTitle = 'Add Product';
  submitText = 'Add Product';
  private productId: string | null = null;

  ngOnInit(): void {
    this.productId = this.route.snapshot.paramMap.get('id');
    if (this.productId) {
      this.pageTitle = 'Edit Product';
      this.submitText = 'Save Changes';
      this.form.patchValue({
        name: 'Wireless Keyboard',
        sku: 'KB-112',
        category: 'Electronics',
        price: '$39.50',
        stock: 18,
        status: 'Low stock',
        supplier: 'Keyline Supplies'
      });
    }
  }

  cancel(): void {
    this.router.navigate(['/products']);
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.toast.error('Please fix the highlighted fields before saving.');
      return;
    }

    this.toast.success(this.productId ? 'Product updated successfully.' : 'Product added successfully.');
    this.router.navigate(['/products']);
  }
}
