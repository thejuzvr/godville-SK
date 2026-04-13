#!/bin/bash

# Скрипт проверки системы контекстов событий журнала
# Для Ubuntu Linux

set -e

echo "=========================================="
echo "Проверка системы контекстов событий журнала"
echo "=========================================="
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода успешных сообщений
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Функция для вывода ошибок
error() {
    echo -e "${RED}✗ $1${NC}"
}

# Функция для вывода предупреждений
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Функция для вывода информационных сообщений
info() {
    echo -e "ℹ $1"
}

# Проверка наличия необходимых команд
check_command() {
    if ! command -v $1 &> /dev/null; then
        error "Команда $1 не найдена"
        return 1
    else
        success "Команда $1 найдена"
        return 0
    fi
}

echo "1. Проверка необходимых команд..."
echo "-----------------------------------"
check_command "mix"
check_command "psql"
check_command "elixir"
echo ""

# Проверка миграций
echo "2. Проверка миграций..."
echo "-----------------------------------"
if [ -d "priv/repo/migrations" ]; then
    success "Директория миграций существует"
    
    # Проверка наличия миграции для индексов
    if ls priv/repo/migrations/*add_context_index* 1> /dev/null 2>&1; then
        success "Миграция для индексов найдена"
    else
        error "Миграция для индексов не найдена"
    fi
else
    error "Директория миграций не существует"
fi
echo ""

# Проверка модуля валидации
echo "3. Проверка модуля валидации..."
echo "-----------------------------------"
if [ -f "lib/godville_sk/game/log_metadata.ex" ]; then
    success "Модуль LogMetadata существует"
    
    # Проверка синтаксиса
    if elixir -c lib/godville_sk/game/log_metadata.ex 2>/dev/null; then
        success "Синтаксис модуля корректен"
    else
        error "Ошибка синтаксиса в модуле LogMetadata"
    fi
else
    error "Модуль LogMetadata не найден"
fi
echo ""

# Проверка обновлений в hero.ex
echo "4. Проверка обновлений в hero.ex..."
echo "-----------------------------------"
if grep -q "alias GodvilleSk.Game.LogMetadata" lib/godville_sk/hero.ex; then
    success "Импорт LogMetadata найден в hero.ex"
else
    error "Импорт LogMetadata не найден в hero.ex"
fi

if grep -q "LogMetadata.validate" lib/godville_sk/hero.ex; then
    success "Вызов LogMetadata.validate найден в hero.ex"
else
    error "Вызов LogMetadata.validate не найден в hero.ex"
fi

if grep -q "sovngarde_task" lib/godville_sk/hero.ex; then
    success "Тип события sovngarde_task найден"
else
    error "Тип события sovngarde_task не найден"
fi

if grep -q "sovngarde_thought" lib/godville_sk/hero.ex; then
    success "Тип события sovngarde_thought найден"
else
    error "Тип события sovngarde_thought не найден"
fi
echo ""

# Проверка обновлений в dashboard_live.ex
echo "5. Проверка обновлений в dashboard_live.ex..."
echo "-----------------------------------"
if grep -q "filter_logs_by_context" lib/godville_sk_web/live/dashboard_live.ex; then
    success "Функция filter_logs_by_context найдена"
else
    error "Функция filter_logs_by_context не найдена"
fi

if grep -q "normal_logs" lib/godville_sk_web/live/dashboard_live.ex; then
    success "Функция normal_logs найдена"
else
    error "Функция normal_logs не найдена"
fi

if grep -q "sovngarde_logs" lib/godville_sk_web/live/dashboard_live.ex; then
    success "Функция sovngarde_logs найдена"
else
    error "Функция sovngarde_logs не найдена"
fi
echo ""

# Проверка конфигурации базы данных
echo "6. Проверка конфигурации базы данных..."
echo "-----------------------------------"
if [ -f "config/dev.exs" ]; then
    success "Файл конфигурации dev.exs существует"
    
    # Извлечение параметров подключения
    DB_HOST=$(grep -oP 'hostname: "\K[^"]+' config/dev.exs || echo "localhost")
    DB_NAME=$(grep -oP 'database: "\K[^"]+' config/dev.exs || echo "godville_sk")
    DB_USER=$(grep -oP 'username: "\K[^"]+' config/dev.exs || echo "godville_sk")
    
    info "Параметры подключения:"
    info "  Host: $DB_HOST"
    info "  Database: $DB_NAME"
    info "  User: $DB_USER"
else
    error "Файл конфигурации dev.exs не найден"
fi
echo ""

# Проверка подключения к базе данных
echo "7. Проверка подключения к базе данных..."
echo "-----------------------------------"
if PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -c "SELECT 1;" &> /dev/null; then
    success "Подключение к базе данных успешно"
    
    # Проверка таблицы hero_logs
    if PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -c "\d hero_logs" &> /dev/null; then
        success "Таблица hero_logs существует"
        
        # Проверка индексов
        INDEX_COUNT=$(PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -t -c "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'hero_logs' AND indexname LIKE '%context%';")
        
        if [ "$INDEX_COUNT" -gt 0 ]; then
            success "Индексы для контекста найдены ($INDEX_COUNT индексов)"
        else
            warning "Индексы для контекста не найдены. Возможно, миграция не выполнена."
        fi
        
        # Проверка GIN индекса
        if PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -c "SELECT 1 FROM pg_indexes WHERE tablename = 'hero_logs' AND indexname = 'hero_logs_metadata_gin_index';" &> /dev/null; then
            success "GIN индекс hero_logs_metadata_gin_index существует"
        else
            warning "GIN индекс hero_logs_metadata_gin_index не найден"
        fi
        
        # Проверка B-tree индекса для контекста
        if PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -c "SELECT 1 FROM pg_indexes WHERE tablename = 'hero_logs' AND indexname = 'hero_logs_context_index';" &> /dev/null; then
            success "B-tree индекс hero_logs_context_index существует"
        else
            warning "B-tree индекс hero_logs_context_index не найден"
        fi
        
        # Проверка B-tree индекса для типа
        if PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -c "SELECT 1 FROM pg_indexes WHERE tablename = 'hero_logs' AND indexname = 'hero_logs_type_index';" &> /dev/null; then
            success "B-tree индекс hero_logs_type_index существует"
        else
            warning "B-tree индекс hero_logs_type_index не найден"
        fi
        
        # Проверка записей в таблице
        LOG_COUNT=$(PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -t -c "SELECT COUNT(*) FROM hero_logs;")
        info "Всего записей в hero_logs: $LOG_COUNT"
        
        # Проверка записей с контекстом
        NORMAL_COUNT=$(PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -t -c "SELECT COUNT(*) FROM hero_logs WHERE metadata->>'context' = 'normal';")
        SOVNGARDE_COUNT=$(PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -t -c "SELECT COUNT(*) FROM hero_logs WHERE metadata->>'context' = 'sovngarde';")
        
        info "Записей с контекстом 'normal': $NORMAL_COUNT"
        info "Записей с контекстом 'sovngarde': $SOVNGARDE_COUNT"
        
        # Проверка записей без контекста
        NO_CONTEXT_COUNT=$(PGPASSWORD="Mo90p4mo!!!" psql -h 192.168.61.86 -U godville_sk -d godville_sk -t -c "SELECT COUNT(*) FROM hero_logs WHERE metadata->>'context' IS NULL;")
        if [ "$NO_CONTEXT_COUNT" -gt 0 ]; then
            warning "Записей без контекста: $NO_CONTEXT_COUNT (старые записи)"
        else
            success "Все записи имеют контекст"
        fi
        
    else
        error "Таблица hero_logs не существует"
    fi
else
    error "Не удалось подключиться к базе данных"
    info "Проверьте параметры подключения в config/dev.exs"
fi
echo ""

# Проверка компиляции проекта
echo "8. Проверка компиляции проекта..."
echo "-----------------------------------"
if mix compile 2>&1 | grep -q "Compiled"; then
    success "Проект скомпилирован успешно"
else
    error "Ошибка компиляции проекта"
fi
echo ""

# Проверка тестов
echo "9. Проверка тестов..."
echo "-----------------------------------"
if mix test 2>&1 | grep -q "passed"; then
    success "Тесты пройдены успешно"
else
    warning "Тесты не найдены или не пройдены"
fi
echo ""

# Итоговая проверка
echo "=========================================="
echo "Итоговая проверка"
echo "=========================================="

TOTAL_CHECKS=0
PASSED_CHECKS=0

# Подсчет проверок (можно расширить)
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "lib/godville_sk/game/log_metadata.ex" ]; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if grep -q "LogMetadata.validate" lib/godville_sk/hero.ex; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if grep -q "filter_logs_by_context" lib/godville_sk_web/live/dashboard_live.ex; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

echo "Пройдено проверок: $PASSED_CHECKS из $TOTAL_CHECKS"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    success "Все основные проверки пройдены!"
    echo ""
    echo "Система готова к тестированию."
    echo "Запустите 'mix phx.server' для запуска приложения."
    echo "См. TESTING.md для детальных инструкций по тестированию."
else
    warning "Некоторые проверки не пройдены."
    echo "Пожалуйста, проверьте ошибки выше и исправьте их."
fi

echo ""
echo "=========================================="
echo "Проверка завершена"
echo "=========================================="