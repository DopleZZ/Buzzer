import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, BehaviorSubject, tap, catchError, of } from 'rxjs';
import { User } from '../models/user.model';

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

interface LoginRequest {
  email: string;
  password: string;
}

interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  displayName: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly API_URL = '/api/v1/auth';

  private accessTokenSignal = signal<string | null>(null);
  private refreshTokenSignal = signal<string | null>(null);
  private currentUserSignal = signal<User | null>(null);

  isAuthenticated$ = computed(() => !!this.accessTokenSignal() && !!this.currentUserSignal());
  currentUser$ = this.currentUserSignal.asReadonly();

  constructor(
    private http: HttpClient,
    private router: Router
  ) {
    // Initialize from memory (tokens are NOT stored in localStorage for security)
    this.loadUserFromSession();
  }

  private loadUserFromSession(): void {
    // Check if we have session data (could be from sessionStorage in production)
    // For security, we don't persist tokens - user must re-login
  }

  getAccessToken(): string | null {
    return this.accessTokenSignal();
  }

  login(request: LoginRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.API_URL}/login`, request).pipe(
      tap(response => this.handleAuthSuccess(response))
    );
  }

  register(request: RegisterRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.API_URL}/register`, request).pipe(
      tap(response => this.handleAuthSuccess(response))
    );
  }

  async refreshToken(): Promise<string | null> {
    const currentRefreshToken = this.refreshTokenSignal();
    if (!currentRefreshToken) {
      return null;
    }

    try {
      const response = await this.http.post<AuthResponse>(`${this.API_URL}/refresh`, {
        refreshToken: currentRefreshToken
      }).toPromise();

      if (response) {
        this.handleAuthSuccess(response);
        return response.accessToken;
      }
      return null;
    } catch {
      this.logout();
      return null;
    }
  }

  logout(): void {
    const refreshToken = this.refreshTokenSignal();

    if (refreshToken) {
      this.http.post(`${this.API_URL}/logout`, { refreshToken }).subscribe();
    }

    this.accessTokenSignal.set(null);
    this.refreshTokenSignal.set(null);
    this.currentUserSignal.set(null);

    this.router.navigate(['/auth/login']);
  }

  logoutAll(): void {
    this.http.post(`${this.API_URL}/logout-all`, {}).subscribe();
    this.logout();
  }

  getCurrentUser(): Observable<User> {
    return this.http.get<User>(`${this.API_URL}/me`);
  }

  private handleAuthSuccess(response: AuthResponse): void {
    this.accessTokenSignal.set(response.accessToken);
    this.refreshTokenSignal.set(response.refreshToken);
    this.currentUserSignal.set(response.user);
  }
}