@echo off
rem Double-cliquer pour preparer les photos puis ouvrir le site dans le navigateur, SANS le publier.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deployer.ps1" -SansDeploiement -Apercu
pause
