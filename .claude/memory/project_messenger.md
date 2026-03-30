---
name: Buzzer Messenger Project
description: Защищённый мессенджер с E2E-шифрованием на Spring Boot + Angular
type: project
---

Защищённый мессенджер Buzzer с End-to-End шифрованием.

**Стек:** Spring Boot 3.2, Angular 17, PostgreSQL 16, Redis 7, RabbitMQ 3.13, MinIO

**Ключевые особенности:**
- E2E шифрование (X3DH + Double Ratchet + Sender Keys)
- Realtime через WebSocket (STOMP)
- JWT аутентификация (RS256, 15 мин TTL)
- Файловое хранилище с шифрованием

**Why:** Мессенджер для безопасной коммуникации с фокусом на приватность и производительность.

**How to apply:** При разработке модулей следовать спецификации в `messenger_specification.typ` и правилам в `.claude/rules/`. Использовать субагентов для специализированных задач.