# CRAN submission runbook

Do not submit until every command below succeeds from the built source tarball.

## 1. Prepare the release

1. Confirm that `DESCRIPTION` has the intended version, maintainer address,
   license, URLs, and API documentation links.
2. Confirm that `NEWS.md` describes every user-facing change.
3. Run `git status --short` and account for every file.
4. Regenerate documentation:

   ```r
   devtools::document()
   ```

5. Render `README.md` from `README.Rmd` and build all vignettes without
   credentials or live network calls.
6. Check every example against the CRAN manual-review rules:
   short offline examples run normally, longer examples use `\donttest{}`,
   and `\dontrun{}` explains genuine credential/software prerequisites.
   Never enable live Azure calls merely to remove an example wrapper.

## 2. Run package tests

Run the package tests in a clean R session:

```r
devtools::test(stop_on_failure = TRUE)
```

No test may depend on Azure credentials, a writable home directory, or network
access. Credentialed contract tests under `tests/manual/` are separate release
checks and are not part of `R CMD check`.

## 3. Build the source package

From the parent directory:

```powershell
R CMD build foundryR --compact-vignettes=gs+qpdf
```

Inspect the generated tarball rather than checking the repository directory.
Confirm that recorded documentation fixtures, private files, and this runbook
are absent from the tarball.

## 4. Run CRAN-style checks

Check the tarball:

```powershell
R CMD check foundryR_0.1.0.tar.gz --as-cran
```

Also run with `--run-donttest --timings`. The `Build CRAN source` workflow
builds one archive, audits its contents, records its SHA-256 checksum, and
checks that exact archive on all five supported CI configurations. The
Ubuntu R-release job also checks the PDF manual.

Resolve every package-owned error and warning. Explain unavoidable notes in
`cran-comments.md`; do not claim results that were not produced from the release
tarball.

Run at least:

1. Local Windows R release.
2. Linux R release and R-devel through the existing GitHub Actions matrix.
3. macOS R release through the existing GitHub Actions matrix.
4. win-builder R-release and R-devel:
   <https://win-builder.r-project.org/>.
5. R-hub checks where available: <https://r-hub.github.io/rhub/>.

The example-isolation check is `.github/scripts/check-examples.R`. It records
per-topic runtimes, blocks HTTP requests, checks package-related session state,
and rejects writes to the working directory or redirected user directories.
Standard examples must finish in less than five seconds per help topic.

## 5. Update `cran-comments.md`

Record the exact R versions and platforms tested, the final error/warning/note
counts, and whether this is a first submission or resubmission. For a
resubmission, summarize what changed in response to CRAN feedback.

## 6. Submit

Upload the source tarball through the CRAN submission form:
<https://cran.r-project.org/submit.html>.

Use the package maintainer address from `DESCRIPTION`, confirm the submission
email promptly, and retain the submission identifier. Do not submit a GitHub
archive or the repository directory.

## 7. Respond to CRAN

1. Reproduce any reported failure on the submitted tarball.
2. Make the smallest package-owned correction.
3. Re-run the complete check matrix.
4. Update `cran-comments.md` with the resubmission response.
5. Submit a newly built tarball with a new version when CRAN requests one.

For the September 2026 resubmission, retain version 0.1.0: this version has not
been published, and the reviewer did not request a version bump. Include a
point-by-point response in the submission comments, then reply on the existing
review thread with `cran-submissions@r-project.org` copied. Upload only the
checked `.tar.gz`, not a GitHub ZIP or the supporting log bundle.

## 8. After acceptance

Tag the accepted commit, create a GitHub release from that tag, rebuild the
pkgdown site, and only then add `install.packages("foundryR")` to the README.
