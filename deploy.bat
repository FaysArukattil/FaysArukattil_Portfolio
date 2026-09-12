@echo off
setlocal

echo =================================================================
echo  Fays Arukattil Portfolio - One-Click Auto Deploy
echo =================================================================

set "COMMIT_MSG=%~1"
if "%COMMIT_MSG%"=="" set "COMMIT_MSG=Update portfolio content and assets"

echo [1/3] Staging changes...
git add .

echo [2/3] Committing changes: "%COMMIT_MSG%"...
git commit -m "%COMMIT_MSG%"

echo [3/3] Pushing to GitHub main branch...
git push origin main

echo.
echo =================================================================
echo  Deployment triggered successfully!
echo  GitHub Actions will now build and update your site automatically.
echo  Live URL: https://faysarukattil.github.io/FaysArukattil_Portfolio/
echo  (Please allow 2-3 minutes for the build and deployment)
echo =================================================================
