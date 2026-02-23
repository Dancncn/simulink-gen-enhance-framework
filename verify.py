from __future__ import annotations

import datetime as _dt
import json
import os
import subprocess
import sys
from pathlib import Path

EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_ENV = 2
EXIT_RUNTIME = 3

DEFAULT_MATLAB_EXE = r"E:\matlab R2025a\bin\matlab.exe"


def _ascii_text(value: str) -> str:
    return value.encode("ascii", "backslashreplace").decode("ascii")


def _json_ascii(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def _matlab_quote(value: str) -> str:
    return value.replace("'", "''")


def _print_status(status: str, stage: str, outdir: Path, err: str) -> None:
    outdir_abs = str(outdir.resolve())
    line = (
        f"STATUS={_ascii_text(status)} "
        f"STAGE={_ascii_text(stage)} "
        f"OUTDIR={_ascii_text(outdir_abs)} "
        f"ERR={_json_ascii(err)}"
    )
    print(line)


def _resolve_matlab_exe() -> tuple[Path, str]:
    env_val = os.environ.get("MATLAB_EXE", "").strip()
    if env_val:
        return Path(env_val), "env"
    return Path(DEFAULT_MATLAB_EXE), "default"


def main() -> int:
    project_root = Path(__file__).resolve().parent
    timestamp = _dt.datetime.now().strftime("%Y-%m-%d_%H%M%S")
    outdir = project_root / "runs" / timestamp
    outdir.mkdir(parents=True, exist_ok=True)

    matlab_stdout = outdir / "matlab_stdout.txt"
    report_path = outdir / "verify_report.json"

    matlab_exe, source = _resolve_matlab_exe()
    if source == "default" and not matlab_exe.exists():
        _print_status("fail", "env", outdir, f"MATLAB not found: {matlab_exe}")
        return EXIT_ENV
    if source == "env" and not matlab_exe.exists():
        _print_status("fail", "env", outdir, f"MATLAB_EXE not found: {matlab_exe}")
        return EXIT_ENV

    batch_cmd = (
        f"cd('{_matlab_quote(str(project_root))}'); "
        f"outDir='{_matlab_quote(str(outdir))}'; "
        "run('matlab/run_verify.m');"
    )
    cmd = [str(matlab_exe), "-logfile", str(matlab_stdout), "-batch", batch_cmd]

    try:
        subprocess.run(cmd, cwd=str(project_root), check=False)
    except OSError as exc:
        _print_status("fail", "launch", outdir, f"MATLAB launch failed: {exc}")
        return EXIT_RUNTIME

    if not report_path.exists():
        _print_status("fail", "report_missing", outdir, f"verify_report.json not found: {report_path}")
        return EXIT_RUNTIME

    try:
        report = json.loads(report_path.read_text(encoding="utf-8", errors="strict"))
    except Exception as exc:
        _print_status("fail", "report_parse", outdir, f"verify_report.json parse failed: {exc}")
        return EXIT_RUNTIME

    status = str(report.get("status", "fail")).strip().lower()
    if status not in {"pass", "fail"}:
        status = "fail"
    stage = str(report.get("fail_stage", "unknown"))

    first_error = ""
    errors = report.get("errors", [])
    if isinstance(errors, list) and errors:
        first = errors[0]
        if isinstance(first, dict):
            first_error = str(first.get("message", ""))
        else:
            first_error = str(first)

    _print_status(status, stage, outdir, first_error)
    return EXIT_PASS if status == "pass" else EXIT_FAIL


if __name__ == "__main__":
    sys.exit(main())
