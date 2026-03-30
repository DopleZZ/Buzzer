import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.routes').then(m => m.authRoutes)
  },
  {
    path: 'app',
    canActivate: [authGuard],
    loadChildren: () => import('./features/shell/shell.routes').then(m => m.shellRoutes)
  },
  {
    path: '',
    redirectTo: '/app/chats',
    pathMatch: 'full'
  },
  {
    path: '**',
    redirectTo: '/app/chats'
  }
];