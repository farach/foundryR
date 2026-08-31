## Submission

This is the first CRAN submission for foundryR.

## Test environments

- Local Windows 11 ARM64 host, x86_64 R 4.6.1
- GitHub Actions:
  - Windows x64, R-release
  - macOS ARM64, R-release
  - Ubuntu x64, R-release
  - Ubuntu x64, R-devel
  - Ubuntu x64, R-oldrel-1

## R CMD check results

0 errors | 0 warnings | 0 notes on all five GitHub Actions jobs.

## Local validation

- testthat: 0 failures, 0 warnings, 10 credential-gated skips, 965 passes
- pkgdown configuration: no problems
- URL checks: all URLs valid
- static `R CMD check --as-cran --no-install --no-manual`: no package code,
  dependency, documentation, namespace, or file-structure findings

## Local environment note

The local host cannot produce a valid full `R CMD check` result. Loading a
freshly downloaded CRAN binary of either `rlang` or `cli` alone exits the x86_64
R process with Windows status `0xC0000409` on this ARM64 machine. The same
environment-level failure terminates package installation during lazy loading.
This reproduces without loading foundryR.

The native Windows x64 GitHub Actions job completed with `Status: OK`, as did
the macOS and Linux jobs. The local emulation failure is therefore not a package
check failure.

## Method references

There are no published method references for this package. The package
provides original R wrappers around documented Microsoft Azure AI Foundry
HTTP APIs and returns results as tidy tibbles.
