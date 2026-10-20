@echo off
rem Double-cliquer pour preparer une cle USB de publication pour le bureau.
rem Details : voir README.md, section "Cles USB du bureau".
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\preparer-cle.ps1"
pause
