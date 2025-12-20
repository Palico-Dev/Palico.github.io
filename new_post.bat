@echo off
set /p postname="Enter post title (use-dashes-not-spaces): "

:: Create the Page Bundle (folder + index.md)
hugo new posts/%postname%/index.md

echo.
echo ------------------------------------------
echo Post created at: content/posts/%postname%/index.md
echo ------------------------------------------
echo Opening in Typora...

:: If Typora is in your PATH, this opens the file immediately
start typora content/posts/%postname%/index.md

pause