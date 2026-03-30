#set text(lang: "ru")

#show: document(
  title: [ТЕХНИЧЕСКАЯ СПЕЦИФИКАЦИЯ],
  subtitle: [Защищённый мессенджер],
  author: [Spec-First Methodology · AI-Driven Development],
)

== Введение

Стек: Spring Boot 3 · Angular 17 · PostgreSQL 16 · Redis 7 · RabbitMQ 3.13 · MinIO · WebSocket

End-to-End Encryption (X3DH + Double Ratchet) · JWT + Spring Security


= 01 — Философия и цели проекта

Мессенджер — высоконагруженное realtime-приложение, где каждая миллисекунда задержки ощутима. Цель архитектуры: минимальная latency при высокой надёжности и конфиденциальности. Проект реализуется по методологии *Spec-First*: каждый модуль описан до написания первой строки кода.

== 1.1 Ключевые цели

- Latency: доставка сообщения < 50 мс при нагрузке до 10 000 одновременных соединений
- Безопасность: E2E-шифрование (X3DH + Double Ratchet), JWT-аутентификация, Spring Security
- Масштабируемость: горизонтальное масштабирование через RabbitMQ + Redis Pub/Sub
- Надёжность: гарантированная доставка (RabbitMQ), персистентность (PostgreSQL), кэш (Redis)
- Хранение файлов: MinIO S3-совместимый объектный стор, стриминг без буферизации
- Фронтенд: Angular 17 с OnPush-стратегией, lazy-loading, WebSocket через STOMP

== 1.2 Нефункциональные требования

#table(
  columns: (auto, auto, auto),
  [Параметр], [Требование], [Инструмент],
  [Latency p99], [< 100 мс (сообщение)], [RabbitMQ + Redis],
  [Throughput], [> 5 000 msg/s], [RabbitMQ cluster],
  [Availability], [99.9% uptime], [Health checks + retry],
  [Шифрование], [E2E (X3DH + Double Ratchet)], [libsignal-protocol],
  [Аутентификация], [JWT + Refresh Token Rotation], [Spring Security],
  [Хранилище файлов], [S3-совместимый MinIO], [MinIO Java SDK],
  [Кэш], [Redis 7 Cluster], [Spring Data Redis],
  [Очередь], [RabbitMQ 3.13 + AMQP], [Spring AMQP],
)


= 02 — Архитектура системы

== 2.1 Обзор слоёв

Система разделена на 5 уровней. Каждый уровень изолирован и может масштабироваться независимо.

#table(
  columns: (auto, auto, auto),
  [Слой], [Технологии], [Назначение],
  [Presentation], [Angular 17, STOMP/WebSocket, REST], [SPA-фронтенд, realtime UI],
  [API Gateway], [Spring Boot 3, Spring Security, JWT], [Аутентификация, маршрутизация, rate limiting],
  [Business Logic], [Spring Boot Services, Spring AMQP], [Чаты, сообщения, группы, E2E-шифрование],
  [Messaging], [RabbitMQ 3.13 (AMQP 0-9-1)], [Асинхронная маршрутизация сообщений],
  [Data], [PostgreSQL 16, Redis 7, MinIO], [Персистентность, кэш, объектное хранилище],
)

== 2.2 Технологический стек

#table(
  columns: (auto, auto, auto, auto),
  [Компонент], [Технология], [Версия], [Обоснование],
  [Backend Framework], [Spring Boot], [3.2.x], [Production-ready, autoconfiguration, WebSocket support],
  [Security], [Spring Security + JWT], [6.x], [RBAC, JWT filter chain, OAuth2 ready],
  [Messaging Broker], [RabbitMQ], [3.13], [AMQP, topic exchange, dead letter queues],
  [Cache / Pub-Sub], [Redis], [7.x], [Session store, online-статус, Pub/Sub для WebSocket],
  [База данных], [PostgreSQL], [16], [JSONB, full-text search, RLS],
  [Object Storage], [MinIO], [RELEASE.2024], [S3-совместимый, self-hosted, стриминг],
  [Frontend], [Angular], [17], [OnPush CD, standalone components, signals],
  [WebSocket], [STOMP over SockJS], [-], [Поверх Spring WebSocket, fallback для прокси],
  [ORM], [Spring Data JPA + Hibernate], [6.x], [Migrations через Liquibase],
  [Migrations], [Liquibase], [4.x], [Версионирование схемы БД],
  [Контейнеризация], [Docker + Docker Compose], [-], [Изолированное окружение, prod-ready],
  [Мониторинг], [Micrometer + Prometheus + Grafana], [-], [Метрики latency, throughput, errors],
  [API Docs], [SpringDoc OpenAPI 3], [-], [Автогенерация Swagger UI],
)

== 2.3 Поток сообщения (message flow)

- Пользователь A печатает сообщение → Angular отправляет STOMP `SEND` на `/app/chat.send`
- Spring WebSocket Controller принимает, валидирует JWT из STOMP headers
- `MessageService` применяет E2E-шифрование (если включено) и сохраняет в PostgreSQL
- `MessageService` публикует событие в RabbitMQ exchange: `chat.direct` или `chat.group`
- RabbitMQ маршрутизирует в очередь получателя(ей) через routing key = `userId`
- `MessageConsumer` читает из очереди, публикует в Redis Pub/Sub канал
- Spring WebSocket Broker доставляет через `/topic/user.{userId}` подписчику
- Пользователь B получает сообщение в Angular через STOMP `SUBSCRIBE`

