# Хранение фотографий на Яндекс.Диске

## Режим папки приложения (рекомендуется)

1. В [oauth.yandex.com](https://oauth.yandex.com/) у приложения включите **только**:
   - «Доступ к папке приложения на Яндекс.Диске» (`cloud_api:disk.app_folder`)
2. **Не** включайте полный доступ (`disk.read` / `disk.write`) — иначе токен сможет трогать весь Диск.
3. Получите OAuth-токен и задайте в ENV:

```bash
YANDEX_DISK_TOKEN=...
YANDEX_DISK_APP_FOLDER=true   # по умолчанию
YANDEX_DISK_FOLDER=geneus     # подпапка: app:/geneus/… ; пусто = app:/…
```

Файлы лежат в системной папке «Приложения» / Apps, изолированно от остального Диска.

## Legacy: полный доступ к Диску

Если уже есть токен с `disk.read`/`disk.write`:

```bash
YANDEX_DISK_APP_FOLDER=false
```

Пути будут `/geneus/…` на всём Диске (ограничение только в коде).

## Переменные

| Переменная | По умолчанию | Описание |
|------------|--------------|----------|
| `YANDEX_DISK_TOKEN` | — | OAuth-токен |
| `YANDEX_DISK_APP_FOLDER` | `true` | `app:/` и изоляция API |
| `YANDEX_DISK_FOLDER` | `geneus` | Подпапка внутри хранилища |

Фронтенд менять не нужно.
