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

All five native jobs completed with `Status: OK` (0 errors, 0 warnings, and
0 notes) on September 14, 2026 UTC:

- Windows x64: R 4.6.1.
- macOS ARM64: R 4.6.1.
- Ubuntu x64: R 4.6.1, R-devel (2026-09-12 r90533), and R 4.5.3.

Each platform's offline test run reported 988 passing expectations, no failures,
errors, or warnings, and 10 intentional live-Azure integration-test skips.
The example audit covers 107 help topics, excludes credentialed `\dontrun{}`
code, and executes the `\donttest{}` example as well. All standard examples
meet the five-second-per-topic limit without live HTTP requests or persistent
file writes.

CI run: <https://github.com/farach/foundryR/actions/runs/34792782471>.
The September 1 pretests are not being reused as resubmission results.

## Method references

There are no published method references for this package. The package
provides original R wrappers around documented Microsoft Azure AI Foundry
HTTP APIs and returns results as tidy tibbles.
