import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-chat-list',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="chat-list-container">
      <header class="chat-list-header">
        <h2>Messages</h2>
        <button class="btn-new-chat">New Chat</button>
      </header>

      <div class="search-box">
        <input type="text" placeholder="Search conversations..." />
      </div>

      <div class="chat-list">
        <div class="chat-item">
          <div class="chat-avatar">JD</div>
          <div class="chat-info">
            <div class="chat-name">John Doe</div>
            <div class="chat-preview">Start your first conversation...</div>
          </div>
          <div class="chat-meta">
            <span class="chat-time">now</span>
          </div>
        </div>

        <div class="empty-state">
          <p>No conversations yet</p>
          <p class="hint">Start a new chat to begin messaging</p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .chat-list-container {
      height: 100%;
      display: flex;
      flex-direction: column;
      background: var(--background);
    }

    .chat-list-header {
      padding: 1rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--border-color);
      background: var(--surface);
    }

    .chat-list-header h2 {
      margin: 0;
      font-size: 1.25rem;
    }

    .btn-new-chat {
      padding: 0.5rem 1rem;
      background: var(--primary-color);
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }

    .search-box {
      padding: 0.75rem;
      background: var(--surface);
    }

    .search-box input {
      width: 100%;
      padding: 0.5rem;
      border: 1px solid var(--border-color);
      border-radius: 4px;
      font-size: 0.875rem;
    }

    .chat-list {
      flex: 1;
      overflow-y: auto;
    }

    .chat-item {
      display: flex;
      align-items: center;
      padding: 0.75rem 1rem;
      border-bottom: 1px solid var(--border-color);
      cursor: pointer;
      background: var(--surface);
    }

    .chat-item:hover {
      background: var(--background);
    }

    .chat-avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: var(--primary-color);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      margin-right: 0.75rem;
    }

    .chat-info {
      flex: 1;
      min-width: 0;
    }

    .chat-name {
      font-weight: 600;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .chat-preview {
      color: var(--text-secondary);
      font-size: 0.875rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .chat-meta {
      text-align: right;
    }

    .chat-time {
      font-size: 0.75rem;
      color: var(--text-secondary);
    }

    .empty-state {
      padding: 2rem;
      text-align: center;
      color: var(--text-secondary);
    }

    .empty-state .hint {
      font-size: 0.875rem;
      margin-top: 0.5rem;
    }
  `]
})
export class ChatListComponent {}