import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="auth-container">
      <div class="auth-card">
        <h1>Buzzer</h1>
        <h2>Create account</h2>

        <form (ngSubmit)="onSubmit()" #registerForm="ngForm">
          <div class="form-group">
            <label for="username">Username</label>
            <input
              type="text"
              id="username"
              name="username"
              [(ngModel)]="credentials.username"
              required
              pattern="^[a-z0-9_]{3,50}$"
              placeholder="Choose a username"
            />
            <small>3-50 characters, lowercase letters, numbers, underscores</small>
          </div>

          <div class="form-group">
            <label for="email">Email</label>
            <input
              type="email"
              id="email"
              name="email"
              [(ngModel)]="credentials.email"
              required
              email
              placeholder="Enter your email"
            />
          </div>

          <div class="form-group">
            <label for="displayName">Display Name</label>
            <input
              type="text"
              id="displayName"
              name="displayName"
              [(ngModel)]="credentials.displayName"
              required
              maxlength="100"
              placeholder="How should we call you?"
            />
          </div>

          <div class="form-group">
            <label for="password">Password</label>
            <input
              type="password"
              id="password"
              name="password"
              [(ngModel)]="credentials.password"
              required
              minlength="8"
              placeholder="Create a password"
            />
            <small>Minimum 8 characters</small>
          </div>

          @if (error) {
            <div class="error-message">{{ error }}</div>
          }

          <button type="submit" [disabled]="loading || registerForm.invalid" class="btn-primary">
            @if (loading) {
              Creating account...
            } @else {
              Sign up
            }
          </button>
        </form>

        <div class="auth-footer">
          <p>Already have an account? <a routerLink="/auth/login">Sign in</a></p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .auth-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 1rem;
    }

    .auth-card {
      background: var(--surface);
      border-radius: 8px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
      padding: 2rem;
      width: 100%;
      max-width: 400px;
    }

    h1 {
      color: var(--primary-color);
      font-size: 2rem;
      margin-bottom: 0.5rem;
      text-align: center;
    }

    h2 {
      color: var(--text-secondary);
      font-size: 1rem;
      text-align: center;
      margin-bottom: 1.5rem;
    }

    .form-group {
      margin-bottom: 1rem;
    }

    label {
      display: block;
      margin-bottom: 0.25rem;
      font-weight: 500;
    }

    input {
      width: 100%;
      padding: 0.75rem;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      font-size: 1rem;
    }

    input:focus {
      outline: none;
      border-color: var(--primary-color);
    }

    small {
      display: block;
      color: var(--text-secondary);
      font-size: 0.75rem;
      margin-top: 0.25rem;
    }

    .btn-primary {
      width: 100%;
      padding: 0.75rem;
      background: var(--primary-color);
      color: white;
      border: none;
      border-radius: 4px;
      font-size: 1rem;
      cursor: pointer;
      margin-top: 1rem;
    }

    .btn-primary:hover:not(:disabled) {
      background: var(--primary-hover);
    }

    .btn-primary:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .error-message {
      color: var(--error-color);
      font-size: 0.875rem;
      margin-top: 0.5rem;
    }

    .auth-footer {
      margin-top: 1.5rem;
      text-align: center;
    }

    .auth-footer a {
      color: var(--primary-color);
      text-decoration: none;
    }

    .auth-footer a:hover {
      text-decoration: underline;
    }
  `]
})
export class RegisterComponent {
  private authService = inject(AuthService);
  private router = inject(Router);

  credentials = { username: '', email: '', password: '', displayName: '' };
  loading = false;
  error: string | null = null;

  async onSubmit(): Promise<void> {
    if (!this.credentials.username || !this.credentials.email ||
        !this.credentials.password || !this.credentials.displayName) return;

    this.loading = true;
    this.error = null;

    try {
      await this.authService.register(this.credentials).toPromise();
      this.router.navigate(['/app/chats']);
    } catch (err: unknown) {
      const error = err as { error?: { field?: string; message?: string } };
      if (error.error?.field) {
        this.error = `${error.error.field}: ${error.error.message || 'Already exists'}`;
      } else {
        this.error = error.error?.message || 'Registration failed';
      }
    } finally {
      this.loading = false;
    }
  }
}