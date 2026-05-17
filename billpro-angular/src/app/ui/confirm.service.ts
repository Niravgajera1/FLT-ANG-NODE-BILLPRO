import { Injectable, signal } from '@angular/core';

export interface ConfirmOptions {
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
}

export interface ConfirmState {
  open: boolean;
  title: string;
  message: string;
  confirmText: string;
  cancelText: string;
  resolve?: (value: boolean) => void;
}

@Injectable({ providedIn: 'root' })
export class ConfirmService {
  private readonly _state = signal<ConfirmState>({
    open: false,
    title: 'Confirm',
    message: '',
    confirmText: 'Confirm',
    cancelText: 'Cancel'
  });

  readonly state = this._state.asReadonly();

  show(message: string, options: Partial<Omit<ConfirmOptions, 'message'>> = {}): Promise<boolean> {
    return new Promise(resolve => {
      this._state.set({
        open: true,
        message,
        title: options.title ?? 'Confirm',
        confirmText: options.confirmText ?? 'Confirm',
        cancelText: options.cancelText ?? 'Cancel',
        resolve
      });
    });
  }

  confirm(): void {
    const current = this._state();
    current.resolve?.(true);
    this.close();
  }

  cancel(): void {
    const current = this._state();
    current.resolve?.(false);
    this.close();
  }

  close(): void {
    this._state.set({
      open: false,
      title: 'Confirm',
      message: '',
      confirmText: 'Confirm',
      cancelText: 'Cancel'
    });
  }
}
