# CRAN submission runbook

Do not submit until every command below succeeds from the built source
tarball.

## 1. Prepare the release

1.  Confirm that `DESCRIPTION` has the intended version, maintainer
    address, license, URLs, and API documentation links.

2.  Confirm that `NEWS.md` describes every user-facing change.

3.  Run `git status --short` and account for every file.

4.  Regenerate documentation:

    ``` r

    devtools::document()
    ```

5.  Render `README.md` from `README.Rmd` and build all vignettes without
    credentials or live network calls.

## 2. Run package tests

Run the package tests in a clean R session:

``` r

devtools::test()
```

No test may depend on Azure credentials, a writable home directory, or
network access. Credentialed contract tests under `tests/manual/` are
separate release checks and are not part of `R CMD check`.

## 3. Build the source package

From the parent directory:

``` powershell
R CMD build foundryR --compact-vignettes=gs+qpdf
```

Inspect the generated tarball rather than checking the repository
directory. Confirm that recorded documentation fixtures, private files,
and this runbook are absent from the tarball.

## 4. Run CRAN-style checks

Check the tarball:

``` powershell
R CMD check foundryR_0.1.0.tar.gz --as-cran
```

Resolve every package-owned error and warning. Explain unavoidable notes
in `cran-comments.md`; do not claim results that were not produced from
the release tarball.

Run at least:

1.  Local Windows R release.
2.  Linux R release and R-devel through the existing GitHub Actions
    matrix.
3.  macOS R release through the existing GitHub Actions matrix.
4.  win-builder R-release and R-devel:
    <https://win-builder.r-project.org/>.
5.  R-hub checks where available: <https://r-hub.github.io/rhub/>.

## 5. Update `cran-comments.md`

Record the exact R versions and platforms tested, the final
error/warning/note counts, and whether this is a first submission or
resubmission. For a resubmission, summarize what changed in response to
CRAN feedback.

## 6. Submit

Upload the source tarball through the CRAN submission form:
<https://cran.r-project.org/submit.html>.

Use the package maintainer address from `DESCRIPTION`, confirm the
submission email promptly, and retain the submission identifier. Do not
submit a GitHub archive or the repository directory.

## 7. Respond to CRAN

1.  Reproduce any reported failure on the submitted tarball.
2.  Make the smallest package-owned correction.
3.  Re-run the complete check matrix.
4.  Update `cran-comments.md` with the resubmission response.
5.  Submit a newly built tarball with a new version when CRAN requests
    one.

## 8. After acceptance

Tag the accepted commit, create a GitHub release from that tag, rebuild
the pkgdown site, and only then add `install.packages("foundryR")` to
the README.
