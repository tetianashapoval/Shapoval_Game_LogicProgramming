# Шаховий розв'язувач матів — Prolog та Python

Реалізація параметричного розв'язувача шахових задач на мат у N ходів на SWI-Prolog з веб-інтерфейсом та порівняльною реалізацією на Python.

Завдання виконано: Шаповал Тетяна Сергіївна

У проєкті є дві серверні реалізації:
- Prolog — основна реалізація логіки пошуку мату та AI
- Python — альтернативна реалізація з тим самим алгоритмом та сумісним REST API

Фронтенд (`HTML/CSS/JS`) спільний для обох реалізацій і працює через http://localhost:8080/.

## Запуск

1. Встановити залежності:
Bash


   pip3 install pyswip
   brew install gmp
   echo 'export PATH=$PATH:/Applications/SWI-Prolog.app/Contents/MacOS' >> ~/.zshrc
   source ~/.zshrc

2. Запустити Prolog сервер (Термінал 1):
Bash


   cd Shapoval_Game && swipl chess_server.pl

3. Запустити Python сервер (Термінал 2):
Bash


   cd Shapoval_Game && python3 chess_server_python.py

4. Відкрити у браузері: http://localhost:8080/

## Структура проєкту

chess_board.pl          — Prolog: шахова логіка + MinMax + Alpha-Beta
chess_server.pl         — Prolog HTTP сервер (порт 8080)
mate_python.py          — Python: порівняльна реалізація алгоритму
chess_server_python.py  — Python HTTP сервер (порт 8081)
index.html              — веб-інтерфейс
README.md               — опис проєкту

## Алгоритм

MinMax з відсіканням Альфа-Бета:
- Атакуючий — MAX-вузол, захисник — MIN-вузол
- Пошук мату в N ходів (N = 2, 3, 4)
- Глибина задається в пів-ходах: 3 / 5 / 7
- Ходи сортуються перед пошуком (шахи → взяття → решта)

## Порівняння Prolog vs Python

| Задача | Prolog | Python | Переможець |
|--------|--------|--------|------------|
| Мат в 2 | 0.050с | 0.013с | Python 4× |
| Мат в 3 | 0.086с | 0.019с | Python 5× |
| Мат в 4 | 0.244с | 5.835с | Prolog 24× |

Python швидший на малих глибинах завдяки нативним структурам даних.
Prolog у 24 рази швидший на глибині 4 завдяки вбудованому бектрекінгу та уніфікації.

## Режими гри

| Режим | Опис |
|-------|------|
| Задача | Завантаження FEN, пошук мату в N ходів |
| Людина vs Людина | Двоє гравців за одним комп'ютером |
| Людина vs Prolog/Python | Людина проти AI |
| Prolog vs Prolog / Python vs Python | AI грає сам з собою |

## REST API

| Endpoint | Метод | Опис |
|----------|-------|------|
| /api/legal_moves | POST | Отримати легальні ходи |
| /api/apply_move | POST | Виконати хід |
| /api/mate | POST | Знайти мат в N ходів |
| /api/best_move | POST | Найкращий хід для AI |

## Структура коду

chess_board.pl
  ├── Представлення позиції (pos/4, Board як список 64 елементів)
  ├── Генерація легальних ходів (всі фігури, перевірка шаху)
  ├── Парсер FEN (fen_to_pos, pos_to_fen)
  ├── Пошук мату (mate_in, mate_in_ab)
  └── Alpha-Beta відсікання (order_moves, ab_defender_loses)

mate_python.py
  ├── Той самий алгоритм на Python
  ├── fenToBoard, legal_moves, apply_move
  └── mate_in_ab з Alpha-Beta

## Тестові задачі

| Задача | FEN | Рішення |
|--------|-----|---------|
| GQOkw — мат в 2 | 3qk2r/pp4p1/5Pn1/4p3/2B3Q1/4p3/PPP2PPP/R3K2R b KQkq - 0 14 | Qd2+ Kf1 Qxf2# |
| zCJpm — мат в 3 | 5r1k/2pnq1p1/2p3P1/p1b1p1r1/1pQ5/3P3P/PPP2P2/2K3RR w - - 0 22 | Qh4 Rh5 Qxh5 Kg8 Qh7# |

## Першоджерела

Уся ігрова логіка, алгоритм та архітектура розроблені авторами самостійно.
Зовнішні бібліотеки використані за стандартною документацією:
- SWI-Prolog: http/thread_httpd, http_dispatch, http_json
- Python: http.server, стандартна бібліотека

## Джерела

1. Russell S. J. Artificial Intelligence: A Modern Approach / S. J. Russell, P. Norvig. — 4th ed. — Hoboken : Pearson, 2020. — (Розд. 5: Adversarial Search and Games).
2. SWI-Prolog HTTP server libraries // SWI-Prolog Reference Manual. — https://www.swi-prolog.org/pldoc/man?section=http
3. Lichess puzzle database — https://lichess.org/training
4. Knuth D. E. An Analysis of Alpha-Beta Pruning / D. E. Knuth, R. W. Moore // Artificial Intelligence. — 1975. — Vol. 6, No. 4. — P. 293–326.
