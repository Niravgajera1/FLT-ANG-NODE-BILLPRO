import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { ToastService } from '../auth/toast.service';
import { ConfirmService } from '../ui/confirm.service';

interface Product {
  id: string;
  name: string;
  sku: string;
  category: string;
  price: string;
  stock: number;
  status: 'In stock' | 'Low stock' | 'Out of stock';
}

@Component({
  selector: 'app-products',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './products.component.html',
  styleUrl: './products.component.scss'
})
export class ProductsComponent {
  private router = inject(Router);
  private toast = inject(ToastService);
  private confirm = inject(ConfirmService);

  products = signal<Product[]>([
    {
      id: 'p1',
      name: 'Premium Notebook',
      sku: 'NB-019',
      category: 'Office Supplies',
      price: '$19.99',
      stock: 124,
      status: 'In stock'
    },
    {
      id: 'p2',
      name: 'Wireless Keyboard',
      sku: 'KB-112',
      category: 'Electronics',
      price: '$39.50',
      stock: 18,
      status: 'Low stock'
    },
    {
      id: 'p3',
      name: 'Eco Paper Ream',
      sku: 'PR-227',
      category: 'Paper Goods',
      price: '$9.75',
      stock: 0,
      status: 'Out of stock'
    }
  ]);

  editProduct(id: string): void {
    this.router.navigate(['/products', id, 'edit']);
  }

  async deleteProduct(id: string): Promise<void> {
    const confirmed = await this.confirm.show('Are you sure you want to delete this product?', {
      title: 'Delete Product',
      confirmText: 'Delete',
      cancelText: 'Cancel'
    });
    if (!confirmed) {
      return;
    }

    this.products.update(list => list.filter(product => product.id !== id));
    this.toast.success('Product deleted successfully.');
  }
}
