# TODO менеджер — Flutter, варіант 4

Лабораторна робота: Flutter-додаток для управління задачами різних користувачів через JSONPlaceholder REST API.

## Можливості

- **GET `/todos`** — список усіх задач, статус і прапорець виконання.
- **GET `/users`, GET `/todos?userId={id}`** — список користувачів, їхні задачі та статистика.
- **POST `/todos`** — створення задачі з назвою, користувачем і початковим статусом.
- **PUT `/todos/{id}`** — редагування задачі.
- **PATCH `/todos/{id}`** — перемикання статусу виконання.
- **DELETE `/todos/{id}`** — видалення, свайп вліво, кнопка **СКАСУВАТИ** протягом 3 секунд.
- Фільтри: усі / виконані / очікують.
- Локальний пошук за назвою, групування задач за користувачем.
- Прогрес-бар і лічильники всього / виконано / очікують.
- `FutureBuilder`, `ListView.builder`, `CircularProgressIndicator`, екран помилки з кнопкою «Повторити».
- `http`, ручні методи `fromJson` і `toJson`, окремий API-сервіс.

## Увага: як працює API

`https://jsonplaceholder.typicode.com` — **демонстраційний**, а не справжній сервер бази даних. Він відповідає на POST/PUT/PATCH/DELETE, але НЕ зберігає результат на сервері. Тому в цьому проєкті всі власні зміни зберігаються **локально на пристрої** через `shared_preferences`. Після повторного запуску вони залишаться в додатку на тому самому пристрої. Для нових локальних задач PATCH, PUT і DELETE виконуються локально, бо цих ID немає на сервері. Для початкових задач запити виконуються через HTTP.

Для роботи потрібен інтернет лише для завантаження вихідних даних та звернень до API. **Окремий Node.js, Python або інший API-сервер запускати НЕ потрібно.**

## Як запустити на Windows у VS Code

1. Встановіть **Flutter SDK**, **VS Code** та розширення **Flutter** і **Dart**.
2. Для Android встановіть **Android Studio** з Android SDK та емулятором. Запустіть емулятор у Device Manager або підключіть телефон з USB debugging.
3. Розпакуйте архів, відкрийте **саме папку `flutter_todo_manager`**, у якій є `pubspec.yaml`.
4. Уперше запустіть подвійним кліком **`setup_windows.bat`** або відкрийте термінал VS Code (`Ctrl` + `` ` ``) та виконайте:

   ```powershell
   flutter create --platforms=android,web .
   flutter pub get
   flutter doctor
   ```

   Команда `flutter create` створює стандартні службові файли Android/Web, яких немає в архіві. Ваш Dart-код залишається на місці.

5. Перевірте доступні пристрої:

   ```powershell
   flutter devices
   ```

6. Запустіть:

   ```powershell
   flutter run
   ```

   Або у Chrome:

   ```powershell
   flutter run -d chrome
   ```

   У VS Code також можна обрати пристрій унизу праворуч і натиснути **F5**.

> Якщо Android Studio показує «No devices», створіть емулятор через **Device Manager → Create Virtual Device** і натисніть ▶. Після цього повторіть `flutter devices`.

## Тести

```powershell
flutter test
flutter analyze
```

Тести знаходяться у `test/`: перевірка JSON-моделі та HTTP GET/POST/PUT/PATCH/DELETE через `MockClient`, а також перевірка екрана помилки. **Автор не запускав ці тести в середовищі без Flutter SDK; запустіть їх локально після налаштування.**

## Структура

```text
lib/
├── main.dart
├── models/
│   ├── todo.dart
│   ├── app_user.dart
│   └── todo_input.dart
├── services/
│   ├── api_service.dart
│   └── todo_repository.dart
├── screens/
│   ├── list_screen.dart
│   ├── detail_screen.dart
│   └── create_edit_screen.dart
└── widgets/
    ├── item_card.dart
    └── error_widget.dart

test/
├── todo_model_test.dart
├── api_service_test.dart
└── widget_test.dart
```

## Приклади коментарів із коду

1. **Мережевий рівень:** «Усі HTTP-запити до JSONPlaceholder знаходяться в одному місці» (`api_service.dart`).
2. **Локальне зберігання:** «JSONPlaceholder не зберігає POST/PUT/PATCH/DELETE на сервері» (`todo_repository.dart`).
3. **Видалення жестом:** «Видаляємо через HTTP перед оновленням списку» (`item_card.dart`).

## Як здати в GitHub (3 коміти)

Після запуску у VS Code відкрийте **Terminal → New Terminal** у корені проєкту:

```powershell
git init
git add pubspec.yaml lib/models lib/services
git commit -m "Implement TODO models and API"
git add lib/screens lib/widgets lib/main.dart
git commit -m "Build TODO screens and CRUD actions"
git add .
git commit -m "Add README, tests and launch configuration"
```

Створіть порожній репозиторій на GitHub, а потім виконайте (замініть адресу):

```powershell
git branch -M main
git remote add origin https://github.com/USERNAME/flutter_todo_manager.git
git push -u origin main
```

Посилання на GitHub-репозиторій надішліть викладачу. Коміти створюєте **ви на своєму ПК**; вони не з'являються в ZIP автоматично.

## Технології

Flutter / Dart, пакет `http`, пакет `shared_preferences`, Material 3. API: <https://jsonplaceholder.typicode.com/todos>.
