import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { WebSocketService } from '../../../core/services/websocket.service';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink],
  template: `
    <div class="app-shell">
      <aside class="sidebar">
        <div class="sidebar-header">
          <h1>Buzzer</h1>
        </div>

        <nav class="sidebar-nav">
          <a routerLink="/app/chats" routerLinkActive="active">
            <span class="icon">💬</span>
            <span>Chats</span>
          </a>
          <a routerLink="/app/profile" routerLinkActive="active">
            <span class="icon">👤</span>
            <span>Profile</span>
          </a>
          <a routerLink="/app/settings" routerLinkActive="active">
            <span class="icon">⚙️</span>
            <span>Settings</span>
          </a>
        </nav>

        <div class="sidebar-footer">
          <div class="user-info" *ngIf="user()">
            <span class="avatar">{{ user()?.displayName?.charAt(0) || '?' }}</span>
            <span class="name">{{ user()?.displayName }}</span>
          </div>
          <button class="btn-logout" (click)="logout()">Sign out</button>
        </div>
      </aside>

      <main class="main-content">
        <router-outlet></router-outlet>
      </main>
    </div>
  `,
  styles: [`
    .app-shell {
      display: flex;
      height: 100vh;
      overflow: hidden;
    }

    .sidebar {
      width: 240px;
      background: var(--surface);
      border-right: 1px solid var(--border-color);
      display: flex;
      flex-direction: column;
    }

    .sidebar-header {
      padding: 1rem;
      border-bottom: 1px solid var(--border-color);
    }

    .sidebar-header h1 {
      color: var(--primary-color);
      font-size: 1.5rem;
      margin: 0;
    }

    .sidebar-nav {
      flex: 1;
      padding: 1rem 0;
    }

    .sidebar-nav a {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      color: var(--text-primary);
      text-decoration: none;
      transition: background-color 0.2s;
    }

    .sidebar-nav a:hover {
      background: var(--background);
    }

    .sidebar-nav a.active {
      background: var(--primary-color);
      color: white;
    }

    .sidebar-footer {
      padding: 1rem;
      border-top: 1px solid var(--border-color);
    }

    .user-info {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }

    .avatar {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: var(--primary-color);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
    }

    .name {
      font-weight: 500;
    }

    .btn-logout {
      width: 100%;
      padding: 0.5rem;
      background: transparent;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      cursor: pointer;
      color: var(--text-secondary);
    }

    .btn-logout:hover {
      background: var(--error-color);
      color: white;
      border-color: var(--error-color);
    }

    .main-content {
      flex: 1;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
  `]
})
export class ShellComponent implements OnInit {
  private authService = inject(AuthService);
  private webSocketService = inject(WebSocketService);
  private router = inject(Router);

  user = this.authService.currentUser$;

  ngOnInit(): void {
    this.webSocketService.connect();
  }

  logout(): void {
    this.webSocketService.disconnect();
    this.authService.logout();
  }
}