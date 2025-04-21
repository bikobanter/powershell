###############################################################################
# Language     :  PowerShell Core
# Filename     :  Powershell_Profile.ps1
# Description  :  Powershell profile containing useful functions and commands.
# Repository   :  https://github.com/bikobanter/PowerShell
###############################################################################

#region functions
$ppFunctions = Get-ChildItem function:
function MyFunctions {
    Get-ChildItem function: | Where-Object { $ppFunctions -notcontains $_ }    
}
function Get-EnvironmentVariables{
    Get-ChildItem env:* | sort-object name
}
function Set-EnvironmentVariable{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$VariableName,
        [Parameter(Mandatory=$true)]
        [string]$VariableValue
    )
    Set-Item -Path Env:$VariableName -Value $VariableValue
}

function Get-WifiProfile { 
    netsh wlan show profile 
}
function Remove-WifiProfile {        
    param
    (
        $SSID
    )
    (netsh wlan delete profile $SSID)
}
function Remove-AllWifiProfiles {
    
function Get-AllWifiProfiles {
        param
        (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Data to process')]
            $InputObject
        )
        process {
            $InputObject.Line.Substring(27)
        }
    }

    $ssid = netsh wlan show profile | Select-String 'All User Profile' | Get-AllWifiProfiles
    
    ForEach ($id in $ssid) {
        netsh wlan delete profile $id.ToString()
    }
}
function Get-TranscriptName {

    $invalidChars = [io.path]::GetInvalidFileNamechars()

    $date = Get-Date -format s

    "{0}.{1}.{2}.txt" -f "Powershell_Transcript", $env:COMPUTERNAME, ($date.ToString() -replace "[$invalidChars]", "-")
}
function Test-ConsoleHost {
    if (($host.Name -match 'consolehost')) { $true }
    Else { $false }
}

