import { Injectable, OnDestroy } from '@angular/core';
import { RxStomp, RxStompState } from '@stomp/rx-stomp';
import { Observable, Subject, BehaviorSubject } from 'rxjs';
import { filter, map, takeUntil } from 'rxjs/operators';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class WebSocketService implements OnDestroy {
  private rxStomp: RxStomp | null = null;
  private destroy$ = new Subject<void>();
  private connectionState$ = new BehaviorSubject<RxStompState>(RxStompState.CLOSED);

  constructor(private authService: AuthService) {}

  connect(): void {
    if (this.rxStomp) {
      return;
    }

    const token = this.authService.getAccessToken();
    if (!token) {
      return;
    }

    this.rxStomp = new RxStomp();
    this.rxStomp.configure({
      brokerURL: 'ws://localhost:8080/ws',
      connectHeaders: {
        Authorization: `Bearer ${token}`
      },
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
      reconnectDelay: 3000,
      debug: (str) => console.log('[STOMP]', str)
    });

    this.rxStomp.connectionState.pipe(
      takeUntil(this.destroy$)
    ).subscribe(state => {
      this.connectionState$.next(state);
    });

    this.rxStomp.activate();
  }

  disconnect(): void {
    if (this.rxStomp) {
      this.rxStomp.deactivate();
      this.rxStomp = null;
    }
    this.destroy$.next();
    this.destroy$.complete();
  }

  subscribe<T>(destination: string): Observable<T> {
    if (!this.rxStomp) {
      throw new Error('WebSocket not connected');
    }

    return this.rxStomp.watch(destination).pipe(
      map(message => JSON.parse(message.body) as T)
    );
  }

  send(destination: string, body: unknown): void {
    if (!this.rxStomp) {
      throw new Error('WebSocket not connected');
    }

    this.rxStomp.publish({
      destination,
      body: JSON.stringify(body)
    });
  }

  get connectionState(): Observable<RxStompState> {
    return this.connectionState$.asObservable();
  }

  isConnected(): boolean {
    return this.connectionState$.getValue() === RxStompState.OPEN;
  }

  ngOnDestroy(): void {
    this.disconnect();
  }
}