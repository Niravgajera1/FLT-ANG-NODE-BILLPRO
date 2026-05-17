import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../auth.service';
import { ToastService } from '../toast.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './login.component.html'
})
export class LoginComponent implements OnInit {
  private fb = inject(FormBuilder);
  private auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);

  showPassword = signal(false);
  isLoading = signal(false);

  form: FormGroup = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    rememberMe: [false]
  });

  ngOnInit(): void {
    const remembered = this.auth.getRememberedEmail();
    if (remembered) {
      this.form.patchValue({ email: remembered, rememberMe: true });
    }
  }

  get emailCtrl()    { return this.form.get('email')!; }
  get passwordCtrl() { return this.form.get('password')!; }

  get emailError(): string {
    const ctrl = this.emailCtrl;
    if (!ctrl.touched || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Email is required.';
    if (ctrl.errors['email'])    return 'Please enter a valid email address.';
    return '';
  }

  get passwordError(): string {
    const ctrl = this.passwordCtrl;
    if (!ctrl.touched || !ctrl.errors) return '';
    if (ctrl.errors['required'])   return 'Password is required.';
    if (ctrl.errors['minlength'])  return 'Password must be at least 6 characters.';
    return '';
  }

  togglePassword(): void {
    this.showPassword.update(v => !v);
  }

  onSubmit(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    this.isLoading.set(true);

    // Simulate async login
    setTimeout(() => {
      const { email, password, rememberMe } = this.form.value;
      const success = this.auth.login(email, password, rememberMe);

      if (success) {
        this.toast.success('Welcome back! Redirecting to dashboard…');
        setTimeout(() => this.router.navigate(['/dashboard']), 800);
      } else {
        this.toast.error('Invalid email or password. Please try again.');
        this.isLoading.set(false);
        this.passwordCtrl.reset();
      }
    }, 900);
  }
}
