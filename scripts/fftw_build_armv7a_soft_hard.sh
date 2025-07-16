#!/bin/bash

set -e

# =============================================== #
# FFTW Cross-Compilation Script for ARMv7-A       #
# (Hard/Soft float with automated setup)          #
# =============================================== #

# Автоматизированная сборка библиотеки FFTW и бенчмарка
# - Режимы: hard float (NEON) и soft float
# - Автоматическая установка кросс-компиляторов
# - Скачивание исходников
# - Статическая линковка и вывод результата в cwd

# Требуется наличие файла 'fftw_bench.c' в рабочем каталоге

FFTW_VERSION="3.3.10"
FFTW_ARCHIVE="fftw-${FFTW_VERSION}.tar.gz"
FFTW_SRC_DIR="fftw-${FFTW_VERSION}"
BENCH_SOURCE="fftw_bench.c"

echo "=== [FFTW Cross Compilation Universal Script: ARMv7-A] ==="

# --- 1. Режим сборки ---

echo "Выберите режим сборки:"
echo "1) ARMv7-A 32-bit HARD float (arm-linux-gnueabihf + NEON, Cortex-A9 и др.)"
echo "2) ARMv7-A 32-bit SOFT float (arm-linux-gnueabi, совместимый режим под ARMv8)"

read -p "Введите 1 или 2: " mode

if [[ "$mode" == "1" ]]; then
    TARGET_TRIPLET="arm-linux-gnueabihf"
    CFLAGS="-O3 -march=armv7-a -mfpu=neon -mfloat-abi=hard"
    ENABLE_NEON="--enable-neon"
    FFTW_PREFIX="/usr/${TARGET_TRIPLET}"
    BINARY_NAME="fftw_bench_armv7a_hard_float"
    REQUIRED_PKGS=("gcc-arm-linux-gnueabihf" "g++-arm-linux-gnueabihf")
elif [[ "$mode" == "2" ]]; then
    TARGET_TRIPLET="arm-linux-gnueabi"
    CFLAGS="-O3 -march=armv7-a -mfloat-abi=soft"
    ENABLE_NEON="--disable-neon"
    FFTW_PREFIX="/usr/${TARGET_TRIPLET}"
    BINARY_NAME="fftw_bench_armv7a_soft_float"
    REQUIRED_PKGS=("gcc-arm-linux-gnueabi" "g++-arm-linux-gnueabi")
else
    echo "[ERROR] Неверный выбор. Завершение."
    exit 1
fi

# --- 2. Проверка наличия исходника ---

if [[ ! -f "$BENCH_SOURCE" ]]; then
    echo "[ERROR] Файл ${BENCH_SOURCE} не найден. Поместите его рядом со скриптом."
    exit 1
fi

# --- 3. Установка кросс-компиляторов ---

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        echo "[*] Устанавливаем ${pkg}..."
        sudo apt-get install -y "$pkg"
    fi
done

# --- 4. Скачивание архива FFTW ---

if [[ ! -f "$FFTW_ARCHIVE" ]]; then
    echo "[*] Скачиваем FFTW ${FFTW_VERSION}..."
    wget "http://www.fftw.org/${FFTW_ARCHIVE}"
else
    echo "[✓] Архив ${FFTW_ARCHIVE} уже существует."
fi

# --- 5. Распаковка исходников ---

if [[ ! -d "$FFTW_SRC_DIR" ]]; then
    echo "[*] Распаковка FFTW..."
    tar -xzf "$FFTW_ARCHIVE"
else
    echo "[✓] Директория $FFTW_SRC_DIR уже существует."
fi

# --- 6. Конфигурация и сборка библиотеки ---

cd "$FFTW_SRC_DIR"
echo "[*] Конфигурируем FFTW с нужным ABI и опциями..."

./configure \
    --host="$TARGET_TRIPLET" \
    --enable-single \
    $ENABLE_NEON \
    --with-slow-timer \
    --disable-threads \
    --enable-static \
    --disable-shared \
    --prefix="$FFTW_PREFIX" \
    CC="${TARGET_TRIPLET}-gcc" \
    CFLAGS="${CFLAGS}"

echo "[*] Собираем FFTW..."
make clean
make -j$(nproc)
sudo make install
cd ..

# --- 7. Компиляция бенчмарка ---

FFTW_INCLUDE="${FFTW_PREFIX}/include"
FFTW_LIB="${FFTW_PREFIX}/lib"

echo "[*] Компилируем бенчмарк ${BINARY_NAME}..."
${TARGET_TRIPLET}-gcc "$BENCH_SOURCE" -o "$BINARY_NAME" \
    -I${FFTW_INCLUDE} \
    ${FFTW_LIB}/libfftw3f.a -lm ${CFLAGS} -static

echo "✅ Готово: $(realpath "$BINARY_NAME")"
