# Database Rules

## Миграции
- Liquibase для версионирования схемы
- Changesets в `src/main/resources/db/changelog/`
- Именование: `YYYYMMDD-HHMM-description.yml`

## Первичные ключи
- UUID v4 для всех таблиц (`gen_random_uuid()`)
- Избегать последовательные ID (безопасность)

## Soft Delete
- `deleted_at TIMESTAMPTZ NULL` вместо hard delete
- При soft delete: `content = NULL`, `type = 'system'`
- Индексы с условием `WHERE deleted_at IS NULL`

## Индексы
- Всегда индекс на FK
- Составной индекс на `(conversation_id, created_at DESC)` для сообщений
- Индекс на `user_id` в conversation_members

## JSONB
- Использовать для `session_state` (E2E) и `payload` (notifications)
- GIN индекс для JSONB полей с поиском

## Naming conventions
- Таблицы: snake_case, множественное число (`users`, `conversations`)
- Колонки: snake_case (`created_at`, `user_id`)
- FK: `{table}_id` (`user_id`, `conversation_id`)