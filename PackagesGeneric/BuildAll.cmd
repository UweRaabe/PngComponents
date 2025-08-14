SETLOCAL
SET BDSVER=%~1
IF "%~1"=="" SET BDSVER=37
call "%ProgramFiles(x86)%\Embarcadero\Studio\%BDSVER%.0\bin\rsvars.bat"
msbuild "PngComponentsGroup.groupproj" /t:build /p:BuildGroup="Alles"