== 2.4 Дополнительные технологии

#table(
  columns: (auto, auto, auto),
  [Технология], [Назначение], [Интеграция],
  [Liquibase], [Управление миграциями БД], [Spring Boot autoconfiguration],
  [SpringDoc OpenAPI], [Swagger UI, API документация], [Аннотации @Operation],
  [Micrometer], [Метрики приложения], [Prometheus endpoint /actuator/prometheus],
  [Prometheus + Grafana], [Дашборды, алерты], [-],
  [Docker Compose stack], [Локальная инфраструктура], [-],
  [Testcontainers], [Интеграционные тесты с реальными сервисами], [JUnit 5 + @Testcontainers],
  [MapStruct], [DTO маппинг без рефлексии], [Compile-time code generation],
  [Resilience4j], [Circuit breaker, retry, rate limiter], [Spring Boot Starter],
)


= 03 — Модуль: Аутентификация

== 3.1 User Stories

- Как новый пользователь, я хочу зарегистрироваться через email + пароль, чтобы получить аккаунт
- Как зарегистрированный пользователь, я хочу войти и получить JWT + Refresh Token
- Как авторизованный пользователь, я хочу автоматически обновлять JWT без повторного входа
- Как пользователь, я хочу выйти и инвалидировать все активные сессии
- Как администратор, я хочу блокировать пользователей

== 3.2 Модель данных

*Таблица: users*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK DEFAULT gen_random_uuid()], [Уникальный идентификатор],
  [username], [varchar(50)], [UNIQUE NOT NULL], [Логин (3–50 символов, a-z0-9_)],
  [email], [varchar(255)], [UNIQUE NOT NULL], [Email адрес],
  [password_hash], [varchar(255)], [NOT NULL], [BCrypt hash (cost=12)],
  [display_name], [varchar(100)], [NOT NULL], [Отображаемое имя],
  [avatar_url], [text], [NULL], [URL аватара в MinIO],
  [status], [varchar(20)], [DEFAULT 'active'], [active | blocked | deleted],
  [last_seen_at], [timestamptz], [NULL], [Последнее присутствие в сети],
  [created_at], [timestamptz], [DEFAULT now()], [Дата регистрации],
  [updated_at], [timestamptz], [DEFAULT now()], [Дата обновления],
)

*Таблица: refresh_tokens*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK], [ID токена],
  [user_id], [uuid], [FK users.id ON DELETE CASCADE], [Владелец],
  [token_hash], [varchar(255)], [UNIQUE NOT NULL], [SHA-256 хэш токена],
  [device_info], [text], [NULL], [User-Agent/device fingerprint],
  [expires_at], [timestamptz], [NOT NULL], [Срок действия (30 дней)],
  [revoked_at], [timestamptz], [NULL], [NULL = активен],
  [created_at], [timestamptz], [DEFAULT now()], [Дата выдачи],
)

== 3.3 API Endpoints

#table(
  columns: (auto, auto, auto, auto, auto),
  [Метод], [Путь], [Тело запроса], [Ответ], [Коды],
  [POST], [/api/v1/auth/register], [{username, email, password, displayName}], [UserDto], [201, 400, 409],
  [POST], [/api/v1/auth/login], [{email, password}], [{accessToken, refreshToken, user}], [200, 401],
  [POST], [/api/v1/auth/refresh], [{refreshToken}], [{accessToken, refreshToken}], [200, 401],
  [POST], [/api/v1/auth/logout], [{refreshToken}], [—], [204, 401],
  [POST], [/api/v1/auth/logout-all], [—], [—], [204, 401],
  [GET], [/api/v1/auth/me], [—], [UserDto], [200, 401],
)

== 3.4 Бизнес-логика

- JWT Access Token: RS256, TTL = 15 минут, payload: `{sub: userId, username, roles}`
- Refresh Token: случайный 256-bit UUID, хранится как SHA-256 хэш в БД
- Refresh Token Rotation: при обновлении старый токен инвалидируется, выдаётся новый
- BCrypt `cost = 12` для хэширования паролей
- Rate limiting: `/auth/login` — 5 попыток / 15 минут / IP (Resilience4j RateLimiter)
- Онлайн-статус: при WebSocket connect/disconnect обновляется `last_seen_at` в Redis с `TTL = 30s`

== 3.5 Spring Security Config

- `sessionManagement(STATELESS)`
- `JwtAuthFilter` добавляется перед `UsernamePasswordAuthenticationFilter`
- Правила доступа:
  - `/api/v1/auth/**` → `permitAll`
  - `/ws/**` → `permitAll` (JWT проверяется в STOMP `CONNECT`)
  - `/**` → `authenticated`

== 3.6 Крайние случаи

- Повторная регистрация с существующим `email` → `409 Conflict` + `{field: 'email', message: '...'}`
- Истёкший access token + валидный refresh → автоматическое обновление в interceptor
- Истёкший refresh token → `401`, Angular редиректит на `/login`
- Обнаружение reuse-атаки (refresh token использован повторно) → инвалидировать все токены пользователя
- Заблокированный пользователь → `403` при любом запросе


= 04 — Модуль: End-to-End шифрование

Реализация E2E-шифрования на основе Signal Protocol (X3DH для обмена ключами + Double Ratchet для шифрования сессии). Сервер хранит только зашифрованные сообщения и публичные ключи.

