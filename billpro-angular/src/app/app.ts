import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';
import { AuthService } from './auth/auth.service';
import { Sidebar } from './sidebar/sidebar';
import { ToastContainerComponent } from './toast/toast-container.component';
import { ConfirmDialogComponent } from './ui/confirm-dialog.component';
import { HeaderComponent } from './header/header.component';

@Component({
  selector: 'app-root',
  imports: [CommonModule, RouterOutlet, Sidebar, ToastContainerComponent, ConfirmDialogComponent, HeaderComponent],
  templateUrl: './app.html',
  styleUrls: ['./app.scss']
})
export class App {
  auth = inject(AuthService);
}
