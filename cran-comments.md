## Resubmission

This is a resubmission of foundryR 0.1.0, its first CRAN release. Thank you for
the manual review. The following changes address the requested corrections:

- Removed the examples and generated help page for the unexported
  `batch_vector()` helper. It remains internal. Recipe examples now call
  `recipes::prep()` and `recipes::bake()` explicitly.
- Made short, offline examples runnable, including configuration setters,
  cosine similarity on toy vectors, cache cleanup, and saving a small base64
  image. Suggested packages are guarded and examples restore session settings.
- The offline recipe-construction example uses `\donttest{}` because loading
  its optional modeling dependencies can exceed five seconds. It is also
  exercised with `--run-donttest`.
- Retained `\dontrun{}` only for examples that need Azure endpoints,
  credentials, deployed models, existing service resources, user-supplied
  media, or an installed and authenticated Azure CLI. These prerequisites
  are stated in the examples. Running these examples on CRAN would require
  private credentials and could create billable service resources.
- `codebook_diff()` now returns a classed character vector without console
  output when assigned. Dedicated `print()` and `format()` methods provide
  display and programmatic access. Other informational output uses suppressible
  messages or the existing `verbose` argument.
- File-writing examples, vignettes, and tests use temporary paths and clean up
  their output. The default embedding cache now lives under `tempdir()`;
  persistent caches require an explicitly supplied directory.
- Configuration persistence remains opt-in (`store = FALSE` by default).
  Explicit `store = TRUE` uses a small package-specific configuration file
  under `tools::R_user_dir("foundryR", "config")`, as permitted for R >= 4.0.
  Examples redirect that configuration file to a temporary path.
- Vignette replay hooks restore their environment variables, options, and
  redactor settings. Credentialed manual test scripts are excluded from the
  source package.

## Validation

The release checks cover Windows R-release, macOS R-release, and Ubuntu
R-release, R-devel, and R-oldrel-1. They include the offline unit tests and
snapshots, `R CMD check --as-cran --run-donttest`, example timing and
side-effect checks, and pkgdown rendering with local link and asset checks.

Final native check results are recorded after the release jobs complete.
The September 1 pretest results are not being reused as resubmission results.

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
