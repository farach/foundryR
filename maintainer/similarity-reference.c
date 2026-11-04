/* Benchmark-only C kernel. Not compiled into or shipped with the R package. */
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <math.h>

static SEXP similarity_reference(SEXP embeddings) {
    if (TYPEOF(embeddings) != VECSXP || LENGTH(embeddings) < 2)
        error("Expected a list of at least two embeddings");
    int n = LENGTH(embeddings);
    int d = LENGTH(VECTOR_ELT(embeddings, 0));
    if (d == 0) error("Empty embedding");
    SEXP unit = PROTECT(allocMatrix(REALSXP, d, n));
    SEXP answer = PROTECT(allocMatrix(REALSXP, n, n));
    double *u = REAL(unit);
    double *out = REAL(answer);
    for (int i = 0; i < n; ++i) {
        SEXP x = VECTOR_ELT(embeddings, i);
        if (TYPEOF(x) != REALSXP || LENGTH(x) != d)
            error("Expected equal-length double vectors");
        double norm = 0;
        for (int k = 0; k < d; ++k)
            norm += REAL(x)[k] * REAL(x)[k];
        norm = sqrt(norm);
        for (int k = 0; k < d; ++k)
            u[(R_xlen_t)i * d + k] = REAL(x)[k] / norm;
    }
    for (int j = 0; j < n; ++j) {
        R_CheckUserInterrupt();
        for (int i = 0; i <= j; ++i) {
            double dot = 0;
            for (int k = 0; k < d; ++k)
                dot += u[(R_xlen_t)i * d + k] * u[(R_xlen_t)j * d + k];
            out[(R_xlen_t)j * n + i] = dot;
            out[(R_xlen_t)i * n + j] = dot;
        }
    }
    UNPROTECT(2);
    return answer;
}

static const R_CallMethodDef methods[] = {
    {"similarity_reference", (DL_FUNC) &similarity_reference, 1},
    {NULL, NULL, 0}
};

void R_init_similarity_reference(DllInfo *dll) {
    R_registerRoutines(dll, NULL, methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
