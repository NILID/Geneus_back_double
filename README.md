![Geneus logo](https://raw.githubusercontent.com/NILID/Geneus/master/geneus-github.png)

# Geneus

Geneus is a Ruby on Rails based genealogy application that operates on the wiki principle: all users edit the same record for an individual.

There is a demo  [running on Heroku](https://geneus.herokuapp.com/). Please feel free to explore.

## Status

This project is in pre-alpha state, meaning you won't find a full set of features to work with. At this point you can:

* Create, edit and delete people
* Add basic genealogical relationships
* Add basic personal information
* Navigate the family tree
* View change history

It is conspicuously missing:

* User accounts of any kind
* Editing permissions (open to the world)
* Relationship validations

## TODO
* Make current style for none-parent children
* Add photos with tags and tags of people
* Add location coordinates
* Rebuild history functionality
* Rebuild parentship functionality
* Add eager loading
* More validations
* More tests
* Allow create person info about birthday/death with year|month|day only

## Setup

    bundle install
    rake db:migrate
    rails server

### Фото на Яндекс.Диске (опционально)

Active Storage хранит **аватары** и **фото галереи** раздельно: `avatars/` и `photos/` (локально `storage/avatars`, `storage/photos`; на Диске `app:/…/avatars`, `app:/…/photos`).
В [oauth.yandex.com](https://oauth.yandex.com/) — право «Доступ к папке приложения», `YANDEX_DISK_TOKEN`, `YANDEX_DISK_APP_FOLDER=true`.
Общий префикс: `YANDEX_DISK_FOLDER` (например `geneus` → `app:/geneus/avatars/…`). См. `.env.production.example`.

## Bugs?

If you find a bug please add an [issue on GitHub](https://github.com/NILID/Geneus/issues) or fork the project and send a pull request.