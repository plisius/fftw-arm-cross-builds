#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <fftw3.h>

#define MAX_SIZE 65536 // 2^16 (65K точек)

int main(int argc, char *argv[]) {
    fftwf_plan plan;
    fftwf_complex *in, *out;
    struct timespec start, end;

    if (argc < 2) {
        fprintf(stderr, "Использование: %s <iterations>\n", argv[0]);
        return 1;
    }

    int iterations = atoi(argv[1]);
    if (iterations <= 0) {
        fprintf(stderr, "Ошибка: iterations должно быть > 0\n");
        return 1;
    }

    // Генерация / загрузка wisdom-файла
    if (!fftwf_import_wisdom_from_filename("wisdom")) {
        printf("Calibrating FFTW...\n");
        fftwf_complex *tmp_in = (fftwf_complex*) fftwf_malloc(MAX_SIZE * sizeof(fftwf_complex));
        fftwf_complex *tmp_out = (fftwf_complex*) fftwf_malloc(MAX_SIZE * sizeof(fftwf_complex));
        if (!tmp_in || !tmp_out) {
            fprintf(stderr, "Ошибка выделения памяти для калибровки wisdom\n");
            return 1;
        }
        fftwf_plan plan_calib = fftwf_plan_dft_1d(MAX_SIZE, tmp_in, tmp_out, FFTW_FORWARD, FFTW_MEASURE);
        fftwf_export_wisdom_to_filename("wisdom");
        fftwf_destroy_plan(plan_calib);
        fftwf_free(tmp_in);
        fftwf_free(tmp_out);
    }

    for (int N = 16; N <= MAX_SIZE; N *= 2) {
        in = (fftwf_complex*) fftwf_malloc(N * sizeof(fftwf_complex));
        out = (fftwf_complex*) fftwf_malloc(N * sizeof(fftwf_complex));
        if (!in || !out) {
            fprintf(stderr, "Ошибка выделения памяти для N=%d\n", N);
            return 1;
        }

        plan = fftwf_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_MEASURE);

        clock_gettime(CLOCK_MONOTONIC, &start);
        for (int i = 0; i < iterations; i++) {
            fftwf_execute(plan);
        }
        clock_gettime(CLOCK_MONOTONIC, &end);

        double time = (end.tv_sec - start.tv_sec) * 1e9;
        time += (end.tv_nsec - start.tv_nsec);
        time /= iterations * 1e3; // мкс на операцию

        printf("N=%8d: %8.2f µs/FFT (iters=%d)\n", N, time, iterations);

        fftwf_destroy_plan(plan);
        fftwf_free(in);
        fftwf_free(out);
    }

    return 0;
}
