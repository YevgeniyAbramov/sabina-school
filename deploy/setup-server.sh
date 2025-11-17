#!/bin/bash

# Скрипт первоначальной настройки сервера для sabina-school

set -e

echo "Начинаем настройку сервера"

# Обновление системы до последних версий пакетов
echo "Обновление системы"
sudo apt update && sudo apt upgrade -y

# Установка Docker для контейнеризации приложения
echo "Установка Docker"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker установлен"
else
    echo "Docker уже установлен"
fi

# Установка Docker Compose для управления многоконтейнерными приложениями
echo "Установка Docker Compose"
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose установлен"
else
    echo "Docker Compose уже установлен"
fi

# Создание рабочей директории приложения
echo "Создание директории приложения"
sudo mkdir -p /opt/sabina-school
sudo chown $USER:$USER /opt/sabina-school
cd /opt/sabina-school

# Загрузка конфигурации docker-compose из репозитория
echo "Скачивание конфигурации"
curl -o docker-compose.yml https://raw.githubusercontent.com/YevgeniyAbramov/sabina-school/main/deploy/docker-compose.prod.yml

# Создание файла переменных окружения
if [ ! -f .env ]; then
    echo "Создание .env файла"
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
    echo "ВНИМАНИЕ: Необходимо изменить пароль в файле .env"
    echo "Отредактируй файл nano /opt/sabina-school/.env"
else
    echo ".env файл уже существует"
fi

echo ""
echo "Настройка завершена"
echo ""
echo "Следующие шаги:"
echo "1. Отредактируй .env файл: nano /opt/sabina-school/.env"
echo "2. Измени db_password на безопасный пароль"
echo "3. Запусти приложение: docker-compose up -d"
echo "4. Настрой базу данных вручную"
echo "5. Проверь статус: docker-compose ps"
echo "6. Открой в браузере: http://your-server-ip:3000"

