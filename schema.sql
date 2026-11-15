-- 1. В pgAdmin 4 создайте БД с именем minecraft_mods.
-- 2. Откройте Query Tool именно этой БД.
-- 3. Выполните весь этот файл.

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS mods (
    id SERIAL PRIMARY KEY,
    title VARCHAR(120) NOT NULL UNIQUE,
    slug VARCHAR(140) NOT NULL UNIQUE,
    short_description VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT NOT NULL,
    version VARCHAR(20) NOT NULL,
    rating NUMERIC(2,1) NOT NULL DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    downloads INTEGER NOT NULL DEFAULT 0 CHECK (downloads >= 0),
    image_url TEXT,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    author_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mod_categories (
    mod_id INTEGER NOT NULL REFERENCES mods(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (mod_id, category_id)
);

CREATE TABLE IF NOT EXISTS forum_topics (
    id SERIAL PRIMARY KEY,
    title VARCHAR(180) NOT NULL,
    message TEXT NOT NULL,
    author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO categories (name) VALUES
('Магия'), ('Технологии'), ('Оружие и броня'), ('Мебель и декор'),
('Биомы'), ('Генерация мира'), ('Геймплей'), ('RPG'),
('Хоррор'), ('Оптимизация')
ON CONFLICT (name) DO NOTHING;

-- Тестовый пользователь: пароль в приложении не хранится в открытом виде.
-- Для демонстрации ниже используется заранее рассчитанный хеш Werkzeug.
INSERT INTO users (username, email, password_hash)
VALUES (
    'admin',
    'admin@example.com',
    'scrypt:32768:8:1$demo$'
)
ON CONFLICT (username) DO NOTHING;

-- Если тестовый admin нужен для входа, лучше зарегистрировать нового пользователя
-- через страницу /register. Это создаст корректный хеш.

INSERT INTO mods
(title, slug, short_description, description, version, rating, downloads, image_url, verified)
VALUES
('Create', 'create', 'Технологический мод с механизмами и автоматизацией.',
 'Большой технологический мод для строительства механизмов, автоматизации производства и создания сложных фабрик.',
 '1.20.x', 4.8, 12450, NULL, TRUE),
('JEI', 'jei', 'Удобный просмотр предметов и рецептов.',
 'Мод добавляет интерфейс для просмотра предметов, рецептов и способов получения ресурсов.',
 '1.20.x', 4.7, 18320, NULL, TRUE),
('Alex''s Mobs', 'alexs-mobs', 'Новые животные и существа.',
 'Набор новых мобов с уникальным поведением, предметами и особенностями игрового мира.',
 '1.19.x', 4.6, 9730, NULL, TRUE)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO mod_categories (mod_id, category_id)
SELECT m.id, c.id FROM mods m, categories c
WHERE (m.slug = 'create' AND c.name IN ('Технологии', 'Оптимизация'))
   OR (m.slug = 'jei' AND c.name IN ('Технологии'))
   OR (m.slug = 'alexs-mobs' AND c.name IN ('Биомы', 'Геймплей'))
ON CONFLICT DO NOTHING;



-- Дополнительная подборка популярных модов для наполнения каталога (24 записи).
INSERT INTO mods
(title, slug, short_description, description, version, rating, downloads, image_url, verified)
VALUES
('Sodium', 'sodium', 'Оптимизация графики и повышение производительности.', 'Клиентский мод оптимизации рендеринга, который помогает повысить производительность Minecraft.', '1.20.x', 4.9, 28600, NULL, TRUE),
('Iris Shaders', 'iris-shaders', 'Поддержка шейдеров с удобным интерфейсом.', 'Добавляет поддержку шейдерных пакетов и совместим с современными графическими модификациями.', '1.20.x', 4.8, 21400, NULL, TRUE),
('JourneyMap', 'journeymap', 'Подробная карта мира в реальном времени.', 'Добавляет мини-карту и полноэкранную карту с отображением исследованных территорий.', '1.20.x', 4.7, 17200, NULL, TRUE),
('Biomes O'' Plenty', 'biomes-o-plenty', 'Множество новых биомов и растений.', 'Расширяет генерацию мира большим количеством новых биомов, растений и природных объектов.', '1.20.x', 4.7, 15300, NULL, TRUE),
('Farmer''s Delight', 'farmers-delight', 'Новые блюда, фермерство и кухонные блоки.', 'Расширяет сельское хозяйство и приготовление еды, добавляя новые культуры, блюда и инструменты.', '1.20.x', 4.8, 14800, NULL, TRUE),
('Waystones', 'waystones', 'Телепортация между установленными камнями.', 'Позволяет создавать точки быстрого перемещения и путешествовать между ними.', '1.20.x', 4.6, 13200, NULL, TRUE),
('Alex''s Caves', 'alexs-caves', 'Необычные подземные биомы и существа.', 'Добавляет редкие подземные биомы, новых существ, блоки и предметы для исследования.', '1.20.x', 4.7, 11900, NULL, TRUE),
('Botania', 'botania', 'Магия природы, цветы и автоматизация.', 'Магический технологический мод, основанный на цветах, природной энергии и автоматизированных механизмах.', '1.20.x', 4.8, 11600, NULL, TRUE),
('Mekanism', 'mekanism', 'Мощные машины, энергия и переработка ресурсов.', 'Добавляет технологические механизмы, энергетические системы, трубы и многоступенчатую переработку ресурсов.', '1.20.x', 4.9, 16400, NULL, TRUE),
('Applied Energistics 2', 'applied-energistics-2', 'Цифровое хранение и автоматизация предметов.', 'Добавляет систему хранения предметов в сети, терминалы и автоматизацию крафта.', '1.20.x', 4.8, 13900, NULL, TRUE),
('Xaero''s Minimap', 'xaeros-minimap', 'Компактная мини-карта с метками.', 'Добавляет настраиваемую мини-карту, отображение окружения и пользовательские метки.', '1.20.x', 4.8, 19100, NULL, TRUE),
('Jade', 'jade', 'Подсказки о блоках и существах.', 'Показывает полезную информацию о блоке или существе, на которое направлен игрок.', '1.20.x', 4.7, 12600, NULL, TRUE),
('AppleSkin', 'appleskin', 'Подробная информация о голоде и насыщении.', 'Отображает дополнительные сведения о шкале голода и свойствах еды.', '1.20.x', 4.6, 10800, NULL, TRUE),
('Mouse Tweaks', 'mouse-tweaks', 'Удобное управление предметами в инвентаре.', 'Улучшает перемещение и распределение предметов мышью в окнах инвентаря.', '1.20.x', 4.7, 9700, NULL, TRUE),
('Terralith', 'terralith', 'Обновлённая генерация обычного мира.', 'Изменяет генерацию Верхнего мира, добавляя разнообразные ландшафты и природные области.', '1.20.x', 4.8, 14200, NULL, TRUE),
('YUNG''s Better Dungeons', 'yungs-better-dungeons', 'Обновлённые подземелья с новыми комнатами.', 'Перерабатывает подземелья, делая их разнообразнее и интереснее для исследования.', '1.20.x', 4.7, 8900, NULL, TRUE),
('Supplementaries', 'supplementaries', 'Декоративные и функциональные блоки.', 'Добавляет множество небольших функциональных блоков и предметов для строительства и приключений.', '1.20.x', 4.6, 9300, NULL, TRUE),
('Sophisticated Backpacks', 'sophisticated-backpacks', 'Рюкзаки с улучшениями и дополнительным хранением.', 'Добавляет настраиваемые рюкзаки с улучшениями для сортировки, хранения и работы с предметами.', '1.20.x', 4.7, 11100, NULL, TRUE),
('Iron Chests', 'iron-chests', 'Сундуки с увеличенной вместимостью.', 'Добавляет сундуки из различных материалов с разным объёмом хранения.', '1.20.x', 4.5, 8400, NULL, TRUE),
('Better Combat', 'better-combat', 'Более динамичная система ближнего боя.', 'Изменяет анимации и механику ближнего боя, поддерживая различные виды оружия.', '1.20.x', 4.6, 10200, NULL, TRUE),
('Origins', 'origins', 'Выбор происхождения с уникальными способностями.', 'Добавляет систему происхождений: каждое даёт игроку особые преимущества и ограничения.', '1.20.x', 4.8, 15700, NULL, TRUE),
('Corpse', 'corpse', 'Сохранение вещей в могиле после поражения.', 'Создаёт контейнер с предметами игрока в месте его последнего поражения.', '1.20.x', 4.5, 7600, NULL, TRUE),
('Carry On', 'carry-on', 'Перенос некоторых блоков и существ.', 'Позволяет поднимать и переносить некоторые блоки с инвентарём и небольших существ.', '1.20.x', 4.6, 8200, NULL, TRUE),
('Nature''s Compass', 'natures-compass', 'Поиск нужных биомов.', 'Добавляет компас, который помогает находить выбранные биомы в мире.', '1.20.x', 4.6, 9100, NULL, TRUE)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO mod_categories (mod_id, category_id)
SELECT m.id, c.id FROM (VALUES
('sodium', 'Оптимизация'),
('iris-shaders', 'Оптимизация'),
('journeymap', 'Геймплей'),
('biomes-o-plenty', 'Биомы'),
('biomes-o-plenty', 'Генерация мира'),
('farmers-delight', 'Геймплей'),
('farmers-delight', 'Мебель и декор'),
('waystones', 'Геймплей'),
('alexs-caves', 'Биомы'),
('alexs-caves', 'Геймплей'),
('botania', 'Магия'),
('botania', 'Технологии'),
('mekanism', 'Технологии'),
('applied-energistics-2', 'Технологии'),
('xaeros-minimap', 'Геймплей'),
('jade', 'Геймплей'),
('appleskin', 'Геймплей'),
('mouse-tweaks', 'Геймплей'),
('terralith', 'Биомы'),
('terralith', 'Генерация мира'),
('yungs-better-dungeons', 'Генерация мира'),
('yungs-better-dungeons', 'RPG'),
('supplementaries', 'Мебель и декор'),
('supplementaries', 'Геймплей'),
('sophisticated-backpacks', 'Геймплей'),
('sophisticated-backpacks', 'Технологии'),
('iron-chests', 'Технологии'),
('better-combat', 'Оружие и броня'),
('better-combat', 'Геймплей'),
('origins', 'RPG'),
('origins', 'Геймплей'),
('corpse', 'Геймплей'),
('carry-on', 'Геймплей'),
('natures-compass', 'Биомы'),
('natures-compass', 'Геймплей')
) AS v(slug, category_name)
JOIN mods m ON m.slug = v.slug
JOIN categories c ON c.name = v.category_name
ON CONFLICT DO NOTHING;

-- Пример темы форума, если admin существует.
INSERT INTO forum_topics (title, message, author_id)
SELECT 'Как установить моды на Forge?', 'Обсуждение установки модов и зависимостей.', id
FROM users WHERE username = 'admin'
AND NOT EXISTS (SELECT 1 FROM forum_topics WHERE title = 'Как установить моды на Forge?');


-- Обложки для всех модов каталога (локальные изображения проекта).
UPDATE mods SET image_url = CASE slug
    WHEN 'create' THEN '/static/mods/create.jpg'
    WHEN 'jei' THEN '/static/mods/jei.jpg'
    WHEN 'alexs-mobs' THEN '/static/mods/alexs-mobs.jpg'
    WHEN 'sodium' THEN '/static/mods/sodium.jpg'
    WHEN 'iris-shaders' THEN '/static/mods/iris-shaders.jpg'
    WHEN 'journeymap' THEN '/static/mods/journeymap.jpg'
    WHEN 'biomes-o-plenty' THEN '/static/mods/biomes-o-plenty.jpg'
    WHEN 'farmers-delight' THEN '/static/mods/farmers-delight.jpg'
    WHEN 'waystones' THEN '/static/mods/waystones.jpg'
    WHEN 'alexs-caves' THEN '/static/mods/alexs-caves.jpg'
    WHEN 'botania' THEN '/static/mods/botania.jpg'
    WHEN 'mekanism' THEN '/static/mods/mekanism.jpg'
    WHEN 'applied-energistics-2' THEN '/static/mods/applied-energistics-2.jpg'
    WHEN 'xaeros-minimap' THEN '/static/mods/xaeros-minimap.jpg'
    WHEN 'jade' THEN '/static/mods/jade.jpg'
    WHEN 'appleskin' THEN '/static/mods/appleskin.jpg'
    WHEN 'mouse-tweaks' THEN '/static/mods/mouse-tweaks.jpg'
    WHEN 'terralith' THEN '/static/mods/terralith.jpg'
    WHEN 'yungs-better-dungeons' THEN '/static/mods/yungs-better-dungeons.jpg'
    WHEN 'supplementaries' THEN '/static/mods/supplementaries.jpg'
    WHEN 'sophisticated-backpacks' THEN '/static/mods/sophisticated-backpacks.jpg'
    WHEN 'iron-chests' THEN '/static/mods/iron-chests.jpg'
    WHEN 'better-combat' THEN '/static/mods/better-combat.jpg'
    WHEN 'origins' THEN '/static/mods/origins.jpg'
    WHEN 'corpse' THEN '/static/mods/corpse.jpg'
    WHEN 'carry-on' THEN '/static/mods/carry-on.jpg'
    WHEN 'natures-compass' THEN '/static/mods/natures-compass.jpg'
    ELSE image_url
END
WHERE slug IN ('create', 'jei', 'alexs-mobs', 'sodium', 'iris-shaders', 'journeymap', 'biomes-o-plenty', 'farmers-delight', 'waystones', 'alexs-caves', 'botania', 'mekanism', 'applied-energistics-2', 'xaeros-minimap', 'jade', 'appleskin', 'mouse-tweaks', 'terralith', 'yungs-better-dungeons', 'supplementaries', 'sophisticated-backpacks', 'iron-chests', 'better-combat', 'origins', 'corpse', 'carry-on', 'natures-compass');
