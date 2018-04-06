###############################################################################################################
# Powershell Version : 5.1
# Author       :  bikobaingaru (https://github.com/bikobaingaru)
# Description  :  Powershell profile containing useful functions and commands.
###############################################################################################################

#region Aiases

Set-Alias -Name ep -Value edit-profile | Out-Null

Set-Alias -Name tch -Value Test-ConsoleHost | Out-Null

Set-Alias -Name info -Value Get-DomainInfo | Out-Null
#endregion Aliases

#region Functions

Function Get-WifiProfile { netsh wlan show profile }

Function Remove-WifiProfile ($SSID){

    (netsh wlan delete profile $SSID)
}

Function Remove-AllWifiProfiles {

    $ssid = netsh wlan show profile | Select-String 'All User Profile' | ForEach-Object {$_.Line.Substring(27)}

    ForEach($id in $ssid){
        netsh wlan delete profile $id.ToString()
    }
}

Function Get-TranscriptName {

    $invalidChars = [io.path]::GetInvalidFileNamechars()

    $date = Get-Date -format s

    "{0}.{1}.{2}.txt" -f"Powershell_Transcript",$env:COMPUTERNAME,($date.ToString() -replace "[$invalidChars]","-")
}

Function Test-ConsoleHost {

    if(($host.Name -match 'consolehost')) {$true}
    Else{$false}

}

Function Get-DomainInfo($domain){
    (whois64.exe $domain)
}

Function Edit-Profile{
            ise "<PowershellProfilePath>"
}

