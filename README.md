# Buzzer

Защищённый мессенджер с E2E-шифрованием.

## Стек технологий

| Слой | Технологии |
|------|------------|
| Backend | Spring Boot 3.2, Spring Security 6, JWT, Spring AMQP, Spring Data Redis |
| Frontend | Angular 17 (standalone, OnPush, Signals), STOMP/WebSocket |
| Database | PostgreSQL 16, Liquibase |
| Cache | Redis 7 |
| Messaging | RabbitMQ 3.13 |
| Storage | MinIO (S3-compatible) |
| Monitoring | Prometheus, Grafana |

## Возможности

- End-to-End шифрование (X3DH + Double Ratchet + Sender Keys)
- Личные и групповые чаты
- Обмен файлами до 100 МБ с шифрованием
- Индикаторы набора текста и онлайн-статуса
- Realtime доставка через WebSocket (STOMP)
- Гарантированная доставка через RabbitMQ

## Разработка

### Требования

- Java 21+
- Node.js 20+
- Docker и Docker Compose

### Запуск инфраструктуры

```bash
docker compose up -d
```

Доступные сервисы:
- PostgreSQL: `localhost:5432` (user: buzzer, db: buzzer)
- Redis: `localhost:6379`
- RabbitMQ: `localhost:5672` (management: `localhost:15672`)
- MinIO: `localhost:9000` (console: `localhost:9001`)
- Prometheus: `localhost:9090`
- Grafana: `localhost:3000`

### Запуск backend

```bash
cd messenger-backend
./mvnw spring-boot:run
```

### Запуск frontend

```bash
cd messenger-frontend
npm install
ng serve
```

## Документация

- Спецификация: `messenger_specification.typ`
- Правила разработки: `.claude/rules/`

## Лицензия

MIT