== 4.1 User Stories

- Как пользователь, я хочу, чтобы только я и мой собеседник могли читать сообщения
- Как пользователь, я хочу, чтобы при компрометации одного ключа прошлые сообщения оставались защищены (Forward Secrecy)
- Как пользователь, я хочу прозрачное шифрование — без ручного управления ключами

== 4.2 Модель данных

*Таблица: user_key_bundles*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK], [ID связки ключей],
  [user_id], [uuid], [FK users.id UNIQUE], [Один bundle на пользователя],
  [identity_key_pub], [text], [NOT NULL], [Долгосрочный публичный ключ идентификации (Ed25519)],
  [signed_prekey_pub], [text], [NOT NULL], [Подписанный prekey (X25519)],
  [signed_prekey_sig], [text], [NOT NULL], [Подпись signed_prekey identity_key],
  [prekey_id], [integer], [NOT NULL], [ID текущего signed prekey],
  [created_at], [timestamptz], [DEFAULT now()], [Дата создания],
)

*Таблица: one_time_prekeys*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK], [ID one-time prekey],
  [user_id], [uuid], [FK users.id], [Владелец],
  [prekey_id], [integer], [NOT NULL], [Порядковый номер],
  [public_key], [text], [NOT NULL], [Публичный X25519 ключ (base64)],
  [used], [boolean], [DEFAULT false], [Использован ли ключ],
  [created_at], [timestamptz], [DEFAULT now()], [Дата создания],
)

*Таблица: e2e_sessions*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK], [ID сессии],
  [initiator_id], [uuid], [FK users.id], [Инициатор X3DH],
  [recipient_id], [uuid], [FK users.id], [Получатель X3DH],
  [session_state], [jsonb], [NOT NULL], [Double Ratchet state (encrypted, client-side only)],
  [created_at], [timestamptz], [DEFAULT now()], [Дата создания],
)

== 4.3 X3DH Handshake (начало сессии)

- Alice запрашивает key bundle Bob'а: `GET /api/v1/keys/{userId}/bundle`
- Сервер возвращает `{identityKey, signedPrekey, signature, oneTimePrekey}` и удаляет one-time prekey из БД
- Alice вычисляет shared secret:
  $DH(Alice_{identity}, Bob_{signed})
    ⊕ DH(Alice_{ephemeral}, Bob_{identity})
    ⊕ DH(Alice_{ephemeral}, Bob_{signed})
    [⊕ DH(Alice_{ephemeral}, Bob_{oneTime})]$
- Alice инициализирует Double Ratchet-сессию с полученным секретом
- Первое сообщение содержит X3DH header (ephemeral key Alice) + зашифрованное сообщение
- Bob при получении первого сообщения вычисляет тот же shared secret и инициализирует сессию

== 4.4 API Endpoints — ключи

#table(
  columns: (auto, auto, auto, auto),
  [Метод], [Путь], [Тело / Ответ], [Описание],
  [POST], [/api/v1/keys/bundle], [{identityKey, signedPrekey, signature, oneTimePrekeys[]}], [Загрузить key bundle],
  [GET], [/api/v1/keys/{userId}/bundle], [—], [Получить bundle пользователя (consumable one-time prekey)],
  [POST], [/api/v1/keys/prekeys], [{prekeys[]}], [Пополнить one-time prekeys (< 20 осталось)],
  [GET], [/api/v1/keys/prekeys/count], [—], [{count: N} — сколько prekeys осталось],
)

== 4.5 Шифрование медиафайлов

- Перед загрузкой в MinIO: клиент шифрует файл AES-256-GCM с симметричным ключом сессии
- Ключ файла передаётся в теле зашифрованного сообщения (внутри Double Ratchet envelope)
- MinIO хранит только зашифрованные blob'ы
- Метаданные файла (размер, MIME) также зашифрованы


= 05 — Модуль: Личные чаты (1-на-1)

== 5.1 User Stories

- Как пользователь, я хочу начать диалог с любым пользователем по username
- Как пользователь, я хочу видеть список всех своих диалогов, отсортированных по последнему сообщению
- Как пользователь, я хочу отправлять текстовые сообщения, получать их в реальном времени
- Как пользователь, я хочу видеть статус доставки (отправлено / доставлено / прочитано)
- Как пользователь, я хочу видеть, когда собеседник печатает
- Как пользователь, я хочу редактировать и удалять свои сообщения
- Как пользователь, я хочу отправлять файлы и изображения (до 100 МБ)
- Как пользователь, я хочу видеть, онлайн ли собеседник

== 5.2 Модель данных

*Таблица: conversations*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK DEFAULT gen_random_uuid()], [ID диалога],
  [type], [varchar(10)], [DEFAULT 'direct'], [direct | group],
  [created_by], [uuid], [FK users.id], [Создатель],
  [created_at], [timestamptz], [DEFAULT now()], [Дата создания],
  [last_message_at], [timestamptz], [NULL], [Для сортировки списка диалогов],
)

*Таблица: conversation_members*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [conversation_id], [uuid], [PK, FK conversations.id], [ID диалога],
  [user_id], [uuid], [PK, FK users.id], [Участник],
  [role], [varchar(20)], [DEFAULT 'member'], [member | admin | owner],
  [joined_at], [timestamptz], [DEFAULT now()], [Дата вступления],
  [last_read_message_id], [uuid], [NULL FK messages.id], [Последнее прочитанное сообщение],
  [muted_until], [timestamptz], [NULL], [Уведомления отключены до],
)

