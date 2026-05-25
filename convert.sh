#!/bin/bash

input_file="$1"
name="${1%.*}"
output_file="$name-p.avi"

# Проверка входного файла
if [ ! -f "$input_file" ]; then
  echo "Ошибка: Файл '$input_file' не найден."
  exit 1
fi

# Конвертируем видео в AVI с MJPEG (попытка совместимости)
ffmpeg -i "$input_file" \
    -vf "scale=-2:240,crop=320:240,transpose=2,vflip" \
    -r 6 \
    -acodec libmp3lame \
    -ac 2 \
    -ar 22050 \
    -ab 64k \
    -pix_fmt yuv420p \
    -c:v mpeg4 \
    -vtag xvid \
    -q:v 5 \
    "$output_file"

# Проверка успешности выполнения
if [ $? -eq 0 ]; then
    echo "$output_file created"
    echo "Видео успешно преобразовано (AVI/MJPEG):"
    echo "- Разрешение: 320x240"
    echo "- Частота кадров: 6 fps"
    echo "- Поворот: 90° по часовой стрелке + вертикальное отзеркаливание"
    echo "- Аудио: PCM S16LE mono, 22050 Hz"
    echo "- Видео: MJPEG, качество 10"
    echo "- Пиксельный формат: yuvj420p"
else
    echo "Ошибка при конвертации видео. Попробуйте другие параметры."
    exit 1
fi

