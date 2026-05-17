import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ToastService, Toast } from '../auth/toast.service';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './toast-container.component.html',
  styleUrls: ['./toast-container.component.scss']
})
export class ToastContainerComponent {
  toastService = inject(ToastService);

  trackById(_: number, toast: Toast): number {
    return toast.id;
  }

  toastTypeClass(type: Toast['type']): string {
    return {
      success: 'border-emerald-100 bg-emerald-50 text-emerald-700',
      error: 'border-rose-100 bg-rose-50 text-rose-700',
      info: 'border-sky-100 bg-sky-50 text-sky-700',
    }[type] ?? 'border-slate-100 bg-slate-50 text-slate-700';
  }
}