*Таблица: messages*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK DEFAULT gen_random_uuid()], [ID сообщения],
  [conversation_id], [uuid], [FK conversations.id NOT NULL], [Диалог],
  [sender_id], [uuid], [FK users.id NOT NULL], [Отправитель],
  [type], [varchar(20)], [DEFAULT 'text'], [text | image | file | audio | video | system],
  [content], [text], [NULL], [Зашифрованное содержимое (base64)],
  [iv], [varchar(50)], [NULL], [Initialization vector для AES-GCM],
  [reply_to_id], [uuid], [NULL FK messages.id], [Цитируемое сообщение],
  [is_edited], [boolean], [DEFAULT false], [Флаг редактирования],
  [deleted_at], [timestamptz], [NULL], [Soft delete],
  [created_at], [timestamptz], [DEFAULT now() INDEX], [Дата отправки],
  [updated_at], [timestamptz], [DEFAULT now()], [Дата изменения],
)

*Таблица: message_attachments*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK], [ID вложения],
  [message_id], [uuid], [FK messages.id CASCADE], [Сообщение],
  [minio_object_key], [text], [NOT NULL], [Ключ объекта в MinIO],
  [encrypted_file_key], [text], [NOT NULL], [Зашифрованный AES-ключ файла],
  [file_name_encrypted], [text], [NOT NULL], [Зашифрованное имя файла],
  [mime_type], [varchar(100)], [NOT NULL], [Зашифрованный MIME-тип],
  [size_bytes], [bigint], [NOT NULL], [Размер файла в байтах],
  [thumbnail_key], [text], [NULL], [MinIO ключ превью (для изображений)],
)

*Таблица: message_reactions*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [message_id], [uuid], [PK FK messages.id], [Сообщение],
  [user_id], [uuid], [PK FK users.id], [Пользователь],
  [emoji], [varchar(10)], [NOT NULL], [Unicode emoji],
  [created_at], [timestamptz], [DEFAULT now()], [Дата реакции],
)

== 5.3 Индексы

```sql
CREATE INDEX idx_messages_conv_created
  ON messages(conversation_id, created_at DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_conv_members_user
  ON conversation_members(user_id);

CREATE INDEX idx_messages_sender
  ON messages(sender_id);
```

== 5.4 WebSocket STOMP Endpoints

#table(
  columns: (auto, auto, auto, auto),
  [Тип], [Destination], [Payload], [Описание],
  [SEND], [/app/chat.send], [SendMessageDto], [Отправить сообщение],
  [SEND], [/app/chat.typing], [{conversationId, isTyping}], [Индикатор набора],
  [SEND], [/app/chat.read], [{conversationId, messageId}], [Подтвердить прочтение],
  [SEND], [/app/chat.edit], [{messageId, encryptedContent, iv}], [Редактировать сообщение],
  [SEND], [/app/chat.delete], [{messageId}], [Удалить сообщение],
  [SUBSCRIBE], [/topic/conversation.{id}], [MessageDto], [Получать сообщения диалога],
  [SUBSCRIBE], [/topic/user.{id}.status], [UserStatusDto], [Online-статус пользователей],
  [SUBSCRIBE], [/user/queue/notifications], [NotificationDto], [Личные уведомления],
)

== 5.5 REST API Endpoints

#table(
  columns: (auto, auto, auto, auto),
  [Метод], [Путь], [Описание], [Ответ],
  [GET], [/api/v1/conversations], [Список диалогов (пагинация cursor-based)], [Page<ConversationDto>],
  [POST], [/api/v1/conversations/direct], [Создать / открыть диалог с userId], [ConversationDto],
  [GET], [/api/v1/conversations/{id}/messages], [История сообщений (cursor, limit=50)], [Page<MessageDto>],
  [POST], [/api/v1/conversations/{id}/attachments], [Загрузить вложение (multipart)], [AttachmentDto],
  [GET], [/api/v1/conversations/{id}/attachments/{aid}], [Скачать вложение (presigned URL)], [PresignedUrl],
  [DELETE], [/api/v1/messages/{id}], [Удалить своё сообщение], [204],
  [PATCH], [/api/v1/messages/{id}], [Редактировать сообщение], [MessageDto],
  [POST], [/api/v1/messages/{id}/reactions], [Добавить реакцию], [ReactionDto],
  [DELETE], [/api/v1/messages/{id}/reactions/{emoji}], [Убрать реакцию], [204],
)

== 5.6 RabbitMQ конфигурация

#table(
  columns: (auto, auto, auto, auto),
  [Элемент], [Имя], [Тип / Параметры], [Описание],
  [Exchange], [chat.direct], [topic, durable=true], [Маршрутизация 1-на-1 сообщений],
  [Exchange], [chat.group], [topic, durable=true], [Маршрутизация групповых сообщений],
  [Exchange], [chat.dlx], [direct, durable=true], [Dead-letter exchange],
  [Queue], [user.{id}.messages], [durable, x-dead-letter-exchange=chat.dlx], [Очередь пользователя],
  [Routing Key], [user.{userId}], [—], [Привязка очереди к exchange],
  [Queue], [notifications], [durable=true], [Push-уведомления],
)

== 5.7 Redis схема