function Edit-Profile {
    code F:\OneDrive\PowerShell\Powershell_Profile.ps1
}
function Enter-Azure {
    $space = " "
    Write-Host -Message $space
    Write-Host -Message "Attempting Azure login..."
    Write-Host -Message $space
    az login --use-device-code
}
function Find-OldDuplicateModules {
    Write-Host -Message "This will report all modules with duplicate (older and newer) versions installed"
    Write-Host -Message "Be sure to run this as an admin"
    Write-Host -Message "(You can update all your Azure modules with update-module Az -force)"

    $mods = get-installedmodule

    foreach ($Mod in $mods) {
        Write-Host -Message "Checking $($mod.name)"
        $latest = get-installedmodule $mod.name
        $specificmods = get-installedmodule $mod.name -allversions
        Write-Host -Message "$($specificmods.count) versions of this module found [ $($mod.name) ]"
    
    
        foreach ($sm in $specificmods) {
            if ($sm.version -eq $latest.version) 
            { $color = "green" }
            else
            { $color = "magenta" }
            Write-Host -Message " $($sm.name) - $($sm.version) [highest installed is $($latest.version)]"
        
        }
        Write-Host -Message "------------------------"
    }
    Write-Host -Message "done"
}
function Remove-OldDuplicateModules {
    Write-Host -Message "this will remove all old versions of installed modules"
    Write-Host -Message "be sure to run this as an admin"
    Write-Host -Message "(You can update all your Azure modules with update-module Az -force)"

    $mods = get-installedmodule

    foreach ($Mod in $mods) {
        Write-Host -Message "Checking $($mod.name)"
        $latest = get-installedmodule $mod.name
        $specificmods = get-installedmodule $mod.name -allversions
        Write-Host -Message "$($specificmods.count) versions of this module found [ $($mod.name) ]"
    
        foreach ($sm in $specificmods) {
            if ($sm.version -ne $latest.version) {
                Write-Host -Message "uninstalling $($sm.name) - $($sm.version) [latest is $($latest.version)]"
                $sm | uninstall-module -force
                Write-Host -Message "done uninstalling $($sm.name) - $($sm.version)"
                Write-Host -Message "    --------"
            }
        
        }
        Write-Host -Message "------------------------"
    }
    Write-Host -Message "done"
}
function Get-Dns {

    Write-Host -Message " "
    Write-Host -Message "Retrieving active DNS client server address.."

    $ActiveAdapter = Get-NetAdapter -Physical | Where-Object status -EQ 'up'

    Get-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.ifIndex | Format-Table -Property ifIndex, Name, ServerAddresses
}
function Set-CloudflareDNS {
    
    $NIC_PreferredDNS = "1.1.1.1"
    $NIC_AlternateDNS = "1.0.0.1"

    ## $NIC_PreferredDNS_IPV6 = "2606:4700:4700::1111"
    ## $NIC_AlternateDNS_IPV6 = "2606:4700:4700::1001"

    $ActiveAdapter = Get-NetAdapter -Physical | Where-Object status -EQ 'up'

    Write-Host -Message " "
    Write-Host -Message "Setting Cloudflare as DNS resolver..."

    Set-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.InterfaceIndex -ServerAddresses($NIC_PreferredDNS, $NIC_AlternateDNS)
    Get-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.InterfaceIndex | Format-Table -Property InterfaceIndex, InterfaceAlias, ServerAddresses
}
function Set-GoogleDNS {
    
    $NIC_PreferredDNS = "8.8.8.8"
    $NIC_AlternateDNS = "8.8.4.4"

    ## $NIC_PreferredDNS_IPV6 = "2606:4700:4700::1111"
    ## $NIC_AlternateDNS_IPV6 = "2606:4700:4700::1001"

    $ActiveAdapter = Get-NetAdapter -Physical | Where-Object status -EQ 'up'

    Write-Host -Message " "
    Write-Host -Message "Setting Google as DNS resolver..."

    Set-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.InterfaceIndex -ServerAddresses($NIC_PreferredDNS, $NIC_AlternateDNS)
    Get-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.InterfaceIndex | Format-Table -Property InterfaceIndex, InterfaceAlias, ServerAddresses
}
function Set-CustomDNS {
    # IPv4 DNS Address
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'IPv4 Address')]
        [integer]
        $NIC_PreferredDNS
    )    


    $ActiveAdapter = Get-NetAdapter -Physical | Where-Object status -EQ 'up'

    Write-Host -Message " "
        
    Set-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.InterfaceIndex -ServerAddresses($NIC_PreferredDNS)
}
function Remove-DisableAntiSpyware {
    REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware   
}
function Prompt {
    $loc = Get-Location

    $prompt = & $GitPromptScriptBlock

    if ($env:ConEmuANSI -eq "ON") {
        $prompt += "$([char]27)]9;12$([char]7)"
        if ($loc.Provider.Name -eq "FileSystem") {
            $prompt += "$([char]27)]9;9;`"$($loc.Path)`"$([char]7)"
        }
    }

    $prompt
}
function Update-DotNetTools {
    <#
      .DESCRIPTION
      Updates all installed dotnet tools.
  #>
    & 'F:\UpdateDotnetTools.ps1'
}
function Update-AzureCLI {
    Write-Host -Message " "
    Write-Host -Message "Updating Azure cli ..."

    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /passive'
}
function Optimize-PSReadLineHistory {
    <#
    .SYNOPSIS
        Optimize the PSReadline history file
    .DESCRIPTION
        The PSReadline module can maintain a persistent command-line history. However, there are no provisions for managing the file. When the file gets very large, performance starting PowerShell can be affected. This command will trim the history file to a specified length as well as removing any duplicate entries.
    .PARAMETER MaximumLineCount
    Set the maximum number of lines to store in the history file.
    .PARAMETER Passthru
    By default this command does not write anything to the pipeline. Use -Passthru to get the updated history file.
    .EXAMPLE
        PS C:\> Optimize-PSReadelineHistory
        
        Trim the PSReadlineHistory file to default maximum number of lines.
    .EXAMPLE
        PS C:\> Optimize-PSReadelineHistory -maximumlinecount 500 -passthru

            Directory: C:\Users\yourUsername\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline


            Mode                LastWriteTime         Length Name
            ----                -------------         ------ ----
            -a----        11/2/2017   8:21 AM           1171 ConsoleHost_history.txt
                    
        Trim the PSReadlineHistory file to 500 lines and display the file listing.
    .INPUTS
        None
    .OUTPUTS
       None
    .NOTES
        version 1.0
    .LINK
    Get-PSReadlineOption
    .LINK
    Set-PSReadlineOption
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline)]
        [int32]$MaximumLineCount = $MaximumHistoryCount,
        [switch]$Passthru
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $History = (Get-PSReadlineOption).HistorySavePath
    } #begin

    Process {
        if (Test-Path -path $History) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Measuring $history"
            $myHistory = Get-Content -Path $History
    
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Found $($myHistory.count) lines of history"
            $count = $myHistory.count - $MaximumLineCount
            
            if ($count -gt 0) {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Trimming $count lines to meet max of $MaximumLineCount lines"
                 $myHistory | Select-Object -skip $count -Unique  | Set-Content -Path $History
                
            }
        }
        else {
            Write-Warning "Failed to find $history"
        }

    } #process

    End {
        If ($Passthru) {
            Get-Item -Path $History
        }
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end 

} #close Name

#endregion functions

#region Aliases

$null = Set-Alias -Name ep -Value Edit-Profile

$null = Set-Alias -Name azure -Value Enter-Azure

$null = Set-Alias -Name env -Value Get-EnvironmentVariables

$null = Set-Alias -Name tch -Value Test-ConsoleHost

$null = Set-Alias -Name loc -Value Get-Location

#endregion Aliases

#region Variables

New-Variable -Name transcripts -Value $home\Documents\PowerShell\Transcripts

#endregion Variables

#region ImportModules

Import-Module powershellget
Import-Module posh-git
if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -Colors @{ InlinePrediction = '#FF7700' }
    Set-PSReadLineOption -EditMode Windows
}
Set-PSReadLineKeyHandler -Key Ctrl+Shift+b `
    -BriefDescription BuildCurrentDirectory `
    -LongDescription "dotnet Build the current directory" `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
Set-PSReadLineKeyHandler -Key Ctrl+Shift+c `
    -BriefDescription CleanCurrentDirectory `
    -LongDescription "dotnet Clean the current project" `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet clean")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
Set-PSReadLineKeyHandler -Key Ctrl+Shift+r `
    -BriefDescription BuildCurrentDirectory `
    -LongDescription "dotnet Run a project" `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet run --project src\WebApp\WebApp.csproj --property WarningLevel=0")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
Set-PSReadLineKeyHandler -Key Ctrl+Shift+x `
    -BriefDescription TestCurrentDirectory `
    -LongDescription "dotnet Test the current directory" `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet test")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Import-Module Terminal-Icons
Import-Module z
Import-Module oh-my-posh
Set-PoshPrompt -Theme blue-owl-mod

$GitPromptSettings.EnableStashStatus = $true
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
$GitPromptSettings.DefaultPromptBeforeSuffix.Text = "`n"

$DefaultUser = 'yourUsername'

#endregion ImportModules

#region COMMANDS

# Enable TLS 1.2 as default
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

#region RecordSessionHistory

$historyFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
Register-EngineEvent PowerShell.Exiting -Action { Get-History | Export-Clixml $historyFilePath } | Out-Null
if (Test-Path $historyFilePath) { Import-Clixml $historyFilePath | Add-History }

if ($env:USERNAME -like 'yourUsername') {
    Set-Location F:\
}
else {
    Set-Location C:\
}

If (tch) {
    Start-Transcript -Path (Join-Path -Path $transcripts -ChildPath $(Get-TranscriptName)) -Verbose
}

#endregion RecordSessionHistory

#PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
#endregion COMMANDS