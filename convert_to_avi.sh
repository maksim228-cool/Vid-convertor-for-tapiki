#!/bin/bash

# Проверка наличия ffmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "Ошибка: ffmpeg не установлен. Выполни: pkg install ffmpeg"
    exit 1
fi

# Функция конвертации одного файла
convert_file() {
    local INPUT="$1"
    local OUTPUT="${INPUT%.*}_fixed.avi"
    
    echo "-----------------------------------------"
    echo "Конвертация: $(basename "$INPUT")"
    echo "-----------------------------------------"
    
    ffmpeg -i "$INPUT" \
        -c:v mjpeg \
        -q:v 5 \
        -r 24 \
        -vf "scale=352:288, format=yuvj420p" \
        -c:a libmp3lame \
        -b:a 192k \
        -ar 48000 \
        -ac 2 \
        -y \
        "$OUTPUT" 2>&1 | grep -E "(frame=|size=|time=|error|Error)"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ Готово: $(basename "$OUTPUT")"
        return 0
    else
        echo "❌ Ошибка: $(basename "$INPUT")"
        return 1
    fi
}

# Функция конвертации папки
convert_folder() {
    local FOLDER="$1"
    local COUNT=0
    local SUCCESS=0
    local FAILED=0
    
    echo "========================================="
    echo "Поиск видео в: $FOLDER"
    echo "========================================="
    
    # Поддерживаемые расширения
    local EXTENSIONS=("mp4" "mkv" "avi" "mov" "flv" "wmv" "webm" "3gp" "m4v" "ts")
    
    # Собираем список файлов
    local FILES=()
    for ext in "${EXTENSIONS[@]}"; do
        while IFS= read -r -d '' file; do
            # Пропускаем уже конвертированные файлы
            if [[ "$file" != *"_fixed.avi" ]]; then
                FILES+=("$file")
            fi
        done < <(find "$FOLDER" -type f -iname "*.$ext" -print0 2>/dev/null)
    done
    
    TOTAL=${#FILES[@]}
    
    if [ $TOTAL -eq 0 ]; then
        echo "Видеофайлы не найдены в указанной папке."
        return 1
    fi
    
    echo "Найдено файлов: $TOTAL"
    echo "========================================="
    
    for file in "${FILES[@]}"; do
        ((COUNT++))
        echo ""
        echo "[$COUNT/$TOTAL]"
        if convert_file "$file"; then
            ((SUCCESS++))
        else
            ((FAILED++))
        fi
    done
    
    echo ""
    echo "========================================="
    echo "Завершено!"
    echo "Успешно: $SUCCESS"
    echo "Ошибок: $FAILED"
    echo "Всего: $TOTAL"
    echo "========================================="
}

# Основная логика
if [ $# -eq 0 ]; then
    echo "Использование:"
    echo "  Один файл:   ./convert_to_avi.sh <файл>"
    echo "  Папка:       ./convert_to_avi.sh <папка>"
    echo ""
    echo "Примеры:"
    echo "  ./convert_to_avi.sh video.mp4"
    echo "  ./convert_to_avi.sh /storage/emulated/0/Download"
    exit 1
fi

TARGET="$1"

if [ ! -e "$TARGET" ]; then
    echo "Ошибка: '$TARGET' не найден"
    exit 1
fi

if [ -f "$TARGET" ]; then
    echo "========================================="
    echo "Режим: одиночный файл"
    echo "Параметры: AVI, MJPEG, 352x288, 24 fps"
    echo "========================================="
    convert_file "$TARGET"
    
elif [ -d "$TARGET" ]; then
    echo "========================================="
    echo "Режим: пакетная обработка папки"
    echo "Параметры: AVI, MJPEG, 352x288, 24 fps"
    echo "========================================="
    convert_folder "$TARGET"
    
else
    echo "Ошибка: '$TARGET' не является файлом или папкой"
    exit 1
fi