#table(
  columns: (auto, auto, auto, auto),
  [Ключ], [Тип], [TTL], [Значение],
  [user:{id}:online], [STRING], [30s], [1 если онлайн (обновляется heartbeat)],
  [user:{id}:typing:{convId}], [STRING], [5s], [1 если пишет (auto-expire)],
  [conv:{id}:unread:{userId}], [STRING], [—], [Счётчик непрочитанных],
  [session:{token}], [STRING], [15m], [Кэш JWT claims (избегает DB lookup)],
  [conv:{id}:last_msg], [HASH], [—], [Кэш последнего сообщения для списка],
)

== 5.8 Крайние случаи

- Собеседник офлайн: сообщение сохранено в БД и в очереди RabbitMQ. Доставка при reconnect
- Потеря WebSocket: SockJS fallback (long-polling). Pending messages переотправляются
- Редактирование: только owner, окно = 24 часа после отправки
- Удаление: soft delete, `content → null`, `type → system`. История у обоих очищается
- Файл > 100 МБ: `413` с подсказкой о лимите
- Одновременная отправка: `idempotencyKey` в `SendMessageDto`, дублирование отклоняется


= 06 — Модуль: Групповые чаты

== 6.1 User Stories

- Как пользователь, я хочу создать групповой чат с именем и аватаром
- Как администратор группы, я хочу добавлять и удалять участников
- Как администратор группы, я хочу назначать других администраторов
- Как участник, я хочу покинуть группу
- Как создатель (owner), я хочу удалить группу
- Как пользователь, я хочу видеть список участников и их роли
- Как участник, я хочу видеть, сколько участников прочитало сообщение

== 6.2 Модель данных

*Таблица: group_settings (расширяет conversations)*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [conversation_id], [uuid], [PK FK conversations.id], [Ссылка на базовый диалог],
  [name], [varchar(100)], [NOT NULL], [Название группы],
  [description], [text], [NULL], [Описание],
  [avatar_url], [text], [NULL], [URL аватара в MinIO],
  [invite_link], [varchar(100)], [UNIQUE NULL], [Публичная ссылка-приглашение],
  [max_members], [integer], [DEFAULT 500], [Максимум участников],
  [is_public], [boolean], [DEFAULT false], [Открытая группа (поиск)],
)

*Таблица: message_read_receipts (для групп)*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [message_id], [uuid], [PK FK messages.id], [Сообщение],
  [user_id], [uuid], [PK FK users.id], [Читатель],
  [read_at], [timestamptz], [DEFAULT now()], [Время прочтения],
)

== 6.3 API Endpoints

#table(
  columns: (auto, auto, auto, auto),
  [Метод], [Путь], [Тело], [Описание],
  [POST], [/api/v1/conversations/group], [{name, memberIds[], description?}], [Создать группу],
  [PATCH], [/api/v1/conversations/{id}/group], [{name?, description?, avatar?}], [Обновить настройки],
  [GET], [/api/v1/conversations/{id}/members], [—], [Список участников с ролями],
  [POST], [/api/v1/conversations/{id}/members], [{userIds[]}], [Добавить участников (admin)],
  [DELETE], [/api/v1/conversations/{id}/members/{userId}], [—], [Исключить участника (admin)],
  [PATCH], [/api/v1/conversations/{id}/members/{userId}/role], [{role}], [Изменить роль (owner)],
  [POST], [/api/v1/conversations/{id}/leave], [—], [Покинуть группу],
  [DELETE], [/api/v1/conversations/{id}], [—], [Удалить группу (owner)],
  [POST], [/api/v1/conversations/{id}/invite], [—], [Сгенерировать ссылку-приглашение],
  [GET], [/api/v1/invite/{code}], [—], [Присоединиться по ссылке],
)

== 6.4 E2E-шифрование в группах

- Используется Sender Keys (аналог Signal Groups): каждый участник генерирует свой Sender Key
- При добавлении участника: все текущие участники отправляют ему зашифрованный (для него) Sender Key
- Сообщения шифруются личным Sender Key отправителя и дешифруются тем же Sender Key получателя
- При удалении участника: генерируется новый Sender Key, рассылается всем оставшимся (Key Rotation)

== 6.5 RabbitMQ для групп

- Exchange: `chat.group` (`topic`, `durable`)
- Routing key: `group.{conversationId}`
- Fan-out: `MessageConsumer` читает группу и публикует в personal queues всех участников
- Альтернатива: RabbitMQ Shovel для больших групп (> 100 участников)

== 6.6 Крайние случаи

- Превышение лимита участников (500): `422 Unprocessable Entity`
- Последний admin покидает группу: следующий по `join_date` участник авто-промоутится в admin
- Owner покидает: должен передать ownership перед выходом (`400` иначе)
- Группа без участников после каскадного удаления: `conversation` помечается `deleted`


= 07 — Модуль: Пользователи и профили

== 7.1 User Stories

- Как пользователь, я хочу редактировать имя, биографию и аватар
- Как пользователь, я хочу искать других пользователей по username
- Как пользователь, я хочу управлять списком контактов (добавить / заблокировать)
- Как пользователь, я хочу настраивать приватность (кто видит мой статус / аватар)

== 7.2 Модель данных

*Таблица: contacts*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [owner_id], [uuid], [PK FK users.id], [Владелец списка],
  [contact_id], [uuid], [PK FK users.id], [Контакт],
  [status], [varchar(20)], [DEFAULT 'active'], [active | blocked],
  [custom_name], [varchar(100)], [NULL], [Кастомное имя контакта],
  [created_at], [timestamptz], [DEFAULT now()], [Дата добавления],
)

