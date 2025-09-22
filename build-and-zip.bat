@echo off
SETLOCAL

REM Define the properties from the publish profile
SET configuration=Release
SET platform="Any CPU"
SET publishDir=publish
SET targetFramework=net8.0-windows10.0.22621.0
SET runtimeIdentifier=win-x64
SET selfContained=true

REM Set the working directory to the script's directory
SET scriptDir=%~dp0
REM Define the artifacts/output directory in the script's directory
SET artifactsDir=%scriptDir%artifacts
IF NOT EXIST "%artifactsDir%" (
    mkdir "%artifactsDir%"
)
CD /D "%scriptDir%TcUnit-Runner"

REM Path to the project file
SET projectPath=TcUnit-Runner.csproj

REM Define the path to MSBuild from the full .NET Framework
SET msbuildPath="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
REM Check if MSBuild is installed
IF NOT EXIST %msbuildPath% (
    echo MSBuild not found at %msbuildPath%. Please install Visual Studio Build Tools or update the path in this script.
    EXIT /B 1
)

REM Define the path to the 7z.exe
SET "sevenZipPath=C:\Program Files\7-Zip\7z.exe"
REM Check if 7-Zip is installed
IF NOT EXIST "%sevenZipPath%" (
    echo 7-Zip not found at "%sevenZipPath%". Please install 7-Zip or update the path in this script.
    EXIT /B 1
)

if exist "%publishDir%" (
    rmdir /s /q "%publishDir%"
)

REM Restore dependencies
echo Restoring dependencies...
%msbuildPath% "%projectPath%" /t:Restore /p:Configuration=%configuration% /p:Platform=%platform% /p:TargetFramework=%targetFramework% /p:RuntimeIdentifier=%runtimeIdentifier% /p:EnableWindowsTargeting=true
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to restore dependencies
    EXIT /B %ERRORLEVEL%
)

REM Hard-coded version string and project name
SET versionString=1.0.0
SET projName=TcUnit-Runner

echo Publishing the project with version %versionString%...
%msbuildPath% "%projectPath%" /t:Publish /p:Configuration=%configuration% /p:Platform=%platform% /p:PublishDir="%publishDir%" /p:TargetFramework=%targetFramework% /p:RuntimeIdentifier=%runtimeIdentifier% /p:SelfContained=%selfContained% /p:Version=%versionString%
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to publish the project
    EXIT /B %ERRORLEVEL%
)

REM Combine the .csproj name and version to form the zip file name
SET "zipFile=%artifactsDir%\%projName%_%versionString%.zip"


REM Check if publish directory exists and is not empty
IF NOT EXIST "%publishDir%" (
     echo ERROR: Publish directory '%publishDir%' does not exist. Nothing to zip.
     EXIT /B 1
)
DIR /B "%publishDir%\*" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
     echo ERROR: Publish directory '%publishDir%' is empty. Nothing to zip.
     EXIT /B 1
)

if exist "%zipFile%" (
     echo Removing existing .zip file
     del "%zipFile%"
)
REM Copy license and config files to publish directory
copy "%scriptDir%TcUnit-Runner\LICENSE" "%publishDir%" >nul
copy "%scriptDir%TcUnit-Runner\Beckhoff.TwinCAT.Ads_LICENSE" "%publishDir%" >nul
copy "%scriptDir%TcUnit-Runner\log4net_LICENSE-2.0" "%publishDir%" >nul
copy "%scriptDir%TcUnit-Runner\NDesk_Options_LICENSE" "%publishDir%" >nul
copy "%scriptDir%TcUnit-Runner\log4net.config" "%publishDir%" >nul

echo Zipping the published files into %zipFile%...
pushd "%publishDir%"
"%sevenZipPath%" a -tzip "%zipFile%" *
popd
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to zip the published files
    EXIT /B %ERRORLEVEL%
)

echo Build and zip process completed successfully. Output file: %zipFile%

ENDLOCAL
