###############################################################################################################
# Powershell Version : 5.1
# Author       :  bikobaingaru (https://github.com/bikobaingaru)
# Description  :  Powershell profile containing useful functions and commands.
###############################################################################################################

#region Aiases

Set-Alias -Name ep -Value edit-profile | out-null

Set-Alias -Name tch -Value Test-ConsoleHost | Out-Null
#endregion Aliases

#region Functions

Function Get-WifiProfile { netsh wlan show profile }

Function Remove-WifiProfile ($SSID){

    (netsh wlan delete profile $SSID)
}

Function Remove-AllWifiProfiles {

    $ssid = netsh wlan show profile | Select-String 'All User Profile' | ForEach {$_.Line.Substring(27)}

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