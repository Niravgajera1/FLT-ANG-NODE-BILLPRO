import { Injectable, signal } from '@angular/core';

export interface Toast {
  id: number;
  message: string;
  type: 'success' | 'error' | 'info';
  hiding: boolean;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
  private _toasts = signal<Toast[]>([]);
  readonly toasts = this._toasts.asReadonly();

  private nextId = 0;

  show(message: string, type: Toast['type'] = 'info', duration = 4000): void {
    const id = ++this.nextId;
    const toast: Toast = { id, message, type, hiding: false };
    this._toasts.update(list => [...list, toast]);

    setTimeout(() => this.hide(id), duration);
  }

  success(message: string) { this.show(message, 'success'); }
  error(message: string)   { this.show(message, 'error'); }
  info(message: string)    { this.show(message, 'info'); }

  hide(id: number): void {
    // Mark as hiding (triggers slide-out animation)
    this._toasts.update(list =>
      list.map(t => t.id === id ? { ...t, hiding: true } : t)
    );
    // Remove after animation
    setTimeout(() => {
      this._toasts.update(list => list.filter(t => t.id !== id));
    }, 350);
  }
}
