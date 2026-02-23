@echo off
setlocal EnableExtensions

cd /d "%~dp0"
set "ROOT=%CD%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "TS=%%I"
if not defined TS (
  echo Failed to generate timestamp.
  exit /b 1
)

set "OUTDIR=%ROOT%\runs\%TS%"
if not exist "%ROOT%\runs" mkdir "%ROOT%\runs"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

if defined MATLAB_EXE (
  set "MATLAB_CMD=%MATLAB_EXE%"
) else (
  set "MATLAB_CMD=matlab"
)

set "OUTDIR_M=%OUTDIR:\=/%"
set "RUN_SCRIPT_M=%ROOT:\=/%/matlab/run_verify.m"
set "MATLAB_STDOUT=%OUTDIR%\matlab_stdout.txt"

"%MATLAB_CMD%" -logfile "%MATLAB_STDOUT%" -batch "outDir='%OUTDIR_M%'; run('%RUN_SCRIPT_M%');"
set "MATLAB_EXIT=%ERRORLEVEL%"

echo outDir=%OUTDIR%
echo exit_code=%MATLAB_EXIT%

exit /b %MATLAB_EXIT%
