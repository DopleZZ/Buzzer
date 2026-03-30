import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="settings-page">
      <h2>Settings</h2>
      <p>App settings will be available here.</p>
    </div>
  `,
  styles: [`
    .settings-page {
      padding: 2rem;
      max-width: 600px;
      margin: 0 auto;
    }

    h2 {
      margin-bottom: 1rem;
    }
  `]
})
export class SettingsComponent {}