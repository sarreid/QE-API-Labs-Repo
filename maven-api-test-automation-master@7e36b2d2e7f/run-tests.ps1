#!/usr/bin/env pwsh

#
# Runs tests in Karate feature files, for on how to use this script, execute the following:
#
#               get-help .\run-tests.ps1
#
# For detailed usage:
#
#               get-help .\run-tests.ps1 -detailed
#

<#
.SYNOPSIS
    Runs API tests

.DESCRIPTION
    Runs Karate based API tests and save output and HTML report to timestamp file/folder

.PARAMETER ClassPathFolder
    Loction of class path folder (where classpath:* resources reside).

.PARAMETER DefaultProfile
    Name of default profile to be specified

.PARAMETER Env
    Environment to run tests against

.PARAMETER Features
    Array of feature folders to process.

.PARAMETER HtmlSourceFolder
    Location of Karate HTML report generated.

.PARAMETER PomFile
    Location if POM file to process

.PARAMETER Profiles
    Array of POM profiles to specify

.PARAMETER Threads
    Number of threads to use when running tests in parallel

.PARAMETER AndTags
    All tags must be present (and'ed)

.PARAMETER Tags
    Array of tags to be run

.PARAMETER UnitTests
    Run Java unit tests

.PARAMETER doNotCheckEnv
    Do not check environment value, use as is.

.PARAMETER DoNotCheckFeatures
    Do not check feature folders, use as is.

.PARAMETER DoNotCheckProfiles
    Do not check profiles, use as is.

.PARAMETER doNotCheckTags
    Do not check tag values, use as is.

.PARAMETER doNotExecute
    Display Maven command line and execute.

.PARAMETER ListProfiles
    List profiles defined within POM file.

.PARAMETER NoClean
    Do not perform Maven clean phase

.PARAMETER NoNoData
    Do not ignore tests tagged with @NO-DATA

.PARAMETER NoNoDataEnv
    Do not ignore tests tagged with @NO-DATA-{env}

.PARAMETER NoDefaultProfile
    Do not specify the default profile to be used

.PARAMETER NoGitProperties
    Do not pass git related values (repository, branch, dirty)

.PARAMETER NoHostUserProperties
    Do not pass host and user related values

.PARAMETER NoHtmlReport
    Do not generated HTML report

.PARAMETER NoIgnore
    Do not ignore tests tagged with @ignore

.PARAMETER NoTests
    Do not run the tests, just compile Java & Test code

.PARAMETER PassThrough
    Additional arguments will be passed through to Maven command line

#>
[CmdletBinding(PositionalBinding=$false)]
Param (
    [parameter(Mandatory=$false)]                                       [string]    $ClassPathFolder        = './src/test/resources',
    [parameter(Mandatory=$false)]                                       [string]    $DefaultProfile         = 'tag-based-api-runner',
    [parameter(Mandatory=$false)]                                       [string]    $Env                    = 'dev',
    [parameter(Mandatory=$false)]                                       [string[]]  $Features               = @(),
    [parameter(Mandatory=$false)]                                       [string]    $GitUntrackedFiles      = 'no',
    [parameter(Mandatory=$false)]                                       [string]    $htmlSourceFolder       = './target/cucumber-html-reports',
    [parameter(Mandatory=$false)]                                       [string]    $Origin                 = 'origin',
    [parameter(Mandatory=$false)]                                       [string]    $PomFile                = './pom.xml',
    [parameter(Mandatory=$false)]                                       [string[]]  $Profiles               = @(),
    [parameter(Mandatory=$false)]                                       [string]    $ResultsFolder          = './results',
    [parameter(Mandatory=$false)]                                       [string[]]  $Tags                   = @(),
    [parameter(Mandatory=$false)][ValidateRange(1, [int]::MaxValue)]    [int]       $Threads                = 1,
    [parameter(Mandatory=$false)]                                       [switch]    $UnitTests              = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $AndTags                = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $DoNotCheckEnv          = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $DoNotCheckFeatures     = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $DoNotCheckProfiles     = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $DoNotCheckTags         = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $DoNotExecute           = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $ListProfiles           = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoClean                = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoGitProperties        = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoHostUserProperties   = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoNoData               = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoNoDataEnv            = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoDefaultProfile       = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoHtmlReport           = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoIgnore               = $false,
    [parameter(Mandatory=$false)]                                       [switch]    $NoTests                = $false,
    [parameter(Mandatory=$false, ValueFromRemainingArguments = $true)]  [string[]]  $PassThrough
)

# To debug, uncomment the following:
# Set-PSDebug -Trace 1

#
# Ensure that this scripts stops when native powershell commands fail.
# For executables, the exit code of the application should be explicitly called.
#
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

#
# Change directory to the folder containing this script
#
Push-Location $PSScriptRoot

function main() {

    if ( $ListProfiles ) {
        $profiles = getProfiles $PomFile
        if ( $profiles.count -eq 0 ) {
            Write-Host ''
            Write-Host "No profiles defined within '${pomFile}'"
            Write-Host ''
        } else {
            Write-Host ''
            Write-Host "profiles defined within '${pomFile}':"
            Write-Host ''
            ForEach ($profile in $profiles) {
                Write-Host "  '${profile}'"
            }
            Write-Host ''
        }
        return 0
    }

    $ResultsFileNameBase = 'tests'
    $COMMAND_ARGS = @()
    if ( ! ${NoClean} ) {
        $COMMAND_ARGS += @( 'clean' )
    }
    $COMMAND_ARGS += @( 'test-compile', 'surefire:test' )
    if ( ${NoTests} ) {
        $COMMAND_ARGS += @( '--define', 'skipTests' )
        $ResultsFileNameBase += '-skip-tests'
    } else {
        $addDefaultProfile = ! ${NoDefaultProfile} -and ${DefaultProfile}
        if ( ($Profiles.count -gt 0) -or $addDefaultProfile -or ${UnitTests} ) {
            # NOTE: Scoping rules prevent changes to $Profiles
            $profilesToUse = $Profiles
            if ( $UnitTests) {
                $profilesToUse += @( "unit-tests" )
            } else {
                if ( $addDefaultProfile ) {
                    $profilesToUse += @( ${DefaultProfile} )
                }
            }
            if ( ! $DoNotCheckProfiles ) {
                validateProfiles $PomFile $profilesToUse
            }
            $profiles = $profilesToUse -join ','
            $COMMAND_ARGS += ( '--activate-profiles', "${profiles}" )
        }

        if ( ${UnitTests} ) {
            $ResultsFileNameBase += "-unit-tests"
        } else {
            $ResultsFileNameBase += "-${Env}"
            if ( ! $DoNotCheckEnv ) {
                $configFile = "./src/test/resources/karate-config-${Env}.js"
                if ( ! (Test-Path $configFile -PathType Leaf) ) {
                    throw "FAIL: Environment '${Env}' is not valid as environment configuration file '${configFile}' does not exist"
                }
            }
            $COMMAND_ARGS += ( '--define', "karate.env=${Env}" )

            $COMMAND_ARGS += ( '--define', "apitest.threads=${Threads}" )

            if ( $Tags -and ($Tags.count -gt 0) ) {
                if ( ! $DoNotCheckTags ) {
                    $failed = $false
                    ForEach ($tag in $tags) {
                        if ( ! ($tag -match '^~?@') ) {
                            Write-Error "FAIL: Tag value '$tag' does not start with '@' or '~@'"
                            $failed = $true
                        }
                    }
                    if ( $failed ) {
                        throw "FAIL: One or more tags failed validation - please correct or use -DoNotCheckTagss    "
                    }
                }
                $delim = if ($andTags) { "&" } else { ',' }
                $tagsValue = $Tags -join $delim
                $COMMAND_ARGS += ( '--define', "apitest.tags=${tagsValue}" )
            }

            if ( $Features -and ($Features.count -gt 0) ) {
                $failed = $false
                if ( ! $DoNotCheckFeatures ) {
                    ForEach ($feature in $Features) {
                        $pattern = '^classpath:'
                        if ( $feature -match $pattern ) {
                            # Convert class path folder into relative folder using CLASSPATH_FOLDER
                            $folder = $feature -replace $pattern, "${ClassPathFolder}/"
                            Write-Host "INFO: Class path '${feature}' specified, checking folder '${folder}'"
                        } else {
                            $folder = ${feature}
                        }
                        if ( ! (Test-Path ${folder} -PathType Container) )  {
                            Write-Error "FAIL: Feature folder '${folder}' does not exist"
                            $failed = $true
                        }
                    }
                    if ( $failed ) {
                        throw "FAIL: One or more feature folders are invalid - please correct or use -DoNotCheckFeatures"
                    }
                }
                $featuresValue = $Features -join ','
                $COMMAND_ARGS += ( '--define', "apitest.feature.paths=$featuresValue" )
            }

            if ( $NoHtmlReport ) {
                $COMMAND_ARGS += ( '--define', 'apitest.html.report.generate=false' )
            }
            if ( $NoIgnore ) {
                $COMMAND_ARGS += ( '--define', 'apitest.ignore=false' )
            }
            if ( $NoNoData ) {
                $COMMAND_ARGS += ( '--define', 'apitest.no.data=false' )
            }
            if ( $NoNoDataEnv ) {
                $COMMAND_ARGS += ( '--define', 'apitest.no.data.env=false' )
            }
            if ( ! $NoHostUserProperties ) {
                $HostName = hostname
                if ( $HostName )  {
                    $COMMAND_ARGS += ( '--define', "apitest.host=${HostName}" )
                }
                $UserName = whoami
                if ( $UserName )  {
                    $COMMAND_ARGS += ( '--define', "apitest.user=${UserName}" )
                }
            }
            if ( ! $NoGitProperties ) {
                $GitRepositoryUrl =  git config --get "remote.${Origin}.url"
                if ( $GitRepositoryUrl ) {
                    $COMMAND_ARGS += ('--define', "apitest.git.repository.url=${GitRepositoryUrl}" )
                }
                $GitBranch = git branch --show-current
                if ( $GitBranch ) {
                    $COMMAND_ARGS+=('--define', "apitest.git.branch=${GitBranch}")
                }
                $GitCommitHash = git log -n 1 '--pretty=format:%H'
                if ( $GitCommitHash ) {
                    $COMMAND_ARGS+=('--define', "apitest.git.commit.hash=${GitCommitHash}")
                }
                [array] $GitDirty = git status --short "--untracked-files=${GitUntrackedFiles}"
                if ( $GitDirty -and ($GitDirty.count -gt 0) ) {
                    $count = $GitDirty.count
                    $COMMAND_ARGS+=('--define', "apitest.git.dirty=Uncommitted files: ${count}")
                }
            }
        }
    }
    if ( $PassThrough -and ($PassThrough.count -gt 0) ) {
        $COMMAND_ARGS += ${PassThrough}
    }

    $commandDisplay = quoteArgs mvn ${COMMAND_ARGS}

    $caption = if ( $DoNotExecute ) { "Command to be executed" } else { "Executing" }
    Write-Host ''
    Write-Host "${caption}:"
    Write-Host ''
    Write-Host $commandDisplay
    Write-Host ''

    if ( $DoNotExecute ) {
        return 0
    }

    $timestamp = Get-Date -format "yyyy-MM-dd-HH.mm.ss"
    $ResultsFileNameBase += "-${timestamp}"

    if ( ! (Test-Path ${ResultsFolder} -PathType Container) )  {
        # NOTE: Send New-Item output to /dev/null so it does not pollute the return value
        New-Item -ItemType Directory -Force -Path ${ResultsFolder} | Out-Null
    }

    $OutputFileName = "${ResultsFileNameBase}.txt"
    $OutputFile = "${ResultsFolder}/${OutputFileName}"

    $OutputFolderName = "${ResultsFileNameBase}"
    $OutputFolder = "${ResultsFolder}/${OutputFolderName}"

    Write-Host "Output written to '${OutputFile}'"
    Write-Host
    #
    # NOTE: Do not pipe output to the PowerShell console, as too much output will prevent application
    # from completing successfully.
    #
    mvn ${COMMAND_ARGS} | Out-File -Encoding utf8 ${OutputFile}
    $returnCode = $LASTEXITCODE

    Write-Host ''
    Write-Host "Output saved to '${OutputFile}'"

    Push-Location ${ResultsFolder}
    try {
        # Create tests-latest.txt which is linked to the output file in the results folder
        # NOTE: Send New-Item output to /dev/null so it does not pollute the return value
        New-Item -itemtype symboliclink -path . -Name 'tests-latest.txt' -value ${OutputFileName} -Force | Out-Null
    } catch {
        # Ignore - Windows may restrict symbolic links to admins only
    }
    Pop-Location

    if ( ! ${NoTests} -and ! ${UnitTests} ) {

        #
        # Find all occurances of the following line and total the number of failed:
        #
        # Karate version: 0.9.5
        # ======================================================
        # elapsed:  10.59 | threads:    1 | thread time: 8.31
        # features:     4 | ignored:    0 | efficiency: 0.78
        # scenarios:   24 | passed:    24 | failed: 1
        # ======================================================
        #

        [array] $failed = Select-String -Path ${OutputFile} -Pattern '^Karate version: \d+\.\d+\.\d+' -Context 0, 5 | `
                          ForEach-Object { $_.context.postContext} | `
                          Select-String -Pattern '^\s*scenarios:\s+\d+\s+\|\s+passed:\s+\d+\s+\|\s+failed:\s+(\d+)\s*$' -AllMatches | `
                          ForEach-Object { $_.Matches.Groups[1].value -as [int] }

        if ( $failed.count -eq 0 ) {
            $totalFailed = 0
        } else {
            $totalFailed = ($failed | Measure-Object -sum).Sum
        }
        if ( $totalFailed -gt 0 ) {
            Write-Host ''
            Write-Host "FAIL: Failures: ${totalFailed}"
            $returnCode=1
        }

        if ( ! ${NoHtmlReport} ) {
            Write-Host ''
            if ( Test-Path ${htmlSourceFolder} -PathType Container ) {
                # NOTE: Send New-Item output to /dev/null so it does not pollute the return value
                New-Item -ItemType Directory -Force -Path ${OutputFolder} | Out-Null

                # Copy all HTML report files
                Get-ChildItem ${htmlSourceFolder} | Copy-Item -Destination ${OutputFolder} -Recurse

                Write-Host "HTML report saved to '${OutputFolder}'"

                $htmlReports = Get-ChildItem -Path ${OutputFolder} -Recurse -Name -Filter "overview-*.html"

                Write-Host ''
                if ( $htmlReports.count -gt 0 ) {
                    Write-Host "HTML reports:"
                    ForEach ( $htmlReport in  $htmlReports ) {
                        Write-Host "  ${OutputFolder}/${htmlReport}"
                    }
                } else {
                    Write-Host 'No HTML reports available!'
                }

                Push-Location ${ResultsFolder}
                try {
                    # Create tests-latest which is linked to the output folder in the results folder
                    # NOTE: Send New-Item output to /dev/null so it does not pollute the return value
                    New-Item -itemtype symboliclink -path . -name 'tests-latest' -value ${OutputFolderName} -Force | Out-Null
                } catch {
                    # Ignore - Windows may restrict symbolic links to admins only
                }
                Pop-Location
            } else {
                Write-Host "WARN: HTML report folder '${htmlSourceFolder}' does not exist"
            }
        }
    }

    Write-Host ''

    return $returnCode
}

Function getProfiles {
    Param(
        [String]
        # Location of POM file to process
        $pomFile
    )
    <#
        .SYNOPSIS
        Given a POM file, returns array of profiles defined within it

        .INPUTS
        None. You cannot pipe objects to getProfiles

        .OUTPUTS
        System.String[]. Array of profiles defined within the POM file.
    #>

    [xml]$xml = Get-Content $pomFile
    $profiles = @()
    $xml.project.profiles.profile | ForEach-Object {
        $profiles += @( $_.id )
    }

    return $profiles;
}

Function validateProfiles {

    Param(
        [String]
        # Location of POM file to process
        $pomFile,

        [String[]]
        # List of referenced profiles to be validated
        $profiles
    )
    <#
        .SYNOPSIS
        Given a POM file, will validate that all referenced profiles are defined.
        If not, an exeption is thrown, which includes a list of the profiles which do not exist within the POM file.

        .INPUTS
        None. You cannot pipe objects to quoteArgs

        .OUTPUTS
        None.  Exception thrown if an undefined profile is referenced
    #>

    $validProfiles = getProfiles $pomFile
    $invalidProfiles = @()

    ForEach ( $profile in $profiles) {
        if ( ! $validProfiles.contains($profile) ) {
            $invalidProfiles += @( $profile )
        }
    }

    if ( $invalidProfiles.count -gt 0 ) {
        throw "FAIL: The following profiles do not exist within '${pomFile}': ${invalidProfiles}"
    }
}

Function quoteArgs {
    Param (
        [String]
        # Command to be executed
        $command,

        [String[]]
        # Arguments to be used when command is executed
        $arguments
    )
    <#
        .SYNOPSIS
        Creates a string of the command and arguments, where arguments are quoted if they contain something other than
        alphanumeric characters, minus ('-'), dot ('.') or underscore ('_').

        .INPUTS
        None. You cannot pipe objects to quoteArgs

        .OUTPUTS
        System.String. Command line which can be copied, pasted and executed.
    #>
    $Values = @( $command )
    ForEach ($argument in $arguments) {
        if ( $argument -match '[^-0-9a-zA-Z=._]' ) {
            $Values += @( ("'" + $argument + "'") )
        } else  {
            $Values += @( $argument )
        }
    }
    return $Values
}

$exitCode = main

if ( $exitCode -ne 0 ) {
    Write-Host "Exit code: ${exitCode}"
    write-Host ''
}

exit $exitCode