*Таблица: user_privacy_settings*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [user_id], [uuid], [PK FK users.id], [Пользователь],
  [last_seen_visibility], [varchar(20)], [DEFAULT 'contacts'], [everyone | contacts | nobody],
  [avatar_visibility], [varchar(20)], [DEFAULT 'everyone'], [everyone | contacts | nobody],
  [read_receipts_enabled], [boolean], [DEFAULT true], [Показывать ли «прочитано»],
  [online_status_visible], [boolean], [DEFAULT true], [Показывать ли онлайн],
)

== 7.3 API Endpoints

#table(
  columns: (auto, auto, auto),
  [Метод], [Путь], [Описание],
  [GET], [/api/v1/users/search?q={query}&limit=20], [Поиск по username/displayName (min 3 символа)],
  [GET], [/api/v1/users/{id}/profile], [Публичный профиль пользователя],
  [PATCH], [/api/v1/users/me], [Обновить профиль (displayName, bio)],
  [POST], [/api/v1/users/me/avatar], [Загрузить аватар (multipart, max 5 МБ, JPEG/PNG/WebP)],
  [GET], [/api/v1/users/me/contacts], [Список контактов],
  [POST], [/api/v1/users/me/contacts/{userId}], [Добавить контакт],
  [DELETE], [/api/v1/users/me/contacts/{userId}], [Удалить контакт],
  [POST], [/api/v1/users/me/contacts/{userId}/block], [Заблокировать пользователя],
  [POST], [/api/v1/users/me/contacts/{userId}/unblock], [Разблокировать пользователя],
  [GET], [/api/v1/users/me/privacy], [Настройки приватности],
  [PATCH], [/api/v1/users/me/privacy], [Обновить настройки приватности],
)


= 08 — Модуль: Файлы и медиа (MinIO)

== 8.1 User Stories

- Как пользователь, я хочу отправлять изображения, документы, аудио и видео
- Как пользователь, я хочу видеть превью изображений прямо в чате
- Как пользователь, я хочу скачивать файлы напрямую из чата

== 8.2 Buckets MinIO

#table(
  columns: (auto, auto, auto, auto),
  [Bucket], [Назначение], [ACL], [Retention],
  [chat-attachments], [Зашифрованные вложения сообщений], [private], [90 дней (configurable)],
  [chat-avatars], [Аватары пользователей и групп], [public-read], [permanent],
  [chat-thumbnails], [Превью изображений], [private], [90 дней],
)

== 8.3 Процесс загрузки файла

- Client → `POST /api/v1/conversations/{id}/attachments` (multipart/form-data, max 100 МБ)
- Backend: валидация размера, типа MIME; генерация UUID ключа объекта
- Backend: стриминговая передача в MinIO через MinIO Java SDK (`putObject` с `InputStream`)
- Backend: сохранение метаданных в `message_attachments`
- Client получает `attachmentId`, формирует `SendMessageDto` с encrypted file key
- Сообщение доставляется через WebSocket

== 8.4 Процесс скачивания

- Client → `GET /api/v1/conversations/{id}/attachments/{aid}`
- Backend: проверка доступа (участник диалога), генерация MinIO presigned URL (TTL 5 мин)
- Client скачивает напрямую с MinIO через presigned URL
- Client дешифрует файл с помощью file key из сообщения

== 8.5 Ограничения и политики

- Максимальный размер файла: 100 МБ
- Разрешённые MIME-типы: `image/*`, `video/*`, `audio/*`, `application/pdf`, `application/zip`, `text/*`, `application/msword` и OOXML-форматы
- Превью генерируется асинхронно через RabbitMQ task queue для `image/*` и `video/*`
- Thumbnail генерирует Thumbnailator (Java) для изображений, FFmpeg для видео
- Жизненный цикл: lifecycle policy в MinIO удаляет файлы при soft-delete сообщения + 30 дней


= 09 — Модуль: Уведомления

== 9.1 Типы уведомлений

#table(
  columns: (auto, auto, auto),
  [Тип], [Триггер], [Доставка],
  [NEW_MESSAGE], [Новое сообщение в диалоге], [WebSocket + Push],
  [GROUP_INVITE], [Добавлен в группу], [WebSocket + Push],
  [MESSAGE_REACTION], [Реакция на своё сообщение], [WebSocket],
  [USER_ONLINE], [Контакт появился онлайн], [WebSocket (если подписан)],
  [KEY_BUNDLE_LOW], [< 20 one-time prekeys], [WebSocket (личное)],
)

== 9.2 Модель данных

*Таблица: notifications*

#table(
  columns: (auto, auto, auto, auto),
  [Поле], [Тип], [Constraints], [Описание],
  [id], [uuid], [PK], [ID уведомления],
  [user_id], [uuid], [FK users.id], [Получатель],
  [type], [varchar(50)], [NOT NULL], [Тип (NEW_MESSAGE, GROUP_INVITE, ...)],
  [payload], [jsonb], [NOT NULL], [Данные: {senderId, conversationId, preview}],
  [read_at], [timestamptz], [NULL], [NULL = не прочитано],
  [created_at], [timestamptz], [DEFAULT now()], [Дата создания],
)

== 9.3 WebSocket Push

