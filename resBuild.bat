SET SCRIPT_DIR=%~dp0

docker pull registry.gitlab.com/edherbert/avtools/asset-builder-image:latest

::Make sure the output exists.
echo "Clearing build directory"
rmdir /S /Q "%SCRIPT_DIR%\build"
mkdir %SCRIPT_DIR%/build/assets

SET BUILD_OUTPUT="%SCRIPT_DIR%\build\assets"
SET BUILD_INPUT="%SCRIPT_DIR%\assets"
docker run -it --name asset-builder-container --rm ^
    -v "%BUILD_OUTPUT%:/buildOutput" ^
    -v "%BUILD_INPUT%:/buildInput" ^
    registry.gitlab.com/edherbert/avtools/asset-builder-image --input /buildInput --output /buildOutput %*

@REM chmod -R 777 $BUILD_OUTPUT
