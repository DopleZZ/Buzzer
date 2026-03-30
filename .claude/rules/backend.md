# Backend Development Rules

## DTO и маппинг
- Использовать `record` для всех DTO
- MapStruct для маппинга между Entity и DTO
- Валидация через `@Validated` и Jakarta Bean Validation

## Стили кода
- Пакеты по домену: `auth/`, `user/`, `conversation/`, `message/`, `group/`, `crypto/`, `media/`, `notification/`
- Именование: `*Controller`, `*Service`, `*Repository`
- Exception handling через `@ControllerAdvice`

## API версиирование
- Все REST endpoints: `/api/v1/*`
- WebSocket STOMP: `/app/*` для приёма, `/topic/*` и `/user/*` для доставки

## Транзакции
- `@Transactional(readOnly = true)` для чтения
- `@Transactional` для записи
- Избегать длинных транзакций

## Тесты
- Unit тесты: JUnit 5 + Mockito
- Integration: Testcontainers (PostgreSQL, Redis, RabbitMQ)
- @DataJpaTest с реальной БД через Testcontainers