- Канал: `/user/queue/notifications` (личный, Spring Security гарантирует изоляцию)
- Пользователь офлайн: уведомление сохраняется в БД + очередь RabbitMQ `notifications`
- При reconnect: доставляется batch непрочитанных уведомлений


= 10 — Frontend: Angular 17

== 10.1 Архитектура Angular

- Standalone components (без NgModules), Angular Signals для state
- OnPush Change Detection Strategy на всех компонентах
- Lazy loading всех основных маршрутов
- RxJS WebSocket через `rxStomp` (@stomp/rx-stomp) с автореконнектом
- Виртуальный скроллинг (@angular/cdk/scrolling) для списка сообщений
- HTTP Interceptors: JWT inject, 401-refresh, error handling

== 10.2 Структура маршрутов

```text
/auth/login          → AuthComponent (lazy)
/auth/register       → RegisterComponent (lazy)
/app                 → AppShellComponent (guard: AuthGuard)
  /app/chats         → ChatListComponent
  /app/chats/:id     → ChatViewComponent
  /app/profile       → ProfileComponent (lazy)
  /app/settings      → SettingsComponent (lazy)
```

== 10.3 Основные экраны

#table(
  columns: (auto, auto, auto, auto),
  [Экран], [Компонент], [Состояния], [Данные],
  [Список чатов], [ChatListComponent], [loading | empty | list], [conversations$, unreadCounts$],
  [Окно чата], [ChatViewComponent], [loading | active | error], [messages$, typingUsers$, members$],
  [Профиль], [ProfileComponent], [view | edit], [user$],
  [Поиск], [UserSearchComponent], [idle | searching | results | empty], [searchResults$],
  [Информация о группе], [GroupInfoComponent], [view | edit (admin)], [group$, members$],
  [Настройки], [SettingsComponent], [tabs: privacy | notifications | keys], [settings$],
)

== 10.4 Сервисы Angular

#table(
  columns: (auto, auto),
  [Сервис], [Ответственность],
  [AuthService], [Логин, регистрация, refresh token, хранение JWT в memory (не localStorage)],
  [ChatService], [REST операции с диалогами и сообщениями],
  [WebSocketService], [STOMP подключение, подписки, переподключение],
  [CryptoService], [libsignal-protocol-typescript: X3DH, Double Ratchet, шифрование/дешифрование],
  [KeyStoreService], [IndexedDB: хранение приватных ключей (encrypted with user passphrase)],
  [MediaService], [Загрузка/скачивание файлов, шифрование перед загрузкой],
  [NotificationService], [Web Push API, управление уведомлениями],
  [UserService], [Профили, контакты, поиск],
)

== 10.5 Безопасность на клиенте

- JWT хранится в memory (переменная сервиса), НЕ в localStorage/sessionStorage
- Refresh Token хранится в HttpOnly cookie (SameSite=Strict)
- Приватные ключи E2E: IndexedDB, зашифрованные AES-GCM ключом из passphrase пользователя (PBKDF2)
- Content Security Policy: `strict-dynamic`, без `unsafe-inline`
- WebAuthn опционально для разблокировки ключей без passphrase


= 11 — Структура репозитория

== 11.1 Backend (Spring Boot)

```text
messenger-backend/
├── src/main/java/com/messenger/
│   ├── config/          # SecurityConfig, RabbitConfig, RedisConfig, MinIOConfig
│   ├── auth/            # AuthController, AuthService, JwtService, JwtAuthFilter
│   ├── user/            # UserController, UserService, UserRepository
│   ├── conversation/    # ConversationController, ConversationService
│   ├── message/         # MessageController, MessageService, WebSocketController
│   ├── group/           # GroupService, GroupController
│   ├── crypto/          # KeyBundleController, KeyBundleService
│   ├── media/           # MediaController, MinIOService, ThumbnailService
│   ├── notification/    # NotificationService, RabbitMQConsumer
│   ├── common/          # BaseEntity, ErrorHandler, PageResponse, DTOs
│   └── MessengerApplication.java
├── src/main/resources/
│   ├── application.yml
│   ├── application-prod.yml
│   └── db/changelog/    # Liquibase changesets
└── src/test/            # Unit + Integration tests (Testcontainers)
```

== 11.2 Frontend (Angular)

```text
messenger-frontend/
├── src/app/
│   ├── core/            # AuthGuard, Interceptors, Services (singleton)
│   ├── shared/          # UI components, pipes, directives
│   ├── features/
│   │   ├── auth/        # LoginComponent, RegisterComponent
│   │   ├── chat/        # ChatListComponent, ChatViewComponent
│   │   ├── group/       # GroupCreateComponent, GroupInfoComponent
│   │   ├── profile/     # ProfileComponent
│   │   └── settings/    # SettingsComponent
│   └── app.routes.ts
├── src/environments/
└── angular.json
```

== 11.3 Docker Compose (dev)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    ports: ["5432:5432"]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
  rabbitmq:
    image: rabbitmq:3.13-management
    ports: ["5672:5672", "15672:15672"]
  minio:
    image: minio/minio
    ports: ["9000:9000", "9001:9001"]
  backend:
    build: ./messenger-backend
    ports: ["8080:8080"]
  frontend:
    build: ./messenger-frontend
    ports: ["4200:4200"]
  prometheus:
    image: prom/prometheus
    ports: ["9090:9090"]
  grafana:
    image: grafana/grafana
    ports: ["3000:3000"]
```


= 12 — Субагенты Claude Code

CLAUDE.md (≤ 120 строк) — главный конфиг для Claude Code. Краткий обзор проекта, стек, правила, команды для быстрого старта субагентов.

== 12.1 Роли субагентов

#table(
  columns: (auto, auto, auto, auto),
  [Субагент], [Модель], [Инструменты], [Зона ответственности],
  [database-architect], [claude-opus-4], [Read, Write, Edit, Bash], [Liquibase changesets, схема БД, индексы, RLS],
  [backend-engineer], [claude-opus-4], [Read, Write, Edit, Bash], [Spring Boot сервисы, REST, WebSocket, AMQP, Redis],
  [security-engineer], [claude-opus-4], [Read, Write, Edit, Bash], [JWT, Spring Security, E2E-крипто, KeyBundle API],
  [frontend-developer], [claude-sonnet-4], [Read, Write, Edit, Bash], [Angular компоненты, маршруты, сервисы, STOMP],
  [qa-reviewer], [claude-sonnet-4], [Read, Bash, Glob, Grep], [Code review, тесты, безопасность (без Write/Edit)],
  [devops-engineer], [claude-sonnet-4], [Read, Write, Edit, Bash], [Docker Compose, Prometheus, Grafana, MinIO buckets],
)

== 12.2 Правила субагентов (rules)

#table(
  columns: (auto, auto, auto),
  [Файл правила], [Glob-паттерн], [Содержание],
  [backend.md], [**/*.java], [Использовать record для DTO, MapStruct для маппинга, @Validated],
  [security.md], [**/security/**, **/auth/**], [JWT через RS256, BCrypt cost=12, никогда не логировать токены],
  [database.md], [**/changelog/**, **/repository/**], [Индексы на FK, soft delete вместо hard, UUID v4 как PK],
  [frontend.md], [**/*.ts, **/*.html], [OnPush везде, никогда localStorage для JWT, async pipe],
  [crypto.md], [**/crypto/**, **CryptoService**], [Приватные ключи только в IndexedDB encrypted, не в памяти],
)


= 13 — Антипаттерны и чеклист

== 13.1 Антипаттерны для этого проекта

#table(
  columns: (auto, auto, auto),
  [Антипаттерн], [Последствие], [Правильный подход],
  [JWT в localStorage], [XSS кража токенов], [JWT в памяти, Refresh в HttpOnly cookie],
  [Приватные ключи в sessionStorage], [Утечка E2E ключей], [IndexedDB + AES-GCM + PBKDF2],
  [Polling вместо WebSocket], [Высокая latency, нагрузка на сервер], [STOMP over SockJS + Redis Pub/Sub],
  [Сохранение plaintext сообщений], [Нарушение E2E-гарантий], [Только зашифрованный content + IV],
  [Один exchange для всего], [Сложная маршрутизация], [Отдельные exchange: direct, group, notifications],
  [Hard delete сообщений], [Нарушение консистентности истории], [Soft delete: deleted_at + content = null],
  [Синхронная генерация thumbnail], [Блокировка upload endpoint], [Async через RabbitMQ task queue],
  [Раздутый CLAUDE.md (> 120 строк)], [Засорение контекста агентов], [Детали — в rules и skills],
)

== 13.2 Чеклист готовности к сборке

*База данных*

- Все таблицы из спецификации описаны в Liquibase changesets
- Индексы на `conversation_id + created_at`, `user_id` FK
- Soft delete реализован через `deleted_at`
- UUID v4 как первичные ключи

*Backend*

- JWT: RS256, 15 мин TTL, Refresh Rotation
- RabbitMQ exchanges: `chat.direct`, `chat.group`, `chat.dlx`, `notifications`
- Redis: online-статус, typing-индикатор, JWT-кэш
- MinIO buckets созданы с правильными ACL
- WebSocket STOMP: `/app/*` для приёма, `/topic/*` и `/user/*` для доставки
- Spring Security: stateless, JWT filter, CORS настроен
- Resilience4j: rate limiter на `/auth/login`

*E2E шифрование*

- KeyBundle API: upload, fetch (с consumable one-time prekeys), пополнение
- X3DH handshake реализован на клиенте
- Double Ratchet-сессия инициализируется при первом сообщении
- Sender Keys для групп с Key Rotation при изменении состава
- Файлы шифруются AES-256-GCM до загрузки в MinIO

*Frontend*

- Angular 17: standalone, OnPush, Signals
- STOMP подключение с автореконнектом и pending message queue
- CryptoService интегрирован с `libsignal-protocol-typescript`
- KeyStoreService: IndexedDB с шифрованием
- JWT не хранится в localStorage / sessionStorage
- Виртуальный скроллинг для сообщений

*Инфраструктура*

- Docker Compose: postgres, redis, rabbitmq, minio, backend, frontend, prometheus, grafana
- Переменные окружения: `JWT_PRIVATE_KEY`, `DB_URL`, `REDIS_URL`, `RABBITMQ_URL`, `MINIO_ACCESS_KEY`
- Prometheus `/actuator/prometheus` endpoint открыт
- Grafana дашборд: message throughput, latency p99, WebSocket connections


"Качество спецификации определяет качество автономной сборки.\nКаждый час в документации экономит день разработки."

Spec-First Methodology · Защищённый Мессенджер · v1.0 · 2025