Function Start-JobWithNotification {
    <#
    .DESCRIPTION
    A wrapper function for the Start-Job cmdlet. Adds the capability to notify you when a long running job completes. Notifications can be either a system beep or a toast. for help with Start-Job see https://technet.microsoft.com/library/hh849698.aspx.
    
    This function should not be used in scripts or at the command line when many jobs will be created. This will overwhelm the user with too many beeps or toast messages and won't be very useful. The primary use for this is when you need to perform a long running job
    or two at the command line and you want a reminder when it completes.
    .EXAMPLE
    Start-JobWithNotification -Name NotifyJob -ScriptBlock {1..10 | foreach {Write-Host $_; start-sleep -Seconds 1}} -NotificationType Beep,toast
    Starts a job with a beep and toast notification
    .PARAMETER NotificationType
    How you would like to be notified of job completion. Accepts values 'Toast' or 'Beep', or both.
    .FORWARDHELPTARGETNAME Start-Job
    .FORWARDHELPCATEGORY Cmdlet
    
    DISCLAIMER: This script is provided 'AS IS'. It has been tested for personal use, please   
    test in a lab environment before using in a production environment.
    #>
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
     param(
         [Parameter(ParameterSetName='DefinitionName', Mandatory=$true, Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]
      $DefinitionName, 
         [Parameter(ParameterSetName='DefinitionName', Position=1)]
         [ValidateNotNullOrEmpty()]
         [string]
      $DefinitionPath, 
         [Parameter(ParameterSetName='DefinitionName', Position=2)]
         [ValidateNotNullOrEmpty()]
         [string]
      $Type, 
         [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
         [Parameter(ParameterSetName='LiteralFilePathComputerName', ValueFromPipelineByPropertyName=$true)]
         [Parameter(ParameterSetName='FilePathComputerName', ValueFromPipelineByPropertyName=$true)]
         [string]
      $Name, 
         [Parameter(ParameterSetName='ComputerName', Mandatory=$true, Position=0)]
         [Alias('Command')]
         [scriptblock]
      $ScriptBlock, 
         [Parameter(ParameterSetName='FilePathComputerName')]
         [Parameter(ParameterSetName='ComputerName')]
         [Parameter(ParameterSetName='LiteralFilePathComputerName')]
         [pscredential]
         [System.Management.Automation.CredentialAttribute()]
      $Credential, 
         [Parameter(ParameterSetName='FilePathComputerName', Mandatory=$true, Position=0)]
         [string]
      $FilePath, 
         [Parameter(ParameterSetName='LiteralFilePathComputerName', Mandatory=$true)]
         [Alias('PSPath')]
         [string]
      $LiteralPath, 
         [Parameter(ParameterSetName='FilePathComputerName')]
         [Parameter(ParameterSetName='ComputerName')]
         [Parameter(ParameterSetName='LiteralFilePathComputerName')]
         [System.Management.Automation.Runspaces.AuthenticationMechanism]
      $Authentication, 
         [Parameter(ParameterSetName='ComputerName', Position=1)]
         [Parameter(ParameterSetName='LiteralFilePathComputerName', Position=1)]
         [Parameter(ParameterSetName='FilePathComputerName', Position=1)]
         [scriptblock]
      $InitializationScript, 
         [Parameter(ParameterSetName='LiteralFilePathComputerName')]
         [Parameter(ParameterSetName='FilePathComputerName')]
         [Parameter(ParameterSetName='ComputerName')]
         [switch]
      $RunAs32, 
         [Parameter(ParameterSetName='LiteralFilePathComputerName')]
         [Parameter(ParameterSetName='FilePathComputerName')]
         [Parameter(ParameterSetName='ComputerName')]
         [ValidateNotNullOrEmpty()]
         [version]
      $PSVersion, 
         [Parameter(ParameterSetName='ComputerName', ValueFromPipeline=$true)]
         [Parameter(ParameterSetName='LiteralFilePathComputerName', ValueFromPipeline=$true)]
         [Parameter(ParameterSetName='FilePathComputerName', ValueFromPipeline=$true)]
         [psobject]
      $InputObject, 
         [Parameter(ParameterSetName='FilePathComputerName')]
         [Parameter(ParameterSetName='ComputerName')]
         [Parameter(ParameterSetName='LiteralFilePathComputerName')]
         [Alias('Args')]
         [System.Object[]]
      $ArgumentList,
    
        [ValidateSet('Toast','Beep')]
        [string[]]
      $NotificationType = 'Toast'
    ) 
     begin
     {
        function Toast {
            param (
                $Icon = "$PsScriptRoot\Powershell.ico",
                            
                [String]
                $Title = 'Powershell Job Notifier',
                          
                [String]
                $Message,
                            
                [ValidateRange(10,30)]
                [int]
                $LifeTime = 10
            )
        
            Add-Type -AssemblyName System.Windows.Forms
            $NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
            $NotifyIcon.Icon = $Icon
            $NotifyIcon.BalloonTipIcon = 'Info'
            $NotifyIcon.BalloonTipText = $Message
            $NotifyIcon.BalloonTipTitle = $Title
            $NotifyIcon.Visible = $True 
            $NotifyIcon.ShowBalloonTip(($Lifetime * 1000))
        }
                
        function Beep {
            param (
                [int]$Frequency = 440,
                [int]$Duration = 500
            )
                    
            [System.Console]::Beep($Frequency, $Duration)
        }
         try
         {
             $outBuffer = $null
             if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
             {
                 $PSBoundParameters['OutBuffer'] = 1
             }
             $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Start-Job', [System.Management.Automation.CommandTypes]::Cmdlet)
             $Action = {
                    function Toast {
                    param (
                        $Icon = "$PsScriptRoot\Powershell.ico",
                                    
                        [String]
                        $Title = 'Powershell Job Notifier',
                                  
                        [String]
                        $Message,
                                    
                        [ValidateRange(10,30)]
                        [int]
                        $LifeTime = 10
                    )
    
                    Add-Type -AssemblyName System.Windows.Forms
                    $NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
                    $NotifyIcon.Icon = $Icon
                    $NotifyIcon.BalloonTipIcon = 'Info'
                    $NotifyIcon.BalloonTipText = $Message
                    $NotifyIcon.BalloonTipTitle = $Title
                    $NotifyIcon.Visible = $True 
                    $NotifyIcon.ShowBalloonTip(($Lifetime))
                    }
                            
                    function Beep {
                        param (
                            [int]$Frequency = 440,
                            [int]$Duration = 500
                        )
                                
                        [System.Console]::Beep($Frequency, $Duration)
                    }     
                switch ($Event.MessageData)
                {
                    {$_ -contains 'Beep'}  {Beep}
                    {$_ -contains 'Toast'} {Toast -Message "Powershell Job $($Event.SourceArgs[0].Name.ToUpper()) has changed to state $($Event.SourceArgs[0].JobStateInfo.state.ToString().toupper())."}
                }
                $EventSubscriber | Unregister-Event
                $EventSubscriber.Action | Remove-Job
             }
    
             $PSBoundParameters.Remove('NotificationType') | out-null
    
             $scriptCmd =
             {
                & $wrappedCmd @PSBoundParameters |
                    ForEach-Object {
                        Register-ObjectEvent -InputObject $_ -EventName 'StateChanged' -Action $Action -MessageData $NotificationType |
                            Out-Null; $_
                    }
             }
             $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
             $steppablePipeline.Begin($PSCmdlet)
         }
         catch {throw}
     }
     
     process
     {
         try {$steppablePipeline.Process($_)} catch {throw}
     }
     
     end
     {
         try {$steppablePipeline.End()} catch {throw}
     }
    }

#endregion Functions

#region Variables

New-Variable -Name doc -Value $home\documents\WindowsPowershell\Transcripts

#endregion Variables

#region PS_Drives

Add-VSTeamAccount -Profile "set your VSTS profile" -Drive "set your drive"
New-PSDrive -Name "set your drive" -PSProvider SHiPS -Root VSTeam#VSAccount
"`n"

#endregion

#region Commands

#region Record Session History
$historyFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
Register-EngineEvent PowerShell.Exiting -Action {Get-History | Export-Clixml $historyFilePath } | Out-Null
if(Test-Path $historyFilePath) { Import-Clixml $historyFilePath | Add-History }

Set-Location c:\

If(tch) {

    Start-Transcript -Path (Join-Path -Path $doc -ChildPath $(Get-TranscriptName))

    }

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`

[Security.Principal.WindowsBuiltInRole] "Administrator"))

{

Start-JobWithNotification -Name HelpJob -ScriptBlock {Update-Help -Force} -NotificationType Beep

Start-JobWithNotification -Name AzureJob -ScriptBlock {Update-Module Azure -Verbose -Force} -NotificationType Beep

Start-JobWithNotification -Name AzureRMJob -ScriptBlock {Update-Module AzureRM -Verbose -Force} -NotificationType Beep

}

#endregion

#region Azure

Login-AzureRmAccount

$cred = Get-AzureRmSubscription

Set-AzureRmContext -TenantId $cred.TenantId -SubscriptionId $cred.SubscriptionId

### Load VSTeam module
Import-Module VSTeam

#endregion Azure

#region posh-git

### Load posh-git module
Import-Module posh-git

# posh-git background colors
$baseBackgroundColor = "DarkBlue"
$GitPromptSettings.AfterBackgroundColor = $baseBackgroundColor
$GitPromptSettings.AfterStashBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeIndexBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeStashBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchAheadStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchBehindAndAheadStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchBehindStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchGoneStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchIdenticalStatusToBackgroundColor = $baseBackgroundColor
$GitPromptSettings.DelimBackgroundColor = $baseBackgroundColor
$GitPromptSettings.IndexBackgroundColor = $baseBackgroundColor
$GitPromptSettings.ErrorBackgroundColor = $baseBackgroundColor
$GitPromptSettings.LocalDefaultStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.LocalStagedStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.LocalWorkingStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.StashBackgroundColor = $baseBackgroundColor
$GitPromptSettings.WorkingBackgroundColor = $baseBackgroundColor

# posh-git foreground colors
$GitPromptSettings.AfterForegroundColor = "Blue"
$GitPromptSettings.BeforeForegroundColor = "Blue"
$GitPromptSettings.BranchForegroundColor = "Blue"
$GitPromptSettings.BranchGoneStatusForegroundColor = "Blue"
$GitPromptSettings.BranchIdenticalStatusToForegroundColor = "White"
$GitPromptSettings.DefaultForegroundColor = "Gray"
$GitPromptSettings.DelimForegroundColor = "Blue"
$GitPromptSettings.IndexForegroundColor = "Green"
$GitPromptSettings.WorkingForegroundColor = "Yellow"

# posh-git prompt shape
$GitPromptSettings.AfterText = " "
$GitPromptSettings.BeforeText = "  "
$GitPromptSettings.BranchAheadStatusSymbol = "⬆"
$GitPromptSettings.BranchBehindStatusSymbol = "⬇"
$GitPromptSettings.BranchBehindAndAheadStatusSymbol = "⬆⬇"
$GitPromptSettings.BranchGoneStatusSymbol = ""
$GitPromptSettings.BranchIdenticalStatusToSymbol = ""
$GitPromptSettings.DelimText = " ║"
$GitPromptSettings.LocalStagedStatusSymbol = ""
$GitPromptSettings.LocalWorkingStatusSymbol = ""
$GitPromptSettings.ShowStatusWhenZero = $false

#endregion posh-git

#region Customize prompt

set-content Function:prompt {
  $title = (get-location).Path.replace($home, "~")
  $idx = $title.IndexOf("::")
  if ($idx -gt -1) { $title = $title.Substring($idx + 2) }

  $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $windowsPrincipal = new-object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity
  if ($windowsPrincipal.IsInRole("Administrators") -eq 1) { $color = "Red"; }
  else { $color = "Green"; }

  $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

  if ($LASTEXITCODE -ne 0) {
      write-host " " -NoNewLine
      write-host "  $LASTEXITCODE " -NoNewLine -BackgroundColor DarkRed -ForegroundColor Yellow
  }

  if ($PromptEnvironment -ne $null) {
      write-host " " -NoNewLine
      write-host $PromptEnvironment -NoNewLine -BackgroundColor DarkMagenta -ForegroundColor White
  }

  if (Get-GitStatus -ne $null) {
      write-host " " -NoNewLine
      Write-VcsStatus
  }

  $global:LASTEXITCODE = 0

  if ((get-location -stack).Count -gt 0) {
    write-host " " -NoNewLine
    write-host (("+" * ((get-location -stack).Count))) -NoNewLine -ForegroundColor Cyan
  }

  write-host " " -NoNewLine
  write-host "PS>" -NoNewLine -ForegroundColor $color

  $host.UI.RawUI.WindowTitle = $title
  return " "
}

#endregion Customize prompt

#endregion Commands