# Frontend Development Rules

## Angular 17
- Standalone components (без NgModules)
- OnPush Change Detection на всех компонентах
- Angular Signals для реактивного state
- Lazy loading для всех feature routes

## Состояния
- Services в `core/` — singleton state
- Signals для локального состояния
- RxJS для WebSocket streams

## Безопасность
- JWT хранится **только в memory** (переменная AuthService)
- Refresh Token в HttpOnly cookie (автоматически)
- НИКОГДА localStorage / sessionStorage для токенов

## WebSocket
- @stomp/rx-stomp с автореконнектом
- Pending message queue при разрыве
- SockJS fallback для proxy

## Криптография
- libsignal-protocol-typescript для E2E
- IndexedDB для приватных ключей (зашифрованные AES-GCM)
- Web Crypto API для шифрования файлов

## Виртуализация
- @angular/cdk/scrolling для списка сообщений
- Не рендерить невидимые элементы

## HTTP Interceptors
- JwtInterceptor: добавляет Authorization header
- RefreshInterceptor: автоматическое обновление при 401
- ErrorInterceptor: обработка ошибок

## Стиль кода
- Компоненты: `*.component.ts`, `*.component.html`, `*.component.scss`
- Services: `*.service.ts`
- DTO интерфейсы в `models/`