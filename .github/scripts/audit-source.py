import hashlib
import json
import sys
import tarfile
from pathlib import Path, PurePosixPath

archive = Path(sys.argv[1])
checksum_path = archive.with_suffix(archive.suffix + ".sha256")
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
if checksum_path.exists():
    expected = checksum_path.read_text(encoding="utf-8").split()[0]
    if checksum != expected:
        raise SystemExit("Source archive checksum does not match the build artifact.")
excluded = {
    ".git", ".github", ".serena", ".Renviron", ".Renviron.local",
    ".Rhistory", ".RData", "cran-comments.md", "CRAN-SUBMISSION.md",
    "SPEC-measurement-layer.md", "rollout", "sessions", "data-raw",
}
problems = []
with tarfile.open(archive, "r:gz") as source:
    members = source.getmembers()
    for member in members:
        path = PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts or path.parts[0] != "foundryR":
            problems.append(f"Unexpected archive path: {member.name}")
        if excluded.intersection(path.parts):
            problems.append(f"Excluded development file: {member.name}")
        if member.name.startswith("foundryR/tests/manual/"):
            problems.append(f"Manual API test shipped: {member.name}")
        if member.name.startswith("foundryR/vignettes/") and "/0/" in member.name:
            problems.append(f"Recorded API fixture shipped: {member.name}")
    names = {member.name for member in members}
    for obsolete in ("batch_vector.Rd", "foundry_cache_dir.Rd"):
        if f"foundryR/man/{obsolete}" in names:
            problems.append(f"Internal help page shipped: {obsolete}")
    namespace = source.extractfile("foundryR/NAMESPACE").read().decode("utf-8")
    if "export(batch_vector)" in namespace:
        problems.append("The batch_vector helper must remain internal.")
    for method in ("print", "format"):
        if f"S3method({method},foundry_codebook_diff)" not in namespace:
            problems.append(f"Missing {method} method for codebook diffs.")

if archive.stat().st_size > 5 * 1024 * 1024:
    problems.append("Source archive exceeds the 5 MB release target.")
if problems:
    raise SystemExit("\n".join(problems))

checksum_path.write_text(
    f"{checksum}  {archive.name}\n", encoding="utf-8"
)
report = {
    "archive": archive.name,
    "sha256": checksum,
    "size_bytes": archive.stat().st_size,
    "archive_entries": len(members),
    "excluded_files_absent": True,
    "internal_helpers_unexported": True,
    "codebook_diff_methods_registered": True,
}
archive.with_name("source-audit.json").write_text(
    json.dumps(report, indent=2) + "\n", encoding="utf-8"
)
print(json.dumps(report, indent=2))
