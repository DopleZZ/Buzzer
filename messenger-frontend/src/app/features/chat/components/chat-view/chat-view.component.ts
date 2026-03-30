import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-chat-view',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="chat-view">
      <header class="chat-header">
        <div class="chat-info">
          <div class="chat-avatar">JD</div>
          <div class="chat-details">
            <h3>John Doe</h3>
            <span class="status">Online</span>
          </div>
        </div>
      </header>

      <div class="messages-container">
        <div class="empty-chat">
          <p>End-to-end encrypted</p>
          <p class="hint">Messages are secured with E2E encryption</p>
        </div>
      </div>

      <footer class="chat-input">
        <input
          type="text"
          [(ngModel)]="messageText"
          placeholder="Type a message..."
          (keydown.enter)="sendMessage()"
        />
        <button (click)="sendMessage()" [disabled]="!messageText.trim()">Send</button>
      </footer>
    </div>
  `,
  styles: [`
    .chat-view {
      height: 100%;
      display: flex;
      flex-direction: column;
      background: var(--background);
    }

    .chat-header {
      padding: 1rem;
      background: var(--surface);
      border-bottom: 1px solid var(--border-color);
    }

    .chat-info {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    .chat-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--primary-color);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
    }

    .chat-details h3 {
      margin: 0;
      font-size: 1rem;
    }

    .status {
      font-size: 0.75rem;
      color: var(--success-color);
    }

    .messages-container {
      flex: 1;
      overflow-y: auto;
      padding: 1rem;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .empty-chat {
      text-align: center;
      color: var(--text-secondary);
    }

    .empty-chat .hint {
      font-size: 0.875rem;
      margin-top: 0.5rem;
    }

    .chat-input {
      padding: 1rem;
      background: var(--surface);
      border-top: 1px solid var(--border-color);
      display: flex;
      gap: 0.5rem;
    }

    .chat-input input {
      flex: 1;
      padding: 0.75rem;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      font-size: 1rem;
    }

    .chat-input input:focus {
      outline: none;
      border-color: var(--primary-color);
    }

    .chat-input button {
      padding: 0.75rem 1.5rem;
      background: var(--primary-color);
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }

    .chat-input button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `]
})
export class ChatViewComponent {
  messageText = '';

  sendMessage(): void {
    if (!this.messageText.trim()) return;
    // TODO: Implement message sending via WebSocket
    this.messageText = '';
  }
}