# Security Rules

## JWT
- Алгоритм: RS256 (RSA Private/Public key)
- Access Token TTL: 15 минут
- Payload: `{sub: userId, username, roles}`
- Хранение на клиенте: **только в memory**, НИКОГДА в localStorage/sessionStorage

## Refresh Token
- TTL: 30 дней
- Хранение: HttpOnly cookie (SameSite=Strict)
- SHA-256 хэш в БД
- Refresh Token Rotation: при каждом обновлении старый инвалидируется

## Пароли
- BCrypt с cost=12
- Валидация: минимум 8 символов, буквы + цифры

## Spring Security
- `sessionManagement(STATELESS)`
- `JwtAuthFilter` перед `UsernamePasswordAuthenticationFilter`
- CORS настроен для Angular dev server

## Rate Limiting
- `/auth/login`: 5 попыток / 15 минут / IP (Resilience4j)

## Логирование
- НИКОГДА не логировать токены, пароли, ключи
- Маскировать sensitive данные в логах

## E2E Encryption
- X3DH для handshake
- Double Ratchet для сессий 1-на-1
- Sender Keys для групп
- Приватные ключи: IndexedDB + AES-GCM + PBKDF2 на клиенте