@echo off
rem Double-cliquer pour preparer les photos puis publier le site sur GitHub Pages.
rem Details : voir README.md, section "Mettre a jour le site en ligne".
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deployer.ps1" %*
pause
