# Teardown for httptest2-mocked vignettes, evaluated by end_vignette() after
# mocking stops. Recording and replay leave no global state that must be undone
# here (the placeholder environment variables are process-local to the build),
# so this hook is intentionally minimal.
invisible(NULL)
