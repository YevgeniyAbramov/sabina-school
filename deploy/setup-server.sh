#!/bin/bash

# Скрипт первоначальной настройки сервера для sabina-school

set -e

echo "🚀 Начинаем настройку сервера для Sabina School..."

# Обновление системы
echo "📦 Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка Docker
echo "🐳 Установка Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker установлен"
else
    echo "✅ Docker уже установлен"
fi

# Установка Docker Compose
echo "🐳 Установка Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose установлен"
else
    echo "✅ Docker Compose уже установлен"
fi

# Создание директории для приложения
echo "📁 Создание директории приложения..."
sudo mkdir -p /opt/sabina-school
sudo chown $USER:$USER /opt/sabina-school
cd /opt/sabina-school

# Скачивание docker-compose.yml
echo "📥 Скачивание конфигурации..."
curl -o docker-compose.yml https://raw.githubusercontent.com/YevgeniyAbramov/sabina-school/main/deploy/docker-compose.prod.yml

# Создание .env файла
if [ ! -f .env ]; then
    echo "📝 Создание .env файла..."
    cat > .env << 'EOF'
# Database Configuration
db_host=db
db_port=5432
db_user=admin
db_password=CHANGE_THIS_PASSWORD
db_name=sabina_school
db_sslmode=disable

# Docker Hub
DOCKERHUB_USERNAME=yevgeniyabramov
EOF
    echo "⚠️  НЕ ЗАБУДЬ изменить пароль в файле .env!"
    echo "   Отредактируй файл: nano /opt/sabina-school/.env"
else
    echo "✅ .env файл уже существует"
fi

# Создание схемы auth в базе данных (скрипт)
echo "📝 Создание скрипта инициализации БД..."
cat > init-db.sh << 'EOF'
#!/bin/bash
# Ждем запуска PostgreSQL
sleep 10

# Подключаемся к контейнеру БД и создаем схему
docker exec -i sabina_school_db psql -U admin -d sabina_school << 'SQL'
-- Создание схемы auth
CREATE SCHEMA IF NOT EXISTS auth;

-- Создание таблицы преподавателей
CREATE TABLE IF NOT EXISTS auth.teacher (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT,
    middle_name TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Создание таблицы студентов
CREATE TABLE IF NOT EXISTS auth.student (
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT,
    middle_name TEXT,
    total_lessons INT DEFAULT 0,
    remaining_lessons INT DEFAULT 0,
    paid_amount INT DEFAULT 0,
    missed_classes INT DEFAULT 0,
    is_paid BOOLEAN DEFAULT FALSE,
    teacher_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES auth.teacher(id)
);

-- Создание тестового преподавателя (логин: test, пароль: test)
INSERT INTO auth.teacher (username, password, first_name, last_name, middle_name, created_at)
VALUES ('test', 'test', 'Тестовый', 'Преподаватель', 'Иванович', NOW())
ON CONFLICT (username) DO NOTHING;

\echo '✅ База данных настроена!'
SQL
EOF
chmod +x init-db.sh

echo ""
echo "✅ Настройка завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Отредактируй .env файл: nano /opt/sabina-school/.env"
echo "2. Измени db_password на безопасный пароль"
echo "3. Запусти приложение: docker-compose up -d"
echo "4. Инициализируй БД: ./init-db.sh"
echo "5. Проверь статус: docker-compose ps"
echo "6. Открой в браузере: http://your-server-ip:3000"
echo ""
echo "🔑 Тестовый аккаунт: test / test"

