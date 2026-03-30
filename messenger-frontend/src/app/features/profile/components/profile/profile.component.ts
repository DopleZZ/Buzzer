import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="profile-page">
      <h2>Profile</h2>
      <p>Profile settings will be available here.</p>
    </div>
  `,
  styles: [`
    .profile-page {
      padding: 2rem;
      max-width: 600px;
      margin: 0 auto;
    }

    h2 {
      margin-bottom: 1rem;
    }
  `]
})
export class ProfileComponent {}