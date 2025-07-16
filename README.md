# fftw-arm-cross-builds

![CI](https://github.com/plisius/fftw-arm-cross-builds/actions/workflows/ci.yml/badge.svg)

> Автоматизированная кросс-сборка библиотеки FFTW под ARMv7-A (HARD/SOFT float)
>
> 📲 Подписывайтесь на [наш Telegram-канал](https://t.me/dsp_labs) — анонсы, обсуждения, поддержка.

---

## 📦 О проекте

**fftw-arm-cross-builds** — это скрипт для автоматизированной сборки библиотеки [FFTW](http://www.fftw.org/) под архитектуру ARMv7-A.  
Сборка проходит с использованием кросс-компиляторов в среде Ubuntu, с опциями HARD и SOFT float ABI.

---

## 🧠 Что поддерживается

| Скрипт                                  | Назначение                         |
|------------------------------------------|------------------------------------|
| `scripts/fftw_build_armv7a_soft_hard.sh` | ARMv7-A с режимами HARD и SOFT float |

Требования:
- ОС: Linux (Ubuntu/Debian)
- Предустановлен `fftw_bench.c` (исходник бенчмарка)
- Права `sudo` для установки кросс-компиляторов

