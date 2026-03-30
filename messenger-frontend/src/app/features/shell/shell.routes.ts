import { Routes } from '@angular/router';
import { ShellComponent } from './components/shell/shell.component';

export const shellRoutes: Routes = [
  {
    path: '',
    component: ShellComponent,
    children: [
      {
        path: 'chats',
        loadComponent: () => import('../chat/components/chat-list/chat-list.component')
          .then(m => m.ChatListComponent)
      },
      {
        path: 'chats/:id',
        loadComponent: () => import('../chat/components/chat-view/chat-view.component')
          .then(m => m.ChatViewComponent)
      },
      {
        path: 'profile',
        loadComponent: () => import('../profile/components/profile/profile.component')
          .then(m => m.ProfileComponent)
      },
      {
        path: 'settings',
        loadComponent: () => import('../settings/components/settings/settings.component')
          .then(m => m.SettingsComponent)
      },
      {
        path: '',
        redirectTo: 'chats',
        pathMatch: 'full'
      }
    ]
  }
];