git add .
if "%~1"=="" (
git commit -m "update"
) else (
git commit -m %1
)
git push