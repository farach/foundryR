## Update

This is an update of foundryR 0.1.0, which CRAN published on 2026-09-24.

It is submitted sooner than usual because Azure OpenAI retires `sora-2`, the
last model behind the package's video functions, on 2026-10-15 and has
announced no replacement. The video functions in 0.1.0 will fail with service
errors after that date. In this version they are defunct and raise an error
that explains why.

The update also fixes defects found after 0.1.0 was published. For example,
the conversation functions always failed with HTTP 404, and the service
rejected file uploads made with the default arguments. `NEWS.md` lists every
change. The version moves to 1.0.0 because the interface is now stable.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Validation

One source tarball, built from commit
`3ebc1fe24e731311e0487a1c1bfbda03efc46152`, was checked with
`R CMD check --as-cran --run-donttest` on GitHub Actions:

- Windows Server 2022 x64: R 4.6.1.
- macOS ARM64: R 4.6.1.
- Ubuntu 24.04 x64: R 4.6.1 with the PDF manual, R-devel (2026-09-30 r90605),
  and R 4.5.3.

The same tarball also passed win-builder on R-devel (2026-09-30 r90605) and
R 4.6.1.

Every check finished with `Status: OK`. On GitHub Actions, the tests passed
1433 expectations with no failures or warnings and skipped 10 tests that need
live Azure credentials.

CI run: <https://github.com/farach/foundryR/actions/runs/36887239480>.

## Reverse dependencies

There are no reverse dependencies on CRAN.