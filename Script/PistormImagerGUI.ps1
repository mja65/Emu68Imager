$Script:Version = '1.0.2'

<#PSScriptInfo
.VERSION 1.0.2
.GUID 73d9401c-ab81-4be5-a2e5-9fc0834be0fc
.AUTHOR SupremeTurnip
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI https://github.com/mja65/Emu68-Imager/blob/main/LICENSE
.PROJECTURI https://github.com/mja65/Emu68-Imager
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

<# 
.DESCRIPTION 
Script for Emu68Imager 
#> 

####################################################################### Add GUI Types ################################################################################################################

#[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

####################################################################### End GUI Types ################################################################################################################

####################################################################### Begin Function for Log     #####################################################################################################
function Write-Emu68ImagerLog {
    param (
        $StartorContinue,
        $LocationforLog,
        $DateandTime
    )

    If($StartorContinue -eq 'Start'){
        $NetFrameworkrelease = Get-ItemPropertyValue -LiteralPath 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release
        $Script:PowershellVersion = ((($PSVersionTable.PSVersion).Major).ToString()+'.'+(($PSVersionTable.PSVersion).Minor))
        $WindowsLocale = ((((Get-WinSystemLocale).Name).Tostring())+' ('+(((Get-WinSystemLocale).DisplayName).Tostring())+')')
        $WindowsVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption
        #Script:SSID = [$Script:SSID]
        #Script:WifiPassword = [$Script:WifiPassword] 
        $LogEntry =     @"
Emu68 Imager Log
        
Log created at: $DateandTime
        
Script Version: $Script:Version 
Windows Version: $WindowsVersion
Windows Locale Details: $WindowsLocale
Powershell version used is: $PowershellVersion 
.Net Framework Release installed is: $NetFrameworkrelease 
"@  
    $LogEntry| Out-File -FilePath ($LocationforLog)

    }
    If($StartorContinue -eq 'Continue'){ 
        $LogEntry =     @"

Parameters used: 

Script:HSTDiskName =  [$Script:HSTDiskName]
Script:DiskFriendlyName = [$Script:DiskFriendlyName]
Script:ScreenModetoUse = [$Script:ScreenModetoUse]
Script:ScreenModetoUseFriendlyName = [$Script:ScreenModetoUseFriendlyName]
Script:KickstartVersiontoUse = [$Script:KickstartVersiontoUse]
Script:SizeofFAT32 = [$Script:SizeofFAT32]
Script:SizeofImage = [$Script:SizeofImage]
Script:SizeofDisk = [$Script:SizeofDisk]
Script:SizeofPartition_System = [$Script:SizeofPartition_System]
Script:SizeofPartition_Other = [$Script:SizeofPartition_Other]
Script:ImageOnly = [$Script:ImageOnly]
Script:SetDiskupOnly = [$Script:SetDiskupOnly]
Script:WorkingPath = [$Script:WorkingPath]
Script:WorkingPathDefault = [$Script:WorkingPathDefault]
Script:ROMPath = [$Script:ROMPath]
Script:ADFPath = [$Script:ADFPath]
Script:LocationofImage = [$Script:LocationofImage]
Script:TransferLocation = [$Script:TransferLocation]
Script:WriteMethod = [$Script:WriteMethod]
Script:DeleteAllWorkingPathFiles = [$Script:DeleteAllWorkingPathFiles]

Activity Commences:

"@
        $LogEntry| Out-File -FilePath ($LocationforLog) -Append
    }
}
####################################################################### End Function for Log     #####################################################################################################

####################################################################### Begin function for Window State ##############################################################################################
function Set-WindowState {
    <#
    .SYNOPSIS
    Set the state of a window.
    .DESCRIPTION
    Set the state of a window using the `ShowWindowAsync` function from `user32.dll`.
    .PARAMETER InputObject
    The process object(s) to set the state of. Can be piped from `Get-Process`.
    .PARAMETER State
    The state to set the window to. Default is 'SHOW'.
    .PARAMETER SuppressErrors
    Suppress errors when the main window handle is '0'.
    .PARAMETER SetForegroundWindow
    Set the window to the foreground
    .PARAMETER ThresholdHours
    The number of hours to keep the window handle in memory. Default is 24.
    .EXAMPLE
    Get-Process notepad | Set-WindowState -State HIDE -SuppressErrors
    .EXAMPLE
    Get-Process notepad | Set-WindowState -State SHOW -SuppressErrors
    .LINK
    https://gist.github.com/lalibi/3762289efc5805f8cfcf
    .NOTES
    Original idea from https://gist.github.com/Nora-Ballard/11240204
    #>

    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object[]] $InputObject,

        [Parameter(Position = 1)]
        [ValidateSet(
            'FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
            'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
            'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL'
        )]
        [string] $State = 'SHOW',
        [switch] $SuppressErrors = $false,
        [switch] $SetForegroundWindow = $false,
        [int] $ThresholdHours = 24
    )

    Begin {
        $WindowStates = @{
            'FORCEMINIMIZE'      = 11
            'HIDE'               = 0
            'MAXIMIZE'           = 3
            'MINIMIZE'           = 6
            'RESTORE'            = 9
            'SHOW'               = 5
            'SHOWDEFAULT'        = 10
            'SHOWMAXIMIZED'      = 3
            'SHOWMINIMIZED'      = 2
            'SHOWMINNOACTIVE'    = 7
            'SHOWNA'             = 8
            'SHOWNOACTIVATE'     = 4
            'SHOWNORMAL'         = 1
        }

        $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

        $handlesFilePath = "$env:APPDATA\WindowHandles.json"

        $global:MainWindowHandles = @{}

        if (Test-Path $handlesFilePath) {
            $json = Get-Content $handlesFilePath -Raw
            $data = $json | ConvertFrom-Json
            $currentTime = Get-Date

            foreach ($key in $data.PSObject.Properties.Name) {
                $handleData = $data.$key

                if ($handleData -and $handleData.Timestamp) {
                    try {
                        $timestamp = [datetime] $handleData.Timestamp
                        if ($currentTime - $timestamp -lt (New-TimeSpan -Hours $ThresholdHours)) {
                            $global:MainWindowHandles[[int] $key] = $handleData
                        }
                    } catch {
                        Write-Verbose "Skipping invalid timestamp for handle $key"
                    }
                } else {
                    Write-Verbose "Skipping entry for handle $key due to missing data"
                }
            }
        }
    }

    Process {
        foreach ($process in $InputObject) {
            $handle = $process.MainWindowHandle

            if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($process.Id)) {
                $handle = [int] $global:MainWindowHandles[$process.Id].Handle
                $handle = [int] $global:MainWindowHandles[$process.Id].Handle
            }

            if ($handle -eq 0) {
                if (-not $SuppressErrors) {
                    Write-Error "Main Window handle is '0'"
                } else {
                    Write-Verbose ("Skipping '{0}' with id '{1}', because Main Window handle is '0'" -f $process.ProcessName, $process.Id)
                }

                continue
            }

            Write-Verbose ("Processing '{0}' with id '{1}' and handle '{2}'" -f $process.ProcessName, $process.Id, $handle)

            $global:MainWindowHandles[$process.Id] = @{
                Handle = $handle.ToString()
                Timestamp = (Get-Date).ToString("o")
            }

            $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State]) | Out-Null

            if ($SetForegroundWindow) {
                $Win32ShowWindowAsync::SetForegroundWindow($handle) | Out-Null
            }

            Write-Verbose ("» Set Window State '{1}' on '{0}'" -f $handle, $State)
        }
    }

    End {
        $data = [ordered] @{}

        foreach ($key in $global:MainWindowHandles.Keys) {
            if ($global:MainWindowHandles[$key].Handle -ne 0) {
                $data["$key"] = $global:MainWindowHandles[$key]
            }
        }

        $json = $data | ConvertTo-Json

        Set-Content -Path $handlesFilePath -Value $json
    }
}

####################################################################### End function for Window State ##############################################################################################

####################################################################### Check Runtime Environment ##################################################################################################

if ($env:TERM_PROGRAM){
    Write-Host "Run from Visual Studio Code!"
    $RunMode=0
 } 
 elseif ($psISE){
    Write-Host "Run from Powershell ISE!"
    $RunMode=0
 }
 else{
    $RunMode=1
 } 

if  ($RunMode -eq 1){
    $Script:Scriptpath = ((Split-Path -Parent -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition))+'\')      
    get-process -id $Pid | set-windowstate -State MINIMIZE
} 

if ($RunMode -eq 0){
    $Script:Scriptpath = 'E:\Emu68Imager\'    
}

$Script:LogFolder = ($Script:Scriptpath+'Logs\')
$Script:SettingsFolder = ($Script:Scriptpath+'Settings\')  

if (-not (Test-Path ($Script:LogFolder))){
    $null = New-Item ($Script:LogFolder) -ItemType Directory
}

if (-not (Test-Path ($Script:SettingsFolder))){
    $null = New-Item ($Script:SettingsFolder) -ItemType Directory
}

$Script:LogDateTime = (Get-Date -Format yyyyMMddHHmmss).tostring()
$Script:LogLocation = ($Script:LogFolder+$Script:LogDateTime+'_Emu68ImagerLog.txt')

Write-Emu68ImagerLog -StartorContinue 'Start' -LocationforLog $Script:LogLocation -DateandTime (Get-Date -Format HH:mm:ss)
####################################################################### End Check Runtime Environment ###############################################################################################


####################################################################### Null out Global Variables ###################################################################################################

$Script:ExitType = $null
$Script:HSTDiskName = $null
$Script:HSTDiskNumber = $null
$Script:HSTDiskDeviceID = $null
$Script:ScreenModetoUse = $null
$Script:ScreenModetoUseFriendlyName = $null
$Script:KickstartVersiontoUse = $null
$Script:KickstartVersiontoUseFriendlyName = $null 
$Script:SSID = $null
$Script:WifiPassword = $null
$Script:SizeofFAT32 = $null
$Script:SizeofImage = $null
$Script:SizeofImage_HST = $null
$Script:SizeofPartition_System = $null
$Script:SizeofPartition_Other = $null
$Script:WorkingPath = $null
$Script:WorkingPathDefault = $null
$Script:ROMPath = $null
$Script:ADFPath = $null
$Script:TransferLocation = $null
$Script:Space_WorkingFolderDisk = $null
$Script:AvailableSpace_WorkingFolderDisk = $null
$Script:RequiredSpace_WorkingFolderDisk = $null
$Script:AvailableSpaceFilestoTransfer = $null
$Script:SizeofFilestoTransfer = $null
$Script:SpaceThreshold_WorkingFolderDisk = $null
$Script:SpaceThreshold_FilestoTransfer = $null
$Script:Space_FilestoTransfer = $null
$Script:PFSLimit =$null
$Script:ImageOnly = $null
$Script:TotalSections = $null
$Script:CurrentSection = $null
$Script:SetDiskupOnly = $null
$Script:DeleteAllWorkingPathFiles = $null 
$Script:PartitionBarPixelperKB = $null
$Script:SizeofDisk = $null
$Script:Fat32Maximum = $null
$Script:SizeofFat32_Maximum = $null
$Script:SizeofFat32_Pixels_Maximum = $null
$Script:SizeofPartition_System_Maximum = $null
$Script:WorkbenchMaximum = $null
$Script:SizeofPartition_System_Pixels_Maximum = $null
$Script:SizeofPartition_Other_Maximum = $null
$Script:SizeofPartition_Other_Pixels_Maximum = $null
$Script:SizeofFreeSpace_Maximum = $null
$Script:SizeofFreeSpace_Pixels_Maximum = $null
$Script:SizeofFreeSpace_Pixels_Minimum = $null
$Script:SizeofUnallocated_Pixels_Maximum = $null
$Script:PartitionBarWidth = $null
$Script:SizeofFreeSpace = $null
$Script:SizeofPartition_Other_Pixels = $null
$Script:SizeofPartition_System_Pixels = $null
$Script:SizeofFat32_Pixels = $null
$Script:SizeofUnallocated_Maximum = $null
$Script:Fat32DefaultMaximum = $null
$Script:Fat32Minimum = $null
$Script:WorkbenchMinimum = $null
$Script:WorkMinimum = $null
$Script:PartitionBarKBperPixel = $null
$Script:SizeofFat32_Pixels_Minimum = $null
$Script:SizeofFreeSpace_Pixels = $null
$Script:SizeofPartition_System_Pixels_Minimum = $null
$Script:SizeofPartition_Other_Pixels_Minimum = $null
$Script:SizeofUnallocated  = $null
$Script:SizeofUnallocated_Minimum = $null
$Script:SizeofUnallocated_Pixels = $null
$Script:SizeofUnallocated_Pixels_Minimum = $null
$Script:SizeofFreeSpace_Minimum = $null
$Script:RemovableMedia = $null
$Script:WorkOverhead = $null
$Script:AmigaRDBSectors = $null
$Script:WriteMethod = $null
$Script:UserLocation_Kickstarts = $null
$Script:UserLocation_ADFs = $null
$Script:FoundKickstarttoUse = $null
$Script:AvailableADFs = $null
$Script:DiskFriendlyName = $null
$Script:IsDisclaimerAccepted = $null
$Script:IsLoadedSettings = $null
$Script:HDFImageLocation = $null

####################################################################### End Null out Global Variables ###############################################################################################

####################################################################### Set Script Path dependent  Variables ########################################################################################

$SourceProgramPath = ($Script:Scriptpath+'Programs\')
$InputFolder = ($Script:Scriptpath+'InputFiles\')
$LocationofAmigaFiles = ($Script:Scriptpath+'AmigaFiles\')
$Script:UserLocation_ADFs = ($Script:Scriptpath+'UserFiles\ADFs\')
$Script:UserLocation_Kickstarts = ($Script:Scriptpath+'UserFiles\Kickstarts\')
$Script:Documentation_URL = "https://mja65.github.io/Emu68-Imager/"
$Script:QuickStart_URL = "https://mja65.github.io/Emu68-Imager/quickstart.html"

## Amiga Variables

$DeviceName_Prefix = 'SDH'
$DeviceName_System = ($DeviceName_Prefix+'0')
$VolumeName_System ='Workbench'
$DeviceName_Other = ($DeviceName_Prefix+'1')
$VolumeName_Other = 'Work'
$MigratedFilesFolder='My Files'
#$InstallPathMUI='SYS:Programs/MUI'
#$InstallPathPicasso96='SYS:Programs/Picasso96'
#$InstallPathAmiSSL='SYS:Programs/AmiSSL'
$GlowIcons='TRUE'
$Script:PFSLimit = 101*1024*1024 #Kilobytes
$Script:Fat32DefaultMaximum = 1024*1024 #1gb in Kilobytes
#$Script:WorkbenchMaximum = 1024*1024 #1gb in Kilobytes
$Script:WorkbenchDefaultMaximum = 1024*1024 #1gb in Kilobytes
$Script:WorkbenchMaximum = $Script:PFSLimit
$Script:Fat32Maximum = 4*1024*1024 # in Kilobytes
$Script:Fat32Minimum = 35840 # In KiB
$Script:WorkbenchMinimum = 100*1024 # In KiB
$Script:WorkMinimum = 10*1024 # In KiB
$Script:HDF2emu68Path = ($SourceProgramPath+'hdf2emu68.exe')
$Script:7zipPath = ($SourceProgramPath+'7z.exe')
$Script:DDTCPath = ($SourceProgramPath+'ddtc.exe')
$Script:FindFreeSpacePath = ($SourceProgramPath+'FindFreeSpace.exe')
$Script:FindLockPath = ($SourceProgramPath+'FindLock.exe')
$Script:AmigaRDBSectors = 2015 #Standard number of sectors at 512bytes per sector 
$Script:AmigaBlockSize = 512


$UnLZXURL='http://aminet.net/util/arc/W95unlzx.lha'
$HSTImagerreleases = 'https://api.github.com/repos/henrikstengaard/hst-imager/releases'
$HSTAmigareleases= 'https://api.github.com/repos/henrikstengaard/hst-amiga/releases'
$Emu68releases = 'https://api.github.com/repos/michalsc/Emu68/releases'
$Emu68Toolsreleases = 'https://api.github.com/repos/michalsc/Emu68-tools/releases'

####################################################################### End Set Script Variables ###############################################################################################

######################################################################### Create User Files Folders ###############################################################################################
$Script:UserLocation_ADFs = ($Script:Scriptpath+'UserFiles\ADFs\')
$Script:UserLocation_Kickstarts = ($Script:Scriptpath+'UserFiles\Kickstarts\')

if (-not (Test-Path $Script:UserLocation_ADFs)){
    $null= New-Item -Path $Script:UserLocation_ADFs -ItemType Directory -Force
} 

if (-not (Test-Path $Script:UserLocation_Kickstarts)){
    $null= New-Item -Path $Script:UserLocation_Kickstarts -ItemType Directory -Force
} 

######################################################################### End User Files Folders ###############################################################################################

######################################################################## Functions #################################################################################################################
function Test-ExistenceofFiles {
    param (
        $PathtoTest,
        $PathType
    )
    if (-not (Test-Path $PathtoTest)){
        if ($PathType -eq 'Folder'){
            $PathtoTesttoreport = $PathtoTest
        }
        if ($PathType -eq 'File'){
            $PathtoTesttoreport = Split-Path -Path $PathtoTest -Leaf
        }
        $Message = "$PathType $PathtoTesttoreport `n`n"
        return $Message 
    }
    else{
        return
    }
}

function Set-GUISizeofPartitions {
    param (
    
    )
    $Script:SizeofFAT32_Pixels = [decimal]$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
    $Script:SizeofPartition_System_Pixels = [decimal]$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
    $Script:SizeofPartition_Other_Pixels = [decimal]$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
    $Script:SizeofFreeSpace_Pixels = [decimal]$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
    $Script:SizeofUnallocated_Pixels = [decimal]$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value 
    
    $Overhead_FAT32 = (($Script:SizeofFAT32_Pixels*$Script:PartitionBarKBperPixel)-[math]::floor($Script:SizeofFAT32_Pixels*$Script:PartitionBarKBperPixel))
    $Overhead_System = (($Script:SizeofPartition_System_Pixels*$Script:PartitionBarKBperPixel)-[math]::floor($Script:SizeofPartition_System_Pixels*$Script:PartitionBarKBperPixel))
    $Overhead_Other = (($Script:SizeofPartition_Other_Pixels*$Script:PartitionBarKBperPixel)-[math]::floor($Script:SizeofPartition_Other_Pixels*$Script:PartitionBarKBperPixel))
    $Overhead_FreeSpace = (($Script:SizeofFreeSpace_Pixels*$Script:PartitionBarKBperPixel)-[math]::floor($Script:SizeofFreeSpace_Pixels*$Script:PartitionBarKBperPixel))
    #$Overhead_Unallocated = (($Script:SizeofUnallocated_Pixels*$Script:PartitionBarKBperPixel)-[math]::floor($Script:Sizeofunallocated_Pixels*$Script:PartitionBarKBperPixel))
    $Overhead = $Overhead_FAT32 + $Overhead_System + $Overhead_Other + $Overhead_FreeSpace
    
    $Script:SizeofFAT32 = [math]::floor($Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel)
    $Script:SizeofPartition_System  = [math]::floor($Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel)  
    $Script:SizeofPartition_Other = [math]::floor($Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel)
    $Script:SizeofFreeSpace  = [math]::floor($Script:SizeofFreeSpace_Pixels * $Script:PartitionBarKBperPixel)
    $Script:SizeofUnallocated = ($Script:SizeofUnallocated_Pixels * $Script:PartitionBarKBperPixel)+$Overhead       
    $Script:SizeofImage = $Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other + $Script:SizeofFreeSpace      

    if ($Script:SizeofPartition_Other -ge $Script:PFSLimit){
        $TotalNumberWorkPartitions = [math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)
        $WPF_UI_WorkSizeNote_Label.Text='*'
        $WPF_UI_WorkSizeNoteFooter_Label.Text=('* Due to PFS limitations, Work will be split into '+$TotalNumberWorkPartitions+' partitions of equal size')
    }
    else{
        $WPF_UI_WorkSizeNote_Label.Text=''
        $WPF_UI_WorkSizeNoteFooter_Label.Text='' 
    }

}     
                                                                                    
function GuiValueIsNumber {
    param (
        $ValuetoCheck
    )

    $Startingpointforendcheck = (($ValuetoCheck.Text).Length)-1
    if (($ValuetoCheck.Text -match "^[\d\.]+$") -and (($ValuetoCheck.Text).substring($Startingpointforendcheck,1) -match "^[0-9]")){
        $ValuetoCheck.Background = 'White'
        return $true

    }
    else {
        $ValuetoCheck.Background = 'Red'
        return $false
    }
}

function GuiValueIsSame {
    param (
        $ValuetoCheck,
        $ValuetoCheckAgainst
    )

    if ($ValuetoCheck.Text -eq $ValuetoCheckAgainst){
        $ValuetoCheck.Background = 'White'
        return $true

    }
    else {
        $ValuetoCheck.Background = 'Red'
        return $false
    }
}

function Set-GUIPartitionValues {
    param (
        
    )
    $Script:WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofPartition_System -Scale 'GiB'
    if ($Script:WPF_UI_WorkbenchSize_Value.Text -eq 0){
        $Script:UI_WorkbenchSize_Value = 0
    }
    else {
        $Script:UI_WorkbenchSize_Value = $WPF_UI_WorkbenchSize_Value.Text
    }
    $Script:WPF_UI_WorkbenchSize_Value.Background = 'White'
    
    $Script:WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofPartition_Other -Scale 'GiB'
    if ($Script:WPF_UI_WorkSize_Value.Text -eq 0){
        $Script:UI_WorkSize_Value = 0
    }
    else{
        $Script:UI_WorkSize_Value = $WPF_UI_WorkSize_Value.Text
    }
    $Script:WPF_UI_WorkSize_Value.Background = 'White'
    
    $Script:WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofImage -Scale 'GiB'
    if ($Script:WPF_UI_ImageSize_Value.Text -eq 0){
        $Script:UI_ImageSize_Value = 0
    }
    else{
        $Script:UI_ImageSize_Value = $Script:WPF_UI_ImageSize_Value.Text
    }
    $Script:WPF_UI_ImageSize_Value.Background = 'White'
    
    $Script:WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofFAT32 -Scale 'GiB'
    if ($Script:WPF_UI_FAT32Size_Value.Text -eq 0){
        $Script:UI_FAT32Size_Value = 0    
    }
    else {
        $Script:UI_FAT32Size_Value = $Script:WPF_UI_FAT32Size_Value.Text
    }
    $Script:WPF_UI_Fat32Size_Value.Background = 'White'
    
    $Script:WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofFreeSpace -Scale 'GiB'
    if ($Script:WPF_UI_FreeSpace_Value.Text -eq 0){
        $Script:UI_FreeSpace_Value = 0
    }
    else{
        $Script:UI_FreeSpace_Value = $Script:WPF_UI_FreeSpaceSize_Value.Text
    }        
    $Script:WPF_UI_FreeSpace_Value.Background = 'White'
    
    $Script:WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofUnallocated -Scale 'GiB'
    
    if ($Script:WPF_UI_Unallocated_Value.Text -eq 0){
        $Script:UI_Unallocated_Value = 0
    }
    else{
        $Script:UI_Unallocated_Value = $WPF_UI_Unallocated_Value.Text      
    }    
}
function Set-PartitionMaximums {
    param (     
        $Type
    )
       
    if (($Script:SizeofDisk-$Script:SizeofPartition_System-$Script:SizeofPartition_Other) -le $Script:Fat32Maximum) {
        $Script:SizeofFat32_Maximum = ($Script:SizeofDisk-$Script:SizeofPartition_System-$Script:SizeofPartition_Other) 
    }
    else{
        $Script:SizeofFat32_Maximum = $Script:Fat32Maximum
    }
    $Script:SizeofFat32_Pixels_Maximum = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofFat32_Maximum)
    
    if (($Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_Other) -le $Script:WorkbenchMaximum) {
        $Script:SizeofPartition_System_Maximum = [decimal](($Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_Other))
    }
    else {
        $Script:SizeofPartition_System_Maximum = $Script:WorkbenchMaximum
    }
    $Script:SizeofPartition_System_Pixels_Maximum = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofPartition_System_Maximum)
    
    $Script:SizeofPartition_Other_Maximum = $Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_System
    $Script:SizeofPartition_Other_Pixels_Maximum = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofPartition_Other_Maximum)

    $Script:SizeofFreeSpace_Maximum = $Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_System-$Script:SizeofPartition_Other
    $Script:SizeofFreeSpace_Pixels_Maximum = [decimal](($Script:SizeofDisk * $Script:PartitionBarPixelperKB) - (($Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other)* $Script:PartitionBarPixelperKB)) 
 
    $Script:SizeofUnallocated_Pixels_Maximum = [decimal]($Script:PartitionBarWidth - (($Script:SizeofFreeSpace + $Script:SizeofPartition_Other_Pixels + $Script:SizeofPartition_System_Pixels + $Script:SizeofFat32_Pixels) * $Script:PartitionBarPixelperKB))
    $Script:SizeofUnallocated_Maximum =  [decimal]($Script:SizeofDisk - $Script:SizeofFreeSpace - $Script:SizeofPartition_Other - $Script:SizeofPartition_System - $Script:SizeofFAT32)
}

function Get-FormattedPathforGUI {
    param (
        $PathtoTruncate,
        $Length
    )
    if ($Length){
        $LengthofString = $Length
    }
    else{
        $LengthofString = 37 #Maximum supported by label less three for the ...
    }
    if ($PathtoTruncate.Length -gt $LengthofString){
        $Output = ('...'+($PathtoTruncate.Substring($PathtoTruncate.Length -$LengthofString,$LengthofString)))
    }
    else{
        $Output = $PathtoTruncate
    }
    return $Output
}

function Get-TransferredFilesSpaceRequired {
    param (
        $FoldertoCheck
    )
    
    $SizeofFiles = (Get-ChildItem $FoldertoCheck -force -Recurse | Where-Object { $_.PSIsContainer -eq $false }  | Measure-Object -property Length -sum).sum/1Kb
    return $SizeofFiles #In Kilobytes
}

function Get-RoundedDiskSize {
    param (
        $Size,
        $Scale
    )
    if ($Scale -eq 'GiB'){
        $RoundedSize = ([math]::truncate(($Size/1024/1024)*1000)/1000)
        
    }
    if (($RoundedSize -le 0) -and ($RoundedSize -ge -0.01)){
        $RoundedSize = 0
    }
    return $RoundedSize
}

function Get-FormattedSize {
    param (
        $Size #In Kilobytes
    )
        
    if ($Size -eq 0){
        $ReportedSize = (0).ToString()+' KiB'
    }
    elseif ([Math]::Abs($Size) -le 1024){ #Kilobytes
        $ReportedSize = [math]::Round($Size,2).ToString()+' KiB'
    } 
    elseif (([Math]::Abs($Size) -gt 1024) -and ([Math]::Abs($Size) -le 1024*1024)){
        $ReportedSize = [math]::Round($Size/1024,2).ToString()+' MiB'
    }
    else{
        $ReportedSize = [math]::Round($Size/1024/1024,2).ToString()+' GiB'
    }
    return $ReportedSize
}

function Get-AmigaPartitionList {
    param (
        $SizeofPartition_System_param,
        $SizeofPartition_Other_param,
        $VolumeName_System_param,
        $DeviceName_System_param,
        $PFSLimit,
        $VolumeName_Other_param,
        $DeviceName_Other_param,
        $DeviceName_Prefix_param  
    )
    
    $AmigaPartitionsList = [System.Collections.Generic.List[PSCustomObject]]::New()

    $StartCylinder = 0
    $CurrentCylinder = $StartCylinder
    
    $StartOffset = 0
    $CurrentOffset = $StartOffset 

    $NumberofCylinders_RDB = 2
    $Size_RDB = $NumberofCylinders_RDB*(Get-AmigaPartitionSizeBlockBytes)

    $NumberofCylinders_System = [math]::Floor($SizeofPartition_System_param*1024/(Get-AmigaPartitionSizeBlockBytes))-1
    $Size_System = ($NumberofCylinders_System * (Get-AmigaPartitionSizeBlockBytes))/1024

    $NumberofCylinders_Other = [math]::Floor($SizeofPartition_Other_param*1024/(Get-AmigaPartitionSizeBlockBytes))-1

    
    # Add RDB

    $AmigaPartitionsList += [PSCustomObject]@{
        Type = 'Partition Table'
        PartitionNumber = 0
        NumberofCylinders = $NumberofCylinders_RDB
        SizeofPartition = $Size_RDB
        SizeofPartition_HST = $Size_RDB.ToString()+'kb'
        StartCylinder = $CurrentCylinder 
        EndCylinder = $CurrentCylinder+$NumberofCylinders_RDB-1 
        StartOffset = $CurrentOffset
        EndOffset = $CurrentOffset+$Size_RDB-1
        StartSector = 0
        EndSector = $CurrentOffset+$Size_RDB/512
        DosType = ''
        VolumeName = ''
        DeviceName = ''  
    }

    $PartitionNumbertoPopulate ++
    $CurrentOffset = $CurrentOffset+$Size_RDB
    $CurrentCylinder = $CurrentCylinder+$NumberofCylinders_RDB

    # Add Workbench

    $AmigaPartitionsList += [PSCustomObject]@{
        Type = 'Partition Table'
        PartitionNumber = $PartitionNumbertoPopulate
        NumberofCylinders = $NumberofCylinders_System
        SizeofPartition = $Size_System
        SizeofPartition_HST = $Size_System.ToString()+'kb'
        StartCylinder = $CurrentCylinder 
        EndCylinder = $CurrentCylinder+$NumberofCylinders_System-1 
        StartOffset = $CurrentOffset
        EndOffset = ($CurrentOffset+($Size_System*1024))-1
        StartSector = $CurrentOffset/512
        EndSector = ($CurrentOffset+($Size_System*1024))/512
        DosType = 'PFS3'
        VolumeName = $VolumeName_System_param
        DeviceName = $DeviceName_System_param 
    }

    $PartitionNumbertoPopulate ++
    $CurrentOffset = $CurrentOffset+($Size_System*1024)
    $CurrentCylinder = $CurrentCylinder+$NumberofCylinders_System

     $CapacitytoFill = $SizeofPartition_Other_param
     $TotalNumberWorkPartitions = [math]::ceiling($CapacitytoFill/$PFSLimit)
     $NumberofCylinders_Other  = ([math]::Floor($NumberofCylinders_Other/$TotalNumberWorkPartitions))  
     $Size_Other = ($NumberofCylinders_Other * (Get-AmigaPartitionSizeBlockBytes))/1024

     $WorkPartitionCounter = 0 
     $WorkNameCounter = 1 

     do {
        if ($WorkPartitionCounter -eq 0){
            $VolumeNametoPopulate = $VolumeName_Other_param  
            $DeviceNametoPopulate = $DeviceName_Other_param  
        }
        else{
            $VolumeNametoPopulate = ($VolumeName_Other_param+$WorkNameCounter).ToString()
            $DeviceNametoPopulate = ($DeviceName_Prefix_param+(($PartitionNumbertoPopulate-1).ToString()))
            $WorkNameCounter ++
           
        }

        $AmigaPartitionsList += [PSCustomObject]@{
            Type = 'Partition Table'
            PartitionNumber = $PartitionNumbertoPopulate
            NumberofCylinders = $NumberofCylinders_Other
            SizeofPartition = $Size_Other
            SizeofPartition_HST = $Size_Other.ToString()+'kb'
            StartCylinder = $CurrentCylinder 
            EndCylinder = $CurrentCylinder+$NumberofCylinders_Other-1 
            StartOffset = $CurrentOffset
            EndOffset = ($CurrentOffset+($Size_Other*1024))-1
            StartSector = $CurrentOffset/512
            EndSector = ($CurrentOffset+($Size_Other*1024))/512
            DosType = 'PFS3'
            VolumeName = $VolumeNametoPopulate
            DeviceName = $DeviceNametoPopulate 
        }

        $CurrentOffset = $CurrentOffset+($Size_Other*1024)
        $CurrentCylinder = $CurrentCylinder+$NumberofCylinders_Other

        $PartitionNumbertoPopulate ++
        $WorkPartitionCounter ++
    } until (
        $WorkPartitionCounter -eq  $TotalNumberWorkPartitions
    )

    return $AmigaPartitionsList
}

function Get-RequiredSpace {
    param (
        $ImageSize
    )    
    $SpaceNeeded = ($ImageSize) #Image
    if ($Script:SetDiskupOnly -ne 'TRUE'){
        $SpaceNeeded +=
        (10*1024) + ` #FAT32 Files
        (23*1024) + ` # AmigaImageFiles
        (40*1024) + ` # AmigaDownloads
        (190*1024) + ` # Programs Folder
        (80*1024)   # TempFolder
    }
    return $SpaceNeeded # In Kilobytes
}

function Write-StartTaskMessage {
    param (
        $Message
    )
    Write-Host ''
    Write-Host "[Section: $Script:CurrentSection of $Script:TotalSections]: `t $Message" -ForegroundColor White
    Write-Host ''
    '' | Out-File $Script:LogLocation -Append
    "[Section: $Script:CurrentSection of $Script:TotalSections]: `t $Message" | Out-File $Script:LogLocation -Append
    '' | Out-File $Script:LogLocation -Append
}

function Write-StartSubTaskMessage {
    param (
        $SubtaskNumber,
        $TotalSubtasks,
        $Message
    )
    Write-Host ''
    Write-Host "[Subtask: $SubtaskNumber of $TotalSubtasks]: `t $Message" -ForegroundColor White
    Write-Host ''
    '' | Out-File $Script:LogLocation -Append
    "[Subtask: $SubtaskNumber of $TotalSubtasks]: `t $Message" | Out-File $Script:LogLocation -Append
    '' | Out-File $Script:LogLocation -Append
}

function Write-InformationMessage {
    param (
        $Message,
        [switch]$NoLog
    )
    Write-Host " `t $Message" -ForegroundColor Yellow
    if (-not $NoLog){
        $Message | Out-File $Script:LogLocation -Append
    }
}

function Write-ErrorMessage {
    param (
        $Message,
        [switch]$NoLog
    )
    Write-Host "[ERROR] `t $Message" -ForegroundColor Red
    if (-not $NoLog){
        "[ERROR] `t $Message" | Out-File $Script:LogLocation -Append
    }
}

function Write-TaskCompleteMessage {
    param (
        $Message
    )
    Write-Host "[Section: $Script:CurrentSection of $Script:TotalSections]: `t $Message" -ForegroundColor Green
    "[Section: $Script:CurrentSection of $Script:TotalSections]: `t $Message" | Out-File $Script:LogLocation -Append
    $Script:CurrentSection ++
}


function Read-XAML {
    param (
        $xaml
    )
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    try{
        $Form=[Windows.Markup.XamlReader]::Load( $reader )
    }
    catch{
        Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
        throw
    }
    return $Form
}
function Format-XMLtoXAML{
    param (
        $inputXML 
    )
    $inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
    [xml]$XAML = $inputXML
    return $XAML
}

Function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function Confirm-DiskSpace {
    param (
        $PathtoCheck
    )
    if ($PathtoCheck){
        return (Get-Volume -DriveLetter ((Split-Path -Qualifier $PathtoCheck).Replace(':',''))).SizeRemaining
    }
}

function Confirm-UIFields {
    param (
        
    )
    $NumberofErrors = 0
    $ErrorMessage = $null
     
    if (-not($Script:HSTDiskName)){
        $ErrorMessage += 'You have not selected a disk'+"`n`n"
        $NumberofErrors += 1
    }
    if (-not($WPF_UI_KickstartVersion_Dropdown.SelectedItem)) {
        $ErrorMessage += 'You have not populated a Kickstart version'+"`n`n"
        $NumberofErrors += 1
    }
    If ($Script:ROMPath){
        if ($Script:ROMPath -eq $Script:UserLocation_Kickstarts){
            $WPF_UI_RomPath_Label.Text = 'Using default Kickstart folder'
            $WPF_UI_RomPath_Button.Foreground = 'Black'
            $WPF_UI_RomPath_Button.Background = '#FFDDDDDD'
        }
        else{
            $WPF_UI_RomPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:ROMPath)
            $WPF_UI_RomPath_Button.Background = 'Green'
            $WPF_UI_RomPath_Button.Foreground = 'White'
        }
        if (-not ($Script:FoundKickstarttoUse.KickstartPath)){
            $ErrorMessage += 'A Kickstart file has not been located'+"`n`n"
            $WPF_UI_Rompath_Button_Check.Background = '#FFDDDDDD'
            $WPF_UI_Rompath_Button_Check.Foreground = 'Black'
            $NumberofErrors += 1
        }
        else{
            $WPF_UI_ROMpath_Button_Check.Background = 'Green'
            $WPF_UI_ROMpath_Button_Check.Foreground = 'White'
        }
    }
    else{
        $ErrorMessage += 'You have not populated a Kickstart Path'+"`n`n"
        $NumberofErrors += 1
    }
    if (-not($WPF_UI_ScreenMode_Dropdown.SelectedItem)) {
        $ErrorMessage += 'You have not populated a sceenmode'+"`n`n"
        $NumberofErrors += 1
    }
    if ((-not($Script:ADFPath)) -and ($Script:SetDiskupOnly -ne 'TRUE')) {
        $ErrorMessage += 'You have not populated an ADF Path'+"`n`n"
        $NumberofErrors += 1
    }
    if ($Script:ADFPath -eq  $Script:UserLocation_ADFs){
        $WPF_UI_ADFPath_Label.Text = 'Using default ADF folder'
        $WPF_UI_ADFPath_Button.Foreground = 'Black'
        $WPF_UI_ADFPath_Button.Background = '#FFDDDDDD'       
        $WPF_UI_ADFpath_Button_Check.Background = '#FFDDDDDD'
        $WPF_UI_ADFpath_Button_Check.Foreground = 'Black'
    }
    else{
        $WPF_UI_ADFPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:ADFPath)
        $WPF_UI_ADFPath_Button.Background = 'Green'
        $WPF_UI_ADFPath_Button.Foreground = 'White'
    }
    if (-not ($Script:AvailableADFs | where-object IsMatched -eq 'TRUE') -or ($Script:AvailableADFs | where-object IsMatched -eq 'FALSE')){ 
        $WPF_UI_ADFpath_Button_Check.Background = '#FFDDDDDD'
        $WPF_UI_ADFpath_Button_Check.Foreground = 'Black'
        if ($Script:SetDiskupOnly -ne 'TRUE'){
            $ErrorMessage += 'All the required ADFs have not been located'+"`n"
            $NumberofErrors += 1
        }
    }
    else {
        $WPF_UI_ADFpath_Button_Check.Background = 'Green'
        $WPF_UI_ADFpath_Button_Check.Foreground = 'White'
    }
    If ($Script:WorkingPathDefault -eq $True){
        $WPF_UI_Workingpath_Label.Text = 'Using default Working folder'
        $WPF_UI_Workingpath_Button.Background = '#FFDDDDDD'
        $WPF_UI_Workingpath_Button.Foreground = 'Black'
    }
    If ($Script:WorkingPathDefault -eq $false){
        $WPF_UI_Workingpath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:WorkingPath) 
        $WPF_UI_Workingpath_Button.Background = 'Green'
        $WPF_UI_Workingpath_Button.Foreground = 'White'
    }
    if ($Script:TransferLocation){
        $WPF_UI_MigratedFiles_Button.Content = 'Click to remove Transfer Folder'
        $WPF_UI_MigratedFiles_Button.Background = 'Green'
        $WPF_UI_MigratedFiles_Button.Foreground = 'White'
        $WPF_UI_MigratedPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:TransferLocation) 
        $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:SizeofFilestoTransfer
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        if (($Script:AvailableSpaceFilestoTransfer) -lt $Script:SpaceThreshold_FilestoTransfer){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Red"
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Foreground = "Black"
            $NumberofErrors += 1
        }
        elseif (($Script:AvailableSpaceFilestoTransfer) -lt ($Script:SpaceThreshold_FilestoTransfer*2)){
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Yellow"
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Foreground = "Black"
        }
        else{
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Green"
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Foreground = "White"
        }
    }
    else{
        $WPF_UI_MigratedFiles_Button.Content = 'Click to set Transfer folder'    
        $WPF_UI_MigratedFiles_Button.Background = '#FFDDDDDD'
        $WPF_UI_MigratedFiles_Button.Foreground = 'Black'
        $WPF_UI_MigratedPath_Label.Text='No transfer path selected'       
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = '' 
        $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = '' 
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Transparent"
    }
    
    $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk 
    
    if($Script:HSTDiskName){
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        if ($Script:AvailableSpace_WorkingFolderDisk -le $Script:SpaceThreshold_WorkingFolderDisk){
            $WPF_UI_AvailableSpaceValue_TextBox.Background = "Red"
            $WPF_UI_AvailableSpaceValue_TextBox.Foreground = "Black"
            $WPF_UI_RequiredSpaceMessage_TextBox.Text = "Insufficient space to run tool! You will be prompted to select a new drive and folder from which to run the tool."
            $WPF_UI_RequiredSpaceMessage_TextBox.Foreground = "Red"
        }
        else{
            if ($Script:AvailableSpace_WorkingFolderDisk -le ($Script:SpaceThreshold_WorkingFolderDisk*2)){
                $WPF_UI_AvailableSpaceValue_TextBox.Background = "Yellow"
                $WPF_UI_AvailableSpaceValue_TextBox.Foreground = "Black"
                $WPF_UI_RequiredSpaceMessage_TextBox.Text = ""
        
            }
            else{
                $WPF_UI_AvailableSpaceValue_TextBox.Background = "Green"
                $WPF_UI_AvailableSpaceValue_TextBox.Foreground = "White"
                $WPF_UI_RequiredSpaceMessage_TextBox.Text = ""
            }
        }
    }
    
    if ($Script:SetDiskupOnly -eq 'TRUE'){
        $WPF_UI_WIfiSettings_Label.Visibility = 'Hidden'
        $WPF_UI_Password_Label.Visibility = 'Hidden'
        $WPF_UI_Password_Textbox.Visibility = 'Hidden'
        $WPF_UI_SSID_Label.Visibility = 'Hidden'
        $WPF_UI_SSID_Textbox.Visibility = 'Hidden'
        $WPF_UI_SetUpDiskOnly_CheckBox.IsChecked = 'TRUE'   
        $WPF_UI_MigratedFiles_Button.Visibility = 'Hidden'
        $WPF_UI_MigratedPath_Label.Visibility = 'Hidden'
        $WPF_UI_MigratedFiles_Button.IsEnabled = ""
        $WPF_UI_ADFpath_Button.Visibility = 'Hidden'
        $WPF_UI_ADFPath_Label.Visibility = 'Hidden'
        $WPF_UI_ADFPath_Button.IsEnabled = ""
        $WPF_UI_ADFpath_Button_Check.IsEnabled = ""
        $WPF_UI_ADFpath_Button_Check.Visibility = 'Hidden'
        $WPF_UI_RequiredSpaceTransferredFiles_TextBox.Visibility = 'Hidden'
        $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Visibility = 'Hidden'
        $WPF_UI_AvailableSpaceTransferredFiles_TextBox.Visibility = 'Hidden'
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Visibility = 'Hidden'
    }
    elseif ($Script:SetDiskupOnly -eq 'FALSE'){
        $WPF_UI_WIfiSettings_Label.Visibility = 'Visible'
        $WPF_UI_Password_Label.Visibility = 'Visible'
        $WPF_UI_Password_Textbox.Visibility = 'Visible'
        $WPF_UI_SSID_Label.Visibility = 'Visible'
        $WPF_UI_SSID_Textbox.Visibility = 'Visible'
        $WPF_UI_SetUpDiskOnly_CheckBox.IsChecked = '' 
        $WPF_UI_MigratedFiles_Button.IsEnabled = "TRUE"
        $WPF_UI_MigratedFiles_Button.Visibility = 'Visible'
        $WPF_UI_MigratedPath_Label.Visibility = 'Visible'
        $WPF_UI_ADFPath_Button.IsEnabled = "TRUE"
        $WPF_UI_ADFPath_Button.Visibility = 'Visible'
        $WPF_UI_ADFPath_Label.Visibility = 'Visible'
        $WPF_UI_ADFpath_Button_Check.IsEnabled = "TRUE"
        $WPF_UI_ADFpath_Button_Check.Visibility = 'Visible'
        $WPF_UI_RequiredSpaceTransferredFiles_TextBox.Visibility = 'Visible'
        $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Visibility = 'Visible'
        $WPF_UI_AvailableSpaceTransferredFiles_TextBox.Visibility = 'Visible'
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Visibility = 'Visible'
    }
    if ($Script:ImageOnly -eq 'TRUE'){
        $WPF_UI_ImageOnly_CheckBox.IsChecked = 'TRUE'
    }
    else{
        $WPF_UI_ImageOnly_CheckBox.IsChecked = ''
    }
    if ($Script:WriteMethod -eq 'SkipEmptySpace'){
        $WPF_UI_SkipEmptySpace_CheckBox.IsChecked = 'TRUE'
    }
    elseif ($Script:WriteMethod -eq 'Normal'){
        $WPF_UI_SkipEmptySpace_CheckBox.IsChecked = ''
    }
    if ($Script:DeleteAllWorkingPathFiles -eq 'TRUE'){
        $WPF_UI_DeleteFiles_CheckBox.IsChecked = 'TRUE'
    }
    else{
        $WPF_UI_DeleteFiles_CheckBox.IsChecked = ''
    }
    if ($NumberofErrors -gt 0){
        $WPF_UI_Start_Button.Background = 'Red'
        $WPF_UI_Start_Button.Foreground = 'Black'
        $WPF_UI_Start_Button.Content = 'Missing information and/or insufficient space on Work partition for transferred files! Press button to see further details'
        return $ErrorMessage
    }
    else{
        if (-not (Confirm-FreeSpacetoRunTool)){
            $WPF_UI_Start_Button.Background = 'Yellow'
            $WPF_UI_Start_Button.Foreground = 'Black'
            $WPF_UI_Start_Button.Content = 'Run Tool (with prompt for new drive and folder from which to run the tool)'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
            $WPF_UI_Start_Button.Foreground = 'White'
            $WPF_UI_Start_Button.Content = 'Run Tool'
        }
        return
    }    
}
       
function Confirm-FreeSpacetoRunTool {
    param (
        
    )
    if (($Script:RequiredSpace_WorkingFolderDisk -ne 0) -and ($Script:AvailableSpace_WorkingFolderDisk -ge $Script:SpaceThreshold_WorkingFolderDisk)){
        return $true
    } 
    else{
        return $false
    }
}

Function Get-FormVariables{
    if ($Script:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$Script:ReadmeDisplay=$true}
#    write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable WPF*
}


function Read-SettingsFile {
    param (
        $SettingsFile
    )
    $Msg_Header ='No SD Card Available'   
    $Msg_Body = @"
SD card is not available! Settings relating to partition sizes have not been loaded.

"@    

    $Msg_Header_WorkingPath ='Working Folder Not Available'   
    $Msg_Body_WorkingPath = @"
Working Folder is not available! If you have insufficient space you will need to set 
the working Folder again when you run the tool.

"@    
    $Msg_Header_NonEmpty = 'Non Empty Folder'
    $Msg_Body_NonEmpty = @"
The Working Folder is not empty! Working Folder will revert to the default.
"@  
    
$SettingstoRead = (
'HSTDiskName',
'ScreenModetoUse',
'ScreenModetoUseFriendlyName',
'KickstartVersiontoUse',
'KickstartVersiontoUseFriendlyName',
'SSID',
'WifiPassword',
'SizeofFAT32',
'SizeofImage',
'SizeofDisk',
'SizeofPartition_System',
'SizeofPartition_Other',
'ImageOnly',
'SetDiskupOnly',
'DeleteAllWorkingPathFiles',
'WorkingPath',
'WorkingPathDefault',
'HSTDiskNumber',
'HSTDiskDeviceID',
'SizeofUnallocated',
'SizeofFreeSpace',
'ROMPath',
'ADFPath',
'TransferLocation',
'WriteMethod',
'DiskFriendlyName',
'WorkbenchMaximum',
'Fat32Maximum')

    $HashTableforSettings  = @{} # Clear Hash
    #$Script:SettingsFile = 'E:\Emu68Imager\Settings\test5.e68'

    Import-Csv $Script:SettingsFile -Delimiter ';' -Header @("Setting", "Value") | Select-Object -Skip 2 | ForEach-Object {
        $HashTableforSettings[$_.Setting] = @($_.Value)

    }

    #$LoadedSettingsFile = Import-Csv $Script:SettingsFile -Delimiter ';' -Header @("Setting", "Value") | Select-Object -Skip 2
    
    $WPF_UI_MediaSelect_DropDown.SelectedItem = $null
    $Script:Disk = $null 
    $Script:SizeofFat32_Pixels = $null     
    $Script:SizeofFreeSpace_Pixels_Maximum = $null    
    $Script:SizeofPartition_Other_Maximum = $null      
    $Script:ListofPackagestoInstall = $null    
    $Script:PartitionBarKBperPixel = $null    
    $Script:PartitionBarPixelperKB = $null  
    $Script:HSTDiskName = $null 
    $Script:ScreenModetoUse = $null 
    $Script:ScreenModetoUseFriendlyName = $null
    $Script:KickstartVersiontoUse = $null 
    $Script:KickstartVersiontoUseFriendlyName = $null
    $Script:SSID = $null
    $Script:WifiPassword = $null 
    $Script:SizeofFAT32 = $null
    $Script:SizeofImage = $null
    $Script:SizeofDisk = $null 
    $Script:SizeofPartition_System = $null
    $Script:SizeofPartition_Other = $null 
    $Script:ImageOnly = $null 
    $Script:SetDiskupOnly = $null
    $Script:WorkingPath = $null 
    $Script:WorkingPathDefault = $null 
    $Script:HSTDiskNumber = $null 
    $Script:HSTDiskDeviceID = $null 
    $Script:SizeofUnallocated = $null
    $Script:SizeofFreeSpace = $null
    $Script:ROMPath = $null 
    $Script:ADFPath = $null 
    $Script:TransferLocation = $null
    $Script:WriteMethod = $null
    $Script:DiskFriendlyName = $null        
    $Script:WorkbenchMaximum = $null               
    $Script:SpaceThreshold_FilestoTransfer = $null 
    $Script:Fat32Maximum = $null                     
    $Script:FoundKickstarttoUse = $null
    $Script:AvailableADFs = $null 
    
    $Script:Space_FilestoTransfer = $null            
    $Script:Space_WorkingFolderDisk = $null        
   
    foreach ($Setting in $SettingstoRead){
        If ($HashTableforSettings.ContainsKey($Setting)){
            if (Test-Path ('variable:Script:'+($Setting))){
                Remove-Variable -Scope Script -Name $Setting
            }
            New-Variable -Scope Script -Name $Setting -Value $HashTableforSettings.($Setting)[0]
        }
    }

    $OtherSettings =  $LoadedSettingsFile | Where-Object {$_.Setting -ne 'AvailableADFs' -and $_.Setting -ne 'FoundKickstarttoUse' } 
    foreach ($Setting in $OtherSettings){
        if (Test-Path ('variable:Script:'+($Setting.Setting))){
            Remove-Variable -Scope Script -Name $Setting.Setting
        }
        New-Variable -Scope Script -Name $Setting.Setting -Value $Setting.Value
    } 
   # Write-Host "SizeofFAT32:  After Load $Script:SizeofFAT32"
   
    # Convert Numeric Variables to Numeric
    
    $Script:SizeofFAT32 = [int]$Script:SizeofFAT32
    $Script:SizeofImage = [int]$Script:SizeofImage
    $Script:SizeofDisk = [decimal]$Script:SizeofDisk
    $Script:SizeofPartition_System = [int]$Script:SizeofPartition_System
    $Script:SizeofPartition_Other = [int]$Script:SizeofPartition_Other
    $Script:SizeofUnallocated = [int]$Script:SizeofUnallocated 
    $Script:SizeofFreeSpace = [int]$Script:SizeofFreeSpace 
    
   #  Write-Host "SizeofFAT32: After Numeric $Script:SizeofFAT32"
    # Write-Host "$Script:SizeofImage"

    $DiskFound = $false
    $DiskstoCheck = Get-RemovableMedia
    foreach ($Disk in $DiskstoCheck){
        if (($Disk.HSTDiskName -eq $Script:HSTDiskName) -and (([decimal]($Disk.SizeofDisk)) -eq $Script:SizeofDisk)) {
            $DiskFound = $true
            $Script:IsLoadedSettings = $true
            break
        }   
    }       
    
  #   Write-Host "SizeofFAT32:  After Disk $Script:SizeofFAT32"
   #  Write-Host "$Script:SizeofImage"
   #  Write-Host "Load Settings: $Script:IsLoadedSettings"

    if ($DiskFound -eq $false){
        $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,48)
        $Script:HSTDiskName = $null
        $Script:HSTDiskDeviceID = $null
        $Script:HSTDiskNumber = $null
        $Script:SizeofFAT32 = 0
        $Script:SizeofImage = 0
        $Script:SizeofDisk = 0
        $Script:SizeofPartition_System = 0
        $Script:SizeofPartition_Other = 0
        $Script:SizeofUnallocated = 0
        $Script:SizeofFreeSpace = 0
    }
    else{
        $Script:PartitionBarPixelperKB = [decimal](($PartitionBarWidth)/$Script:SizeofDisk)
        $Script:PartitionBarKBperPixel = [decimal]($Script:SizeofDisk /($PartitionBarWidth))
        $Script:SizeofFAT32_Pixels = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofFAT32)   
        $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB)
        $Script:SizeofPartition_Other_Pixels = [decimal]($Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB)
        $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
        $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 1    
        ## New Start
        $WPF_UI_FAT32_Splitter.IsEnabled = "True"
        $WPF_UI_Workbench_Splitter.IsEnabled = "True"
        $WPF_UI_Work_Splitter.IsEnabled = "True"
        $WPF_UI_Image_Splitter.IsEnabled = "True"
        $WPF_UI_WorkbenchSize_Value.IsEnabled = "True"
        $WPF_UI_WorkSize_Value.IsEnabled = "True"
        $WPF_UI_ImageSize_Value.IsEnabled = "True"
        $WPF_UI_FAT32Size_Value.IsEnabled = "True"
        $WPF_UI_FreeSpace_Value.IsEnabled = "True"
        Set-PartitionMaximums

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels

        $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck  $Script:WorkingPath)/1Kb 
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }

        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
              
        Set-GUIPartitionValues
    
        $null = Confirm-UIFields
        ## New End
    }

 #    Write-Host "SizeofFAT32:  After Sizing in GUI  $Script:SizeofFAT32"
   #   Write-Host "$Script:SizeofImage"
   #        Write-Host "Load Settings: $Script:IsLoadedSettings"

    if ($Script:WorkingPath){
        if (-not (Test-Path ($Script:WorkingPath))){
            $null = [System.Windows.MessageBox]::Show($Msg_Body_WorkingPath, $Msg_Header_WorkingPath,0,48)
            $Script:WorkingPath = ($Script:Scriptpath+'Working Folder\')
            $Script:WorkingPathDefault = $true   
        }  
        elseif ($Script:WorkingPath -eq ($Script:Scriptpath+'Working Folder\')){
            $Script:WorkingPathDefault = $true  
        }      
        else{
            $items = Get-ChildItem -Path $WorkingPath -Recurse -Force | Where-Object {$_.Name -ne 'AmigaDownloads' -and $_.Name -ne 'AmigaImageFiles' -and $_.Name -ne 'FAT32Partition' -and $_.Name -ne 'HDFImage' -and $_.Name -ne 'OutputImage' -and $_.Name -ne 'Programs' -and $_.Name -ne 'Temp'}
            if ($items.Count -eq 0){
                $Script:WorkingPathDefault = $false

            }
            else{
                $null= [System.Windows.MessageBox]::Show($Msg_Body_NonEmpty, $Msg_Header_NonEmpty,0,48)
                $Script:WorkingPath = ($Script:Scriptpath+'Working Folder\')
                $Script:WorkingPathDefault = $true   
            }
        }
    }
    else{
        $Script:WorkingPath = ($Script:Scriptpath+'Working Folder\')
        $Script:WorkingPathDefault = $true 
             Write-Host "Load Settings: $Script:IsLoadedSettings"
    }

   #  Write-Host "SizeofFAT32:  After Working Path $Script:SizeofFAT32"
   #   Write-Host "$Script:SizeofImage"
     
    $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Script:WorkingPath)/1Kb 
    $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
    $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk

    if ($Script:TransferLocation){
        $Script:SizeofFilestoTransfer = Get-TransferredFilesSpaceRequired -FoldertoCheck $Script:TransferLocation
        if ($Script:HSTDiskName){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
            $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)      
        }
        else{
            $Script:Space_FilestoTransfer = 0
            $Script:SpaceThreshold_FilestoTransfer = 0
        }
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer
    }
    else{
        $Script:SizeofFilestoTransfer = 0
    }
 }

function Write-SettingsFile {
    param (
        $SettingsFile
    )

    'Do not edit this file! It will break Emu68 Imager! You have been warned!' | Out-File $SettingsFile
    'Setting;Value' | Out-File $SettingsFile -Append  
    ('HSTDiskName;'+$Script:HSTDiskName) | Out-File $SettingsFile -Append
    ('ScreenModetoUse;'+$Script:ScreenModetoUse) | Out-File $SettingsFile -Append
    ('ScreenModetoUseFriendlyName;'+$Script:ScreenModetoUseFriendlyName) | Out-File $SettingsFile -Append
    ('KickstartVersiontoUse;'+$Script:KickstartVersiontoUse) | Out-File $SettingsFile -Append
    ('KickstartVersiontoUseFriendlyName;'+$Script:KickstartVersiontoUseFriendlyName) | Out-File $SettingsFile -Append
    ('SSID;'+$Script:SSID) | Out-File $SettingsFile -Append
    ('WifiPassword;'+$Script:WifiPassword) | Out-File $SettingsFile -Append
    ('SizeofFAT32;'+$Script:SizeofFAT32) | Out-File $SettingsFile -Append
    ('SizeofImage;'+$Script:SizeofImage) | Out-File $SettingsFile -Append
    ('SizeofDisk;'+$Script:SizeofDisk) | Out-File $SettingsFile -Append
    ('SizeofPartition_System;'+$Script:SizeofPartition_System) | Out-File $SettingsFile -Append
    ('SizeofPartition_Other;'+$Script:SizeofPartition_Other) | Out-File $SettingsFile -Append
    ('ImageOnly;'+$Script:ImageOnly) | Out-File $SettingsFile -Append
    ('SetDiskupOnly;'+$Script:SetDiskupOnly) | Out-File $SettingsFile -Append
    ('DeleteAllWorkingPathFiles;'+$Script:DeleteAllWorkingPathFiles) | Out-File $SettingsFile -Append
    ('WorkingPath;'+$Script:WorkingPath) | Out-File $SettingsFile -Append
    ('WorkingPathDefault;'+$Script:WorkingPathDefault) | Out-File $SettingsFile -Append
    ('HSTDiskNumber;'+$Script:HSTDiskNumber) | Out-File $SettingsFile -Append
    ('HSTDiskDeviceID;'+$Script:HSTDiskDeviceID) | Out-File $SettingsFile -Append
    ('SizeofUnallocated;'+$Script:SizeofUnallocated) | Out-File $SettingsFile -Append
    ('SizeofFreeSpace;'+$Script:SizeofFreeSpace) | Out-File $SettingsFile -Append
    ('ROMPath;'+$Script:ROMPath) | Out-File $SettingsFile -Append
    ('ADFPath;'+$Script:ADFPath) | Out-File $SettingsFile -Append
    ('TransferLocation;'+$Script:TransferLocation) | Out-File $SettingsFile -Append
    ('WriteMethod;'+$Script:WriteMethod) | Out-File $SettingsFile -Append
    ('DiskFriendlyName;'+$Script:DiskFriendlyName) | Out-File $SettingsFile -Append        
    ('WorkbenchMaximum;'+$Script:WorkbenchMaximum) | Out-File $SettingsFile -Append                
    ('Fat32Maximum;'+$Script:Fat32Maximum) | Out-File $SettingsFile -Append                
}

function Get-SettingsLoadPath {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        InitialDirectory = $Script:SettingsFolder 
        DefaultExt = '.ini'
        Filter = "Emu68 Imager Settings Files (.e68)|*.e68" # Filter files by extension
        Title = 'Load your Settings File'
        FileName =''
    }
    #[Environment]::GetFolderPath('Desktop') 
    $result = $dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if ($result -eq 'OK'){
        return $dialog.FileName
    }
    else {
        return
    }
}

function Get-SettingsSavePath {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.SaveFileDialog -Property @{ 
        InitialDirectory = $Script:SettingsFolder 
        DefaultExt = '.ini'
        Filter = "Emu68 Imager Settings Files (.e68)|*.e68" # Filter files by extension
        Title = 'Save your Settings File'
        FileName =''
    }
    #[Environment]::GetFolderPath('Desktop') 
    $result = $dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if ($result -eq 'OK'){
        return $dialog.FileName
    }
    else {
        return
    }
}

function Get-FolderPath {
    param (
        $InitialDirectory,
        $RootFolder,
        $Message,
        [switch]$ShowNewFolderButton
    )

    if ($Script:PowershellVersion -gt 7){
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $Message
        $dialog.ShowNewFolderButton = if ($ShowNewFolderButton) { $true } else { $false }
        if ($Script:PowershellVersion -gt 7){
            $dialog.UseDescriptionForTitle = 'TRUE'
            if ($selectedPath){
                $dialog.InitialDirectory = $InitialDirectory.TrimEnd('\')
            }
            else{
                if ($selectedPath){
                    $dialog.SelectedPath = $InitialDirectory.TrimEnd('\')
                }
            }
        }
        if ($RootFolder){
            $dialog.RootFolder = $RootFolder
        }
        #[Environment]::GetFolderPath('Desktop') 
        $result = $dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
        if ($result -eq 'OK'){
            return $dialog.SelectedPath
        }
        else {
            return
        }
    }
    else{
        $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
        $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.AddExtension = $false
        $OpenFileDialog.CheckFileExists = $false
        $OpenFileDialog.DereferenceLinks = $true
        $OpenFileDialog.Filter = "Folders|`n"
        $OpenFileDialog.Multiselect = $false
        $OpenFileDialog.Title = $Message
        $OpenFileDialog.InitialDirectory = $InitialDirectory       
        $OpenFileDialogType = $OpenFileDialog.GetType()
        $FileDialogInterfaceType = $Assembly.GetType('System.Windows.Forms.FileDialogNative+IFileDialog')
        $IFileDialog = $OpenFileDialogType.GetMethod('CreateVistaDialog',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$null)
        $null = $OpenFileDialogType.GetMethod('OnBeforeVistaDialog',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$IFileDialog)
        [uint32]$PickFoldersOption = $Assembly.GetType('System.Windows.Forms.FileDialogNative+FOS').GetField('FOS_PICKFOLDERS').GetValue($null)
        $FolderOptions = $OpenFileDialogType.GetMethod('get_Options',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$null) -bor $PickFoldersOption
        $null = $FileDialogInterfaceType.GetMethod('SetOptions',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$FolderOptions)
        $VistaDialogEvent = [System.Activator]::CreateInstance($AssemblyFullName,'System.Windows.Forms.FileDialog+VistaDialogEvents',$false,0,$null,$OpenFileDialog,$null,$null).Unwrap()
        [uint32]$AdviceCookie = 0
        $AdvisoryParameters = @($VistaDialogEvent,$AdviceCookie)
        $AdviseResult = $FileDialogInterfaceType.GetMethod('Advise',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$AdvisoryParameters)
        $AdviceCookie = $AdvisoryParameters[1]
        $Result = $FileDialogInterfaceType.GetMethod('Show',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,[System.IntPtr]::Zero)
        $null = $FileDialogInterfaceType.GetMethod('Unadvise',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$AdviceCookie)
        if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
            $FileDialogInterfaceType.GetMethod('GetResult',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$null)
        }
        if($OpenFileDialog.FileName){
            return $OpenFileDialog.FileName
        }
        else{
            return
        }
    }
}
    
function Get-RemovableMedia {
    param (
    )
    $RemovableMediaList = [System.Collections.Generic.List[PSCustomObject]]::New()
    Get-WmiObject Win32_DiskDrive | Where-Object {$_.MediaType -eq "Removable Media"} | ForEach-Object {
        $DriveStartpoint = $_.DeviceID.IndexOf('DRIVE')+5 # 5 is length of 'Drive'
        $DriveEndpoint = $_.DeviceID.Length
        $DriveLength = $DriveEndpoint- $DriveStartpoint
        $DriveNumber = $_.DeviceID.Substring($DriveStartpoint,$DriveLength)
        $SizeofDiskwithBuffer=($_.Size)-(3076*1024) 
        $RemovableMediaList += [PSCustomObject]@{
            DeviceID = $_.DeviceID
            Model = $_.Model
            SizeofDisk = $SizeofDiskwithBuffer/1024 # KiB
            EnglishSize = ([math]::Round($SizeofDiskwithBuffer/1GB,3).ToString())
            FriendlyName = 'Disk '+$DriveNumber+' '+$_.Model+' '+([math]::Round($SizeofDiskwithBuffer/1GB,3).ToString()+' GiB') 
            HSTDiskName = ('\disk'+$DriveNumber)
            HSTDiskNumber = $DriveNumber
            DeviceisScriptRunDevice = ''
        }
    
    }

    $ScriptDriveLetter = $Script:Scriptpath.substring(($Script:Scriptpath.IndexOf(':\'))-1,1)
    
    foreach ($RemovableMediaItem in $RemovableMediaList) {    
        $DriveNumber = $RemovableMediaItem.DeviceID.Substring($DriveStartpoint,$DriveLength)
        Get-Disk -Number $DriveNumber | Get-Partition | ForEach-Object {
            If ($_.DriveLetter -eq $ScriptDriveLetter){
                $RemovableMediaItem.DeviceisScriptRunDevice = 'TRUE'            
            } 
        }    
    
    }

    return ($RemovableMediaList | Where-Object {$_.DeviceisScriptRunDevice -ne "TRUE"})
}

  

function Compare-FileHash {
    param (
        $FiletoCheck,
        $HashtoCheck
    )
    Write-InformationMessage -Message ('Checking hash for file: '+$FiletoCheck)
    $HashChecked = Get-FileHash $FiletoCheck -Algorithm MD5
    $HashtoReport=$HashChecked.Hash
    if ($HashChecked.Hash -eq $HashtoCheck) {
        Write-InformationMessage -Message "Hash of file matches!"
        return $true
    } 
    else{
        Write-ErrorMessage -Message ('Hash mismatch! Hash expected was: '+$HashtoCheck+' Hash found was: '+$HashtoReport)
        return $false
    }
        
}
function Expand-Zipfiles {
    param (
        $InputFile,
        $OutputDirectory,
        $FiletoExtract,
        $SevenzipPathtouse,
        $TempFoldertouse
    )
    Write-InformationMessage -Message ('Extracting from: '+$InputFile)
    & $SevenzipPathtouse x ('-o'+$OutputDirectory) $InputFile $FiletoExtract -y >($TempFoldertouse+'LogOutputTemp.txt')
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMessage -Message ('Error extracting '+$InputFile+'! Cannot continue!')
        return $false    
    }
    else {
        return $true
    }
}
function Expand-LZXArchive {
    param (
        $LZXFile,
        $DestinationPath,
        $TempFoldertouse,
        $WorkingFoldertouse,
        $LZXPathtouse
    )
    Write-InformationMessage -Message ('Extracting file '+$LZXFile)
    if (-not(Test-Path $DestinationPath)){
       $null= New-Item $DestinationPath -ItemType Directory
    }
    Set-Location $DestinationPath
    & $LZXPathtouse $LZXFile >($TempFoldertouse+'LogOutputTemp.txt')
    Set-Location $WorkingFoldertouse
}
function Get-AmigaFileWeb {
    param (
        $URL,
        $NameofDL,
        $LocationforDL
    )
    Write-InformationMessage -Message ('Downloading file '+$NameofDL)
    if (([System.Uri]$URL).host -eq 'aminet.net'){
        $AminetMirrors =  Import-Csv ($InputFolder+'AminetMirrors.csv') -Delimiter ';'
        foreach ($Mirror in $AminetMirrors){
            Write-InformationMessage -Message ('Trying mirror: '+$Mirror.MirrorURL+' ('+$Mirror.Type+')')
            $URLBase=$Mirror.Type+'://'+$Mirror.MirrorURL
            $URLPathandQuery=([System.Uri]$URL).pathandquery 
            $DownloadURL=($URLBase+$URLPathandQuery)
            Write-InformationMessage -Message ('Trying to download from: '+$DownloadURL)
            try {
                Invoke-WebRequest $DownloadURL -OutFile ($LocationforDL+$NameofDL) # Powershell 5 compatibility -AllowInsecureRedirect
                Write-InformationMessage -Message "Download completed"
                return $true   
            }
            catch {
                Write-ErrorMessage -Message ('Error downloading '+$NameofDL+'! Trying different server')
            }
        }
        Write-ErrorMessage -Message 'All servers attempted. Download failed'
        return $false    
    }
    else{
        do {
            try {
                If ($Attempts -ne 0){
                    Write-InformationMessage -Message ('Downloading file '+$NameofDL+' Attempt #'+($Attempts+1))                
                }
                Invoke-WebRequest $URL -OutFile ($LocationforDL+$NameofDL) # Powershell 5 compatibility -AllowInsecureRedirect
                $IsSuccess = $true
                Write-InformationMessage -Message 'Download completed'
                Return $true       
            }
            catch {
                Write-InformationMessage -message 'Download failed! Retrying in 3 seconds'
                Start-Sleep -Seconds 3
                $IsSuccess = $false   
            }
            $Attempts ++               
            
        } until (
            $IsSuccess -eq $true -or $Attempts -eq 3
        )
        Write-ErrorMessage -Message ('Error downloading '+$NameofDL+'!')
        return $false
    }
}
function Start-HSTImager {
    param (
        $Command,
        $HSTImagePathtouse,
        $SourcePath,
        $DestinationPath,
        $FileSystemPath,
        $Options,
        $DosType, 
        $TempFoldertouse,
        $ImageSize,
        $DeviceName,
        $SizeofPartition,
        $PartitionNumber,
        $VolumeName  
    )
    $Logoutput=($TempFoldertouse+'LogOutputTemp.txt')
    if ($Command -eq 'Blank'){
        Write-InformationMessage -Message 'Creating image'
        & $HSTImagePathtouse blank $DestinationPath $ImageSize >$Logoutput            
    }
    elseif ($Command -eq 'rdb init'){
        Write-InformationMessage -Message 'Initialising partition'
        & $HSTImagePathtouse rdb init $DestinationPath $Options >$Logoutput            
    }
    elseif ($Command -eq 'rdb filesystem add'){
        Write-InformationMessage -Message ('Adding Filesystem '+$DosType+' to RDB')
        & $HSTImagePathtouse rdb filesystem add $DestinationPath $FileSystemPath $DosType $Options >$Logoutput            
    }
    elseif ($Command -eq 'rdb part add'){
        Write-InformationMessage -Message ('Adding partition '+$DeviceName+' '+$DosType+' with size '+$SizeofPartition)
        & $HSTImagePathtouse rdb part add $DestinationPath $DeviceName $DosType $SizeofPartition $Options --mask 0x7ffffffe --buffers 300 --max-transfer 0xffffff >$Logoutput
    }
    elseif ($Command -eq 'rdb part format'){
        Write-InformationMessage -Message ('Formatting partition '+$VolumeName)
        & $HSTImagePathtouse rdb part format $DestinationPath $PartitionNumber $VolumeName >$Logoutput         
    }   
    elseif ($Command -eq 'fs extract') {
        Write-InformationMessage -Message ('Extracting data from ADF. Source path is: '+$SourcePath+' Destination path is: '+$DestinationPath)
        & $HSTImagePathtouse fs extract $SourcePath $DestinationPath $Options >$Logoutput                                
    }
    elseif ($Command -eq 'fs copy') {
        Write-InformationMessage -Message ('Writing file(s) to HDF image for: '+$SourcePath+' to '+$DestinationPath) 
        & $HSTImagePathtouse fs copy $SourcePath $DestinationPath $Options >$Logoutput  
    } 
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-ErrorMessage -Message ('Error in HST-Imager: '+$ErrorLine)
            Copy-Item -Path $Logoutput -Destination ($Script:LogFolder+$Script:LogDateTime+'_LastHSTErrorLogFull.txt')        
        }
    }
    if ($ErrorCount -ge 1){       
        return $false
    }    
    else{
        return $true
    }
}
function Read-AmigaTooltypes {
    param (
        $HSTAmigaPathtouse,
        $TempFoldertouse,
        $IconPath,
        $ToolTypesPath
        
    )
    $Logoutput=($TempFoldertouse+'LogOutputTemp.txt')
    Write-InformationMessage -Message ('Extracting Tooltypes for info file(s): '+$IconPath+'  to '+$ToolTypesPath) 
    & $HSTAmigaPathtouse icon tooltypes export $IconPath $ToolTypesPath >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-ErrorMessage -Message ('Error in HST-Amiga: '+$ErrorLine)           
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        return $false   
    }
    else{
        return $true
    }
}
function Write-AmigaTooltypes {
    param (
        $HSTAmigaPathtouse,
        $TempFoldertouse,
        $IconPath,
        $ToolTypesPath
    )
    $Logoutput=($TempFoldertouse+'LogOutputTemp.txt')
    Write-InformationMessage -Message ('Importing Tooltypes for info file(s): '+$IconPath+' from '+$ToolTypesPath) 
    & $HSTAmigaPathtouse icon tooltypes import $IconPath $ToolTypesPath >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-ErrorMessage -Message ('Error in HST-Amiga: '+$ErrorLine)           
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        return $false    
    }
    else{
        return $true
    }        
}
function Write-AmigaIconPostition {
    param (
        $HSTAmigaPathtouse,
        $TempFoldertouse,
        $IconPath,
        $XPos,
        $YPos
    )
    $Logoutput=($TempFoldertouse+'LogOutputTemp.txt')
    Write-InformationMessage -Message ('Adjusting position for for info file: '+$IconPath) 
    & $HSTAmigaPathtouse icon update $IconPath -x $Xpos -y $YPos >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-ErrorMessage -Message ('Error in HST-Amiga: '+$ErrorLine)           
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        return $false    
    }
    else{
        return $true
    }        
}

function Expand-AmigaZFiles {
    param (
        $LocationofZFiles,
        $SevenzipPathtouse,
        $WorkingFoldertouse
    )
    $ListofFilestoDecompress=Get-ChildItem -Path $LocationofZFiles -Recurse -Filter '*.Z'
    Write-InformationMessage -Message ('Decompressing .Z files in location: '+$LocationofZFiles)
    foreach ($FiletoDecompress in $ListofFilestoDecompress){
        $InputFile=$FiletoDecompress.FullName
        set-location $FiletoDecompress.DirectoryName
        & $SevenzipPathtouse e $InputFile -bso0 -bsp0 -y
    }      
    Set-Location $WorkingFoldertouse
    Write-InformationMessage -Message ('Deleting .Z files in location: '+$LocationofZFiles)
    Get-ChildItem -Path $LocationofZFiles -Recurse -Filter '*.Z' | remove-Item -Recurse -Force
}
function Add-AmigaFolder {
    param (
        $AmigaFolderPath,
        $TempFoldertouse,
        $AmigaDrivetoCopytouse
    )
    $ParentFolder=(Split-Path ($AmigaDrivetoCopytouse+$AmigaFolderPath) -Parent)+'\'
    $Startpoint=(Split-Path -Path ($AmigaDrivetoCopytouse+$AmigaFolderPath)).length+1
    $Endpoint=($AmigaDrivetoCopytouse+$AmigaFolderPath).length-1
    $Length=$Endpoint-$Startpoint
    $FileName=($AmigaDrivetoCopytouse+$AmigaFolderPath).Substring($Startpoint,$Length) 
    if (-not (Test-Path ($AmigaDrivetoCopytouse+$AmigaFolderPath))){
        Write-InformationMessage -Message ('Creating Folder "'+$AmigaFolderPath+'"')
        $null = New-Item -path ($AmigaDrivetoCopytouse+$AmigaFolderPath) -ItemType Directory -Force 
    }
    else{
        Write-InformationMessage -Message ('Folder "'+$AmigaFolderPath+'" already exists')
    
    }
    if (-not(Test-Path ($ParentFolder+$FileName+'.info'))){
        Write-InformationMessage -Message ('Creating .info file '+$FileName+'.info')
        Copy-Item ($TempFoldertouse+'NewFolder.info') $ParentFolder
        Rename-Item ($ParentFolder+'NewFolder.info') ($ParentFolder+$FileName+'.info')
    }
    else {
        Write-InformationMessage -Message ($FileName+'.info already exists')
    }
}

function Get-GithubRelease {
    param (
        $GithubRelease,
        $Tag_Name,
        $Name,
        $LocationforDownload,
        $LocationforProgram,
        $Sort_Flag,
        $OnlyReleaseVersions
    )

    if(Test-Path $LocationforProgram){
        Write-InformationMessage -Message 'File already exists!'
        return $true   
    }
    else{
        Write-InformationMessage -Message 'Retrieving Github information'
        $Counter = 0
        $IsSuccess = $null
        do {
            if ($Counter -gt 0){
                Write-InformationMessage -Message 'Trying to retrieve Githb information again'
            }
            try {
                $GithubDetails = (Invoke-WebRequest $GithubRelease | ConvertFrom-Json)  
                $IsSuccess = $true          
            }
            catch {
                $IsSuccess = $false
            }
            $Counter ++            
        } until (
            $IsSuccess -eq $true -or $Counter -eq 3 
        )
        if ($IsSuccess -eq $false){
            Write-ErrorMessage -Message ('Error downloading '+$NameofDL+'!')
            return $false
        }
        if ($OnlyReleaseVersions -eq 'TRUE'){
        
            $GithubDetails_Sorted = $GithubDetails | Where-Object { $_.tag_name -ne 'nightly' -and ($_.draft).tostring() -eq 'False' -and ($_.prerelease).tostring() -eq 'False' -and ($_.name).tostring() -notmatch 'Release Candidate'} | Sort-Object -Property 'tag_name' -Descending | Select-Object -ExpandProperty assets
            $GithubDetails_ForDownload = $GithubDetails_Sorted  | Where-Object { $_.name -match $Name } | Select-Object -First 1
        }
        else {
            if ($Sort_Flag -eq 'Sort'){
                $GithubDetails_ForDownload = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name } | Sort-Object -Property updated_at -Descending
                $GithubDetails_ForDownload = $GithubDetails | Where-Object { $_.tag_name -eq 'nightly' } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name } | Sort-Object -Property updated_at -Descending
            }
            else{
                $GithubDetails_ForDownload = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }
            }
        }
        $GithubDownloadURL =$GithubDetails_ForDownload[0].browser_download_url 
        Write-InformationMessage -Message ('Downloading Files for URL: '+$GithubDownloadURL)
        $Counter = 0
        $IsSuccess = $null
        do {
            if ($Counter -gt 0){
                Write-InformationMessage -Message 'Trying Download again'
            }
            try {
                Invoke-WebRequest $GithubDownloadURL -OutFile $LocationforDownload # Powershell 5 compatibility -AllowInsecureRedirect
                Write-InformationMessage -Message 'Download completed'  
                $IsSuccess = $true              
            }
            catch {
                $IsSuccess = $false
            }
            $Counter ++             
        } until (
            $IsSuccess -eq $true -or $Counter -eq 3 
        )
        if ($IsSuccess -eq $false){
            Write-ErrorMessage -Message ('Error downloading '+$NameofDL+'!')
            return $false
        }
        Write-InformationMessage -Message 'Extracting Files'
        $null = Expand-Archive -LiteralPath $LocationforDownload -DestinationPath $LocationforProgram -force
        return $true   
    }
}

function Edit-AmigaScripts {
    param (
        $ScripttoEdit,
        $Action,
        $Name,
        $Injectionpoint, 
        $Startpoint,
        $Endpoint,
        $LinestoAdd,
        $ArexxFlag
    )
    $ScripttoEdit_Revised = New-Object System.Collections.Generic.List[System.Object]
    if ($Action -eq 'remove'){
        Write-InformationMessage -Message 'Removing items from script'
        Write-InformationMessage -Message ('Startpoint is: '+$Startpoint+' Endpoint is: '+$Endpoint)
        $RemoveLine=0 
        foreach ($Line in $ScripttoEdit) {
            if ($line -match $Startpoint){
                $RemoveLine=1
                $ScripttoEdit_Revised.Add('; '+$Name+' Removed by Powershell')
            }
            if ($RemoveLine -eq 0){
                $ScripttoEdit_Revised.Add($Line)
                }
            if ($line -match $Endpoint){
                $RemoveLine=0
                }
        }
    }
    if ($Action -eq 'inject' -and $Injectionpoint-eq 'before'){
        Write-InformationMessage -Message 'Injecting new lines in script before Startpoint'
        Write-InformationMessage -Message ('Startpoint is: '+$Startpoint)
        foreach ($Line in $ScripttoEdit) {
            if ($line -match $Startpoint){
                $ScripttoEdit_Revised.Add('')
                if ($ArexxFlag -eq 'AREXX'){
                    $ScripttoEdit_Revised.Add('/*')
                    $ScripttoEdit_Revised.Add($Name+' Added by Powershell -Begin')
                    $ScripttoEdit_Revised.Add('*/')                 
                    $ScripttoEdit_Revised.Add('')
                }
                else{
                    $ScripttoEdit_Revised.Add('; '+$Name+' Added by Powershell -Begin')
                }
                foreach ($LinetoAdd in $LinestoAdd){
                    $ScripttoEdit_Revised.Add($LinetoAdd)
                }
                if ($ArexxFlag -eq 'AREXX'){
                    $ScripttoEdit_Revised.Add('/*')
                    $ScripttoEdit_Revised.Add($Name+' Added by Powershell -End')
                    $ScripttoEdit_Revised.Add('*/')                 
                    $ScripttoEdit_Revised.Add('')
                }
                else{
                    $ScripttoEdit_Revised.Add('; '+$Name+' Added by Powershell -End')
                }
                $ScripttoEdit_Revised.Add('')
                $ScripttoEdit_Revised.Add($Startpoint)
            }
            else{
                $ScripttoEdit_Revised.Add($Line)
           }
       }
   }
   if ($Action -eq 'inject' -and $Injectionpoint-eq 'after'){
        Write-InformationMessage -Message 'Injecting new lines in script after startpoint'
        Write-InformationMessage -Message ('Startpoint is: '+$Startpoint)
       foreach ($Line in $ScripttoEdit) {
           if ($line -match $Startpoint){
               $ScripttoEdit_Revised.Add($Startpoint)
               $ScripttoEdit_Revised.Add('')
               if ($ArexxFlag -eq 'AREXX'){
                   $ScripttoEdit_Revised.Add('/*')
                   $ScripttoEdit_Revised.Add($Name+' Added by Powershell -Begin')
                   $ScripttoEdit_Revised.Add('*/')                 
                   $ScripttoEdit_Revised.Add('')
               }
               else {
                   $ScripttoEdit_Revised.Add('; '+$Name+' Added by Powershell -Begin')            
               }
               foreach ($LinetoAdd in $LinestoAdd){
                   $ScripttoEdit_Revised.Add($LinetoAdd)
               }
               $ScripttoEdit_Revised.Add('')
               if ($ArexxFlag -eq 'AREXX'){
                   $ScripttoEdit_Revised.Add('/*')
                   $ScripttoEdit_Revised.Add($Name+' Added by Powershell -End')
                   $ScripttoEdit_Revised.Add('*/')                 
               }
                else {
                    $ScripttoEdit_Revised.Add('; '+$Name+' Added by Powershell -End')            
                }
            $ScripttoEdit_Revised.Add('')
           }
           else {
            $ScripttoEdit_Revised.Add($Line)
           }
        }
   }
    if ($Action -eq 'Append'){
        $ScripttoEdit_Revised.Add('; '+$Name+' Amended by Powershell')
        foreach ($LinetoAdd in $LinestoAdd){
            $ScripttoEdit_Revised.Add($LinetoAdd)
        }
    }
    return $ScripttoEdit_Revised    
}
function Export-TextFileforAmiga {
    param (
        $ExportFile,
        $DatatoExport,
        $AddLineFeeds
    )
    Write-InformationMessage -Message ('Exporting file '+$ExportFile)
    if ($AddLineFeeds -eq 'TRUE'){
        Write-InformationMessage -Message ('Adding line feeds to file '+$ExportFile)
        foreach ($Line in $DatatoExport){
            $DatatoExportRevised+=$line+"`n"
        }
    }
    else{
        $DatatoExportRevised+=$DatatoExport
    }
    [System.IO.File]::WriteAllText($ExportFile,$DatatoExportRevised,[System.Text.Encoding]::GetEncoding('iso-8859-1'))
}
function Import-TextFileforAmiga {
    param (
        $ImportFile,
        $SystemType
    )
    $DataRevised = New-Object System.Collections.Generic.List[System.Object]
    if ($SystemType -eq 'PC'){
        $Data=Get-Content -path $ImportFile -Encoding ascii ## Powershell 5 compatibility
        $Data = $Data -split "`n"
    }
    if ($SystemType -eq 'Amiga'){
        $Data=[System.IO.File]::ReadAllText($ImportFile,[System.Text.Encoding]::GetEncoding('iso-8859-1')) #-replace "`r`n", "`n"
        $Data = $Data -split "`n" 
    }
    foreach ($Line in $Data){
        $DataRevised.Add(($line -replace "`r`n", "`n"))
    }
    return $DataRevised
}
function Find-LatestAminetPackage {
    param (
        $PackagetoFind,
        $Exclusion,
        $DateNewerthan,
        $Architecture
    )
    $AminetURL='http://aminet.net'
    $URL=('https://aminet.net/search?name='+$PackagetoFind+'&o_date=newer&date='+$DateNewerthan+'&arch[]='+$Architecture)
    Write-InformationMessage -Message('Searching for: '+$PackagetoFind)
    $ListofAminetFiles=Invoke-WebRequest $URL -UseBasicParsing # -AllowInsecureRedirect Powershell 5 compatibility
    foreach ($Line in $ListofAminetFiles.Links) {      
    if (!$Exclusion) {
        if (($line -match ('.lha'))){
            Write-InformationMessage -Message ('Found '+$line.href)
            return ($AminetURL+$line.href)
       }     
    }
    else {
    }
        if (($line -match ('.lha')) -and (-not ($line -match $Exclusion))){
            Write-InformationMessage -Message ('Found '+$line.href)
            return ($AminetURL+$line.href)
       }       
    }
    Write-ErrorMessage -Message 'Could not find package! Unrrecoverable error!'
    return                 
}
function Find-WHDLoadWrapperURL{
    param (
        $SearchCriteria,
        $ResultLimit
        )        
        $SiteLink='https://ftp2.grandis.nu'
        $ListofURLs = New-Object System.Collections.Generic.List[System.Object]
        $SearchResults=Invoke-WebRequest "https://ftp2.grandis.nu/turransearch/search.php?_search_=1&search=$SearchCriteria&category_id=Misc&exclude=&limit=$ResultLimit&httplinks=on"
        Write-InformationMessage -Message ('Retrieving link latest version of '+$SearchCriteria)
        foreach ($Item in $SearchResults.Links.OuterHTML){
            if ($item -match $SearchCriteria){
                $Startpoint=$item.IndexOf('/turran')
                $Endpoint=$item.IndexOf('">/Misc/')
                $InvidualURL=$item.Substring($Startpoint,($Endpoint-$Startpoint))
                $ListofURLs.Add($InvidualURL)    
            }
        }
        $DownloadLink = $SiteLink+($ListofURLs | Sort-Object -Descending | Select-Object -First 1)
        if ($DownloadLink){
            return $DownloadLink
        }
        else {
            return
        }
    }
    
function Get-ModifiedToolTypes {
    param (
        $OriginalToolTypes,
        $ModifiedToolTypes
    )
    $Tooltypes_Revised = New-Object System.Collections.Generic.List[System.Object]
    $HashTableforOldandNewToolTypes = @{} # Clear Hash
    foreach ($ModifiedToolType in $ModifiedTooltypes){
        if ($ModifiedToolType.OldValue -ne ""){
            $HashTableforOldandNewToolTypes.Add($ModifiedToolType.OldValue,$ModifiedToolType.NewValue) 
        }
        else{
            $Tooltypes_Revised.Add($ModifiedTooltype.NewValue)            
        }        
    }
    foreach ($OriginalToolType in $OriginalToolTypes){
        if ($HashTableforOldandNewToolTypes[$OriginalToolType]){
            $Tooltypes_Revised.Add($HashTableforOldandNewToolTypes[$OriginalToolType])
        }
        else{
            $Tooltypes_Revised.Add($OriginalToolType)
        }
    }
    return $Tooltypes_Revised    
}       
function Compare-KickstartHashes {
    param (
        $PathtoKickstartHashes,
        $PathtoKickstartFiles,
        $KickstartVersion
    )
    
    $Msg_Header ='Finding Kickstart'    
    $Msg_Body = @"
Searching folder '$Script:ROMPath' for valid Kickstart file. Depending on the size of the folder you selected this may take some time. 
"@

    $Msg_Header_ExceedLimit ='Exceeded file limits!'   
    $Msg_Body_ExceedLimit = @"
Search is limited to a maximum of 500 files! The current path (with no sub-folders) will be matched.

If this does not find your Kickstart file either select a different path 
with less files or move the Kickstart into the default 
'UserFiles\Kickstarts\' folder in your install path for the tool
and select this path to scan. 

"@

#    $PathtoKickstartHashes = 'E:\Emu68Imager\InputFiles\RomHashes.csv'
#    $PathtoKickstartFiles = 'E:\Emulators\Amiga Files\Shared\rom\'
#    $KickstartVersion = 3.2
    
    $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,0)

    $KickstartHashestoFind =Import-Csv $PathtoKickstartHashes -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Sort-Object -Property 'Sequence'   

    $ListofKickstartFilestoCheck  = Get-ChildItem $PathtoKickstartFiles -force -Recurse

    if ((($ListofKickstartFilestoCheck | Measure-Object).count) -gt 500){
        $null = [System.Windows.MessageBox]::Show($Msg_Body_ExceedLimit,$Msg_Header_ExceedLimit,0,48)
        $ListofKickstartFilestoCheck  = $ListofKickstartFilestoCheck | Where-Object {$_.DirectoryName -eq $PathtoKickstartFiles.TrimEnd('\') } 
    } 

    $ListofKickstartFilestoCheck  = $ListofKickstartFilestoCheck  | Where-Object { $_.PSIsContainer -eq $false -and $_.Length -eq 524288}
   
    $FoundKickstarts = [System.Collections.Generic.List[PSCustomObject]]::New()
    $HashTableforKickstartFilestoCheck = @{} # Clear Hash
   
    foreach ($KickstartDetailLine in $ListofKickstartFilestoCheck){
        $KickstartHash=Get-FileHash -LiteralPath $KickstartDetailLine.FullName -Algorithm MD5
        if (-not ($HashTableforKickstartFilestoCheck[$KickstartHash.Hash])){
            $HashTableforKickstartFilestoCheck.Add(($KickstartHash.Hash),$KickstartDetailLine.FullName)
        }
    }
      
    foreach ($KickstartRomandHash in $KickstartHashestoFind){
        if ($HashTableforKickstartFilestoCheck[$KickstartRomandHash.Hash]){
            $FoundKickstarts += [PSCustomObject]@{
                Kickstart_Version = $KickstartRomandHash.Kickstart_Version
                FriendlyName= $KickstartRomandHash.FriendlyName
                Sequence = $KickstartRomandHash.Sequence 
                Fat32Name = $KickstartRomandHash.Fat32Name
                KickstartPath = ($HashTableforKickstartFilestoCheck[$KickstartRomandHash.Hash])
            }        
        }
        # else{
        #     $FoundKickstarts += [PSCustomObject]@{
        #         Kickstart_Version = $KickstartRomandHash.Kickstart_Version
        #         FriendlyName= $KickstartRomandHash.FriendlyName
        #         Sequence = $KickstartRomandHash.Sequence 
        #         Fat32Name = $KickstartRomandHash.Fat32Name
        #         KickstartPath = ""
        #     }        
        # }
    }
    
    if ($FoundKickstarts){
        $KickstarttoUse = $FoundKickstarts | Sort-Object -Property 'Sequence' | Select-Object -first 1
        return $KickstarttoUse 
    }
    else{
        return
    }
}
    
function Compare-ADFHashes {
    param (
        $PathtoADFFiles,
        $PathtoADFHashes,
        $KickstartVersion,
        $PathtoListofInstallFiles
    
    )

    $Msg_Header ='Finding ADFs'    
    $Msg_Body = @"
Searching folder '$Script:ADFPath' for valid ADFs. 

"@
    $Msg_Header_ExceedLimit ='Exceeded file limits!'   
    $Msg_Body_ExceedLimit = @"
Search is limited to a maximum of 500 files! The current path (with no sub-folders) will be matched.

If this does not find your ADFs either select a different path 
with less files or move the ADFs into the default 
'UserFiles\ADFs\' folder in your install path for the tool
and select this path to scan. 

"@
    $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,0)

  #  $PathtoADFFiles = 'E:\Emulators\Amiga Files\Shared\adf\commodore-amiga-operating-systems-workbench\ESCOM\'
  #  $PathtoADFHashes = 'E:\Emu68Imager\InputFiles\ADFHashes.csv'
  #  $KickstartVersion='3.1'
  #  $PathtoListofInstallFiles = 'E:\Emu68Imager\InputFiles\ListofInstallFiles.csv'

    $ListofADFFilestoCheck = Get-ChildItem $PathtoADFFiles -force -Recurse
    if ((($ListofADFFilestoCheck | Measure-Object).count) -gt 500){
        $null = [System.Windows.MessageBox]::Show($Msg_Body_ExceedLimit,$Msg_Header_ExceedLimit,0,48)
        $ListofADFFilestoCheck = $ListofADFFilestoCheck | Where-Object {$_.DirectoryName -eq $PathtoADFFiles.TrimEnd('\')} 
    } 
    $ListofADFFilestoCheck = $ListofADFFilestoCheck | Where-Object { $_.PSIsContainer -eq $false -and $_.Name -match '.adf' -and $_.Length -eq 901120 } | Get-FileHash  -Algorithm MD5

    $ADFHashes = Import-Csv $PathtoADFHashes -Delimiter ';' | Sort-Object -Property 'Sequence'
   
    $RequiredADFsforInstall = Get-ListofInstallFiles $PathtoListofInstallFiles |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Select-Object ADF_Name, FriendlyName -Unique # Unique ADFs Required
    
    $RequiredADFandHashes = [System.Collections.Generic.List[PSCustomObject]]::New() # Allowing for if there are multiple hashes for the same ADF
    
    foreach ($ADFHash in $ADFHashes){
        foreach ($RequiredADF in $RequiredADFsforInstall){
            if ($ADFHash.ADF_Name -eq $RequiredADF.ADF_Name){
                $RequiredADFandHashes += [PSCustomObject]@{
                    ADF_Name = $ADFHash.ADF_Name
                    FriendlyName = $ADFHash.FriendlyName
                    Hash = $ADFHash.Hash
                    Sequence =  $ADFHash.Sequence
                    ADFSource = $ADFHash.ADFSource
                }
            }
        }
    }
    
    $HashTableforADFHashestoFind = @{} # Clear Hash
    $RequiredADFandHashes | Sort-Object -Property 'Sequence'| ForEach-Object {
        $HashTableforADFHashestoFind[$_.Hash] = @($_.ADF_Name,$_.FriendlyName,$_.ADFSource,$_.Sequence)
    }

    $PathofFoundADFS = [System.Collections.Generic.List[PSCustomObject]]::New()
    $ListofADFFilestoCheck | ForEach-Object {
        if ($HashTableforADFHashestoFind.ContainsKey($_.Hash)){
            $PathofFoundADFS += [PSCustomObject]@{
                Hash = $_.Hash
                Path = $_.Path
                ADF_Name = $HashTableforADFHashestoFind.($_.Hash)[0]
                FriendlyName = $HashTableforADFHashestoFind.($_.Hash)[1]
                Source = $HashTableforADFHashestoFind.($_.Hash)[2]
                Sequence = $HashTableforADFHashestoFind.($_.Hash)[3]
            
            }                  
        }
    }

    $PathofFoundADFS = $PathofFoundADFS | Sort-Object -Property 'Sequence'
    
    $MatchedADFs = [System.Collections.Generic.List[PSCustomObject]]::New()

    $RequiredADFsforInstall | ForEach-Object {
        $IsFoundADF = $false
        foreach ($FoundADF in $PathofFoundADFS){
            If ($_.ADF_Name -eq $FoundADF.ADF_Name){
                $MatchedADFs += [PSCustomObject]@{
                    Hash = $FoundADF.Hash
                    Path = $FoundADF.Path
                    ADF_Name = $FoundADF.ADF_Name
                    FriendlyName = $FoundADF.FriendlyName
                    Source = $FoundADF.Source
                    IsMatched = 'TRUE'
                }
                $IsFoundADF = $true
                break
            }
        }
        if ($IsFoundADF -eq $false){
            $MatchedADFs += [PSCustomObject]@{
                Hash = ''
                Path = ''
                ADF_Name = $_.ADF_Name
                FriendlyName = $_.FriendlyName
                IsMatched = 'False'                
            }
        }            
    }

    return $MatchedADFs
}  

function Get-StartupSequenceVersion {
    param (
        $StartupSequencetoCheck
    )
    $StartupSequence_FirstLine = $StartupSequencetoCheck | Select-Object -First 1
    
    $String_Start='; $VER: Startup-Sequence_HardDrive '    
    $String_End=' ('
    
    $Startpoint = $StartupSequence_FirstLine.IndexOf($String_Start)+$String_Start.Length
    if ($Startpoint -lt 0){
        Write-ErrorMessage -Message  'Error! No version found!'
        return
    }
    else{
        $Endpoint = $StartupSequence_FirstLine.IndexOf($String_End)
        $Version=$StartupSequence_FirstLine.Substring($Startpoint,($Endpoint-$Startpoint))
        Write-InformationMessage -Message ('Version of Startup-Sequence is '+$Version)
        return $Version
    }
}
    
function Get-StartupSequenceInjectionPointfromVersion {
    param (
        $SSversion,
        $InjectionPointtoParse
        )
        $InjectionPointTable = [System.Collections.Generic.List[PSCustomObject]]::New()
        
        if ($InjectionPointtoParse -match "¬"){
            $InjectionPointSplit=$InjectionPointtoParse -split "¬"
        
        }
        else {
            Write-InformationMessage -Message ('Injection point identified (not version specific) is: '+$InjectionPointtoParse)
            return $InjectionPointtoParse
        }    
        foreach ($Row in $InjectionPointSplit) {
            if ($Row.Substring(0,8) -eq 'VERSION-'){
                $Startpoint='VERSION-'.Length
                $length=($row.Length)-$Startpoint       
                $VersiontoPopulate=$row.substring($Startpoint,$length)
            }
            else{
                $StringtoPopulate=$Row
            }
            if ($null -ne $StringtoPopulate){
                $InjectionPointTable += [PSCustomObject]@{
                    Version = $VersiontoPopulate
                    Text= $StringtoPopulate
                }
                $StringtoPopulate=$null
            } 
        
        }
        foreach ($line in $InjectionPointTable){
            if ($line.Version -eq $SSversion){
                Write-InformationMessage -Message ('Injection point identified for version '+$SSversion+' is: '+$line.Text)
                return $line.Text
            }
        }    
        return           
}

#[Enum]::GetNames([System.Environment+SpecialFolder])

function Get-ImageSizevsDiskSize {
    param (
        $UnallocatedSpace,
        $ThresholdtocheckMiB,
        $DiskSizetocheck,
        $ImageSizetocheck
    )

    $FormattedImageSize= Get-FormattedSize -Size $ImageSizetocheck
    $FormattedDiskSize = Get-FormattedSize -Size $DiskSizetocheck

    $Msg_Header ='Check Image Size'    
    $Msg_Body = @"
The image size you have selected  ($FormattedImageSize) is smaller than the size of the disk ($FormattedDiskSize). If you are OK to proceed, select 'Yes' otherwise 'No' to return to the interface
"@
    if ($UnallocatedSpace -ge $ThresholdtocheckMiB*1024){
        $ValueofAction = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,4,48)
        if ($ValueofAction -eq 'Yes'){
            return $true
        }
        else{
            return $false
        }    
    }
    else{
        return $true
    }
}

function Get-TransferFileCheck {
    param (
        $TransferLocationtocheck,
        $TransferSpaceThreshold,
        $TransferAvailableSpace
    )
    $Msg_Header ='Error - Insufficient Space!'    
    $Msg_Body = @"
You do not have sufficient space on your Work partition to transfer the files!
            
Select a location with less space, increase the space on Work, or remove the transfer of files
"@    
    if ($TransferLocationtocheck){
        if ($TransferAvailableSpace -lt $TransferSpaceThreshold){
            $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,48)
            return $false
        }
        else{
            return $true
        }
    }
    else{
        return $true
    }
}

function Get-SpaceCheck {
    param (
      $AvailableSpace,
      $SpaceThreshold
    )
    $Msg_Header ='Error - Insufficient Space!'    
    $Msg_Body = @"
You do not have sufficient space on your drive to run the tool!

Either select a location with sufficient space (the folder must be empty) 
or press 'Cancel' to quit the tool
"@   
    $Msg_Body_Repeat = @"
You still do not have sufficient space on your drive to run the tool!
                  
Either select a location with sufficient space (the folder must be empty) 
or press cancel to quit the tool
"@            
    if ($AvailableSpace -gt $SpaceThreshold){
        return $true
    }
    else {
        $ValueofAction = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,1,48)
        if ($ValueofAction -eq 'Cancel'){
            $Script:ExitType =2
            return $false
        }
        do {
            $Script:WorkingPath = Get-WorkingPath -CheckforEmptyFolder 'TRUE'
            $Script:WorkingPath = $Script:WorkingPath.TrimEnd('\')+'\'
            $Script:WorkingPathDefault = $false   
            $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Script:WorkingPath)/1kb
            $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
            if ($Script:AvailableSpace_WorkingFolderDisk -gt $Script:SpaceThreshold_WorkingFolderDisk){                
                $Success='TRUE'
                return $true # Sufficient Space
            }
            else{
                $ValueofAction = [System.Windows.MessageBox]::Show($Msg_Body_Repeat, $Msg_Header,1,48)
                if ($ValueofAction -eq 'Cancel'){
                    $Script:ExitType = 2
                    return $false
                }
            }

        } until (
            ($Script:ExitType -eq 2) -or $Success -eq 'TRUE'
        )
    }
}

function Write-GUINoOSChosen {
    param (
        $Type
    )
    $Msg_Header ='Error - No OS Chosen!'    
    $Msg_Body = @"  
Cannot check $Type as you have not yet chosen the OS!    
"@     
    $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,48)  
}


function Write-GUIMissingADFs {
    param (
        $MissingADFstoReport 
    )
    
    $Msg_Header ='Error - ADFs Missing!'    
    $Msg_Body = @"  
The following ADFs are missing:  

$MissingADFstoReport 
Select a location with valid ADF files.    
"@     
    $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,48) 

}

function Write-GUINoKickstart {
    param (
        
    )
    $Msg_Header ='Error - No Kickstart found!'    
    $Msg_Body = @"  
No valid Kickstart file was found at the location you specified. Select a location with a valid Kickstart file.    
"@     
    $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,48) 
}

function Write-GUIReporttoUseronOptions {
    $WPF_UI_DiskNameValue_Reporting_Detail_TextBox.Text = $Script:HSTDiskName
    $WPF_UI_ScreenModeValue_Reporting_Detail_TextBox.Text = $Script:ScreenModetoUse
    $WPF_UI_KickstartValue_Reporting_Detail_TextBox.Text =$Script:KickstartVersiontoUse
    if ($Script:SSID){
        $WPF_UI_SSIDValue_Reporting_Detail_TextBox.Text =  $Script:SSID
    }
    else{
        $WPF_UI_SSIDValue_Reporting_Detail_TextBox.Text = 'No SSID Set'
    }
    if ($Script:WifiPassword){
        $WPF_UI_PasswordValue_Reporting_Detail_TextBox.Text = $Script:WifiPassword 

    } 
    else{
        $WPF_UI_PasswordValue_Reporting_Detail_TextBox.Text = 'No Password Set'
    }
    $WPF_UI_Fat32SizeValue_Reporting_Detail_TextBox.Text =  Get-FormattedSize -Size ($Script:SizeofFAT32)
    $WPF_UI_ImageSizeValue_Reporting_Detail_TextBox.Text = Get-FormattedSize -Size $Script:SizeofImage
    $WPF_UI_WorkbenchSizeValue_Reporting_Detail_TextBox.Text = Get-FormattedSize -Size $Script:SizeofPartition_System
    $WPF_UI_WorkSizeValue_Reporting_Detail_TextBox.Text = Get-FormattedSize -Size $Script:SizeofPartition_Other
    $WPF_UI_WriteImageOnlytoDiskValue_Reporting_Detail_TextBox.Text =  $Script:ImageOnly
    # if ($Script:WriteMethod -eq 'Normal'){
    #     $WPF_UI_WriteMethodValue_Reporting_Detail_TextBox.Text = 'All sectors on disk will be written'
    # } 
    # elseif ($Script:WriteMethod -eq 'SkipEmptySpace'){
    #     $WPF_UI_WriteMethodValue_Reporting_Detail_TextBox.Text = 'Empty space on disk will be skipped'
    # }
    # else{
    #     $WPF_UI_WriteMethodValue_Reporting_Detail_TextBox.Text = ''
    # }
    $WPF_UI_SetupDiskOnlyValue_Detail_TextBox.Text = $Script:SetDiskupOnly
    $WPF_UI_DeleteAllWorkingPathFilesValue_Detail_TextBox.Text = $Script:DeleteAllWorkingPathFiles
    $WPF_UI_WorkingPathValue_Reporting_Detail_TextBox.Text = $Script:WorkingPath
    $WPF_UI_RomPathValue_Reporting_Detail_TextBox.Text = $Script:ROMPath
    $WPF_UI_ADFPathValue_Detail_TextBox.Text = Get-FormattedPathforGUI -PathtoTruncate $Script:ADFPath -Length 63
    if ($Script:ImageOnly -eq 'TRUE'){
        $WPF_UI_LocationofImageValue_Detail_TextBox.Text = $Script:LocationofImage
        $WPF_UI_LocationofImage_Detail_TextBox.Visibility = 'Visible'
        $WPF_UI_LocationofImageValue_Detail_TextBox.Visibility = 'Visible'
    }
    else{
        $WPF_UI_LocationofImage_Detail_TextBox.Visibility = 'Hidden'
        $WPF_UI_LocationofImageValue_Detail_TextBox.Visibility = 'Hidden'
    }
    if ($Script:TransferLocation){
        $WPF_UI_TransferPathValue_Detail_TextBox.Text = Get-FormattedPathforGUI -PathtoTruncate $Script:TransferLocation -Length 63
    }
    else{
        $WPF_UI_TransferPathValue_Detail_TextBox.Text = 'No Transfer Location Set'
    }
}
function Repair-SDDisk {
    param (
        $DiskNumbertoUse,
        $TempFoldertoUse
        )
        $SelectDiskLine = ('SELECT DISK '+$DiskNumbertoUse)
        NEW-ITEM -Path ($TempFoldertoUse+'DiskPartScriptClean.txt') -ItemType file -force | OUT-NULL
        ADD-CONTENT -Path ($TempFoldertoUse+'DiskPartScriptClean.txt') $SelectDiskLine
        ADD-CONTENT -Path ($TempFoldertoUse+'DiskPartScriptClean.txt') "Clean"
        
        NEW-ITEM -Path ($TempFoldertoUse+'DiskPartScriptConvertMBR.txt') -ItemType file -force | OUT-NULL
        ADD-CONTENT -Path ($TempFoldertoUse+'DiskPartScriptConvertMBR.txt') $SelectDiskLine
        ADD-CONTENT -Path ($TempFoldertoUse+'DiskPartScriptConvertMBR.txt') "Convert MBR"

        NEW-ITEM -Path ($TempFoldertoUse+'DiskPartScriptClearReadOnlyAttribute.txt') -ItemType file -force | OUT-NULL
        ADD-CONTENT -Path ($TempFoldertoUse+'DiskPartScriptClearReadOnlyAttribute.txt') $SelectDiskLine
        ADD-CONTENT -Path ($TempFoldertoUse+'DiskPartScriptClearReadOnlyAttribute.txt') "attributes disk clear readonly"
        
        Write-InformationMessage 'Clearing read only attribute if set'
        $ClearReadOnlyAttribute = (DISKPART.exe /S ($TempFoldertoUse+'DiskPartScriptClearReadOnlyAttribute.txt'))
        Write-InformationMessage 'Read only attribute clear'   

        $Counter = 1
        do {
            Write-InformationMessage ('Attempting to Clean Disk using Diskpart. Attempt #'+$Counter)
            $CleanDiskOutput = (DISKPART.exe /S ($TempFoldertoUse+'DiskPartScriptClean.txt'))   
            $CleanDiskOutputLinetoCheck = $CleanDiskOutput[$CleanDisk.count-1] 
            if (($CleanDiskOutputLinetoCheck -match 'succeeded') `
                -or ($CleanDiskOutputLinetoCheck -match 'completata') `
                -or ($CleanDiskOutputLinetoCheck -match 'satisfactoriamente') `
                -or ($CleanDiskOutputLinetoCheck -match 'nettoyer') `
                -or ($CleanDiskOutputLinetoCheck -match 'bereinigt')){  
                Write-InformationMessage 'DiskPart has Cleaned the Disk'
                $IsSuccess = $true              
            }
            else {
                Write-InformationMessage 'Diskpart did not clean disk! '
                $IsSuccess = $false

            }
            $Counter ++
        } until (
            $Counter -gt 5 -or $IsSuccess -eq $true
        )
        if ($IsSuccess -eq $false){
            return $false
        }
        else{
            Write-InformationMessage 'Setting disk to MBR'
            $ConvertMBRDiskOutput = (DISKPART.exe /S ($TempFoldertoUse+'DiskPartScriptConvertMBR.txt'))
            Write-InformationMessage 'Disk set to MBR'   
            return $true
        }
}

function Get-Cylinders {
    param (
        $SizeofImage
    )
    
    $Heads = 16
    $Sectors = 63
    $BlockSize = 512
    $SizeofImageBytes = [decimal]$SizeofImage.TrimEnd('kb')*1024
    $Cylinders =  [math]::Floor($SizeofImageBytes/$Heads/$Sectors/$BlockSize) 
    return $Cylinders

}

function Get-AmigaPartitionSizeBlockBytes {
    param (
    )
    $Heads = 16
    $Sectors = 63
    $BlockSize = 512

    return $Heads*$Sectors*$BlockSize
}

function Get-StartEmptySpace {
    param (
      $OutputMessage
    )
    $EmptySpaceStart  = ' - Empty space found at sector '.Length
    $Length = $OutputMessage.Length
    return [decimal]$OutputMessage.Substring($EmptySpaceStart,$Length-$EmptySpaceStart)
  }

  function Get-WorkingPath {
    param (
        $CheckforEmptyFolder
    )
    $Msg_Header_NonEmpty = 'Non Empty Folder'
    $Msg_Body_NonEmpty = @"
You have selected a non-empty folder! Please select an empty folder.
"@  
    do {
        $WorkingPathtoReturn = Get-FolderPath -Message 'Select location for Working Folder (folder must be empty)' -RootFolder 'MyComputer' -ShowNewFolderButton
        if ($WorkingPathtoReturn){
            if ((Get-LocalvsNetwork -PathtoCheck $WorkingPathtoReturn -PreventNetworkPath 'LocalOnly') -eq 'Local'){
                if ($CheckforEmptyFolder -eq 'TRUE'){
                    $items = Get-ChildItem -Path $WorkingPathtoReturn -Recurse -Force | Where-Object {$_.Name -ne 'AmigaDownloads' -and $_.Name -ne 'AmigaImageFiles' -and $_.Name -ne 'FAT32Partition' -and $_.Name -ne 'HDFImage' -and $_.Name -ne 'OutputImage' -and $_.Name -ne 'Programs' -and $_.Name -ne 'Temp'}
                    if ($items.Count -ne 0){
                        $null = [System.Windows.MessageBox]::Show($Msg_Body_NonEmpty, $Msg_Header_NonEmpty,0,48)
                        $IsDefinedWorkingPath = $false
                    }
                    else{
                        $IsDefinedWorkingPath = $true 
                    }
                }
                else{
                    $IsDefinedWorkingPath = $true
                }
            }
        }
    } until (
        ($IsDefinedWorkingPath -eq $true) -or (-not $WorkingPathtoReturn) 
    )
    if ($IsDefinedWorkingPath -eq $true){
        $WorkingPathtoReturn = $WorkingPathtoReturn.TrimEnd('\')+'\' 
    } 
    return $WorkingPathtoReturn
}

function Update-ListofInstallFiles {
    param (              
    )
    $Script:ListofInstallFiles = Get-ListofInstallFiles -ListofInstallFilesCSV ($Script:InputFolder+'ListofInstallFiles.csv') |  Where-Object {$_.Kickstart_Version -eq $Script:KickstartVersiontoUse} | Sort-Object -Property 'InstallSequence'    
    $Script:ListofInstallFiles | Add-Member -NotePropertyName Path -NotePropertyValue $null
    $Script:ListofInstallFiles | Add-Member -NotePropertyName DrivetoInstall_VolumeName -NotePropertyValue $null    
    foreach ($InstallFileLine in $Script:ListofInstallFiles) {
        if ($InstallFileLine.DrivetoInstall -eq 'System'){
            $InstallFileLine.DrivetoInstall_VolumeName = $Script:VolumeName_System
        }
        foreach ($MatchedADF in $AvailableADFs ) {
            if ($InstallFileLine.ADF_Name -eq $MatchedADF.ADF_Name){
                $InstallFileLine.Path=$MatchedADF.Path
            }
            if ($MatchedADF.ADF_Name -match "GlowIcons"){
                $Script:GlowIconsADF = $MatchedADF.Path
            }
            if ($MatchedADF.ADF_Name -match "Storage"){
                $Script:StorageADF=$MatchedADF.Path
            }
            if ($MatchedADF.ADF_Name -match "Install"){
                $Script:InstallADF=$MatchedADF.Path
            }
        }          
    }             
}

function Remove-WorkingFolderData {
    param (
        $DefaultFolder,
        $AtEnd
    )
    
    if ($DefaultFolder -eq 'TRUE'){
        $WorkingFoldertouse = ($Script:Scriptpath+'Working Folder\')
    }
    else {
        $WorkingFoldertouse = $Script:WorkingPath 
    }
    if (Test-Path ($WorkingFoldertouse)){
        if ($AtEnd -eq 'TRUE'){
            $NewFolders = ($WorkingFoldertouse+'Programs\'),($WorkingFoldertouse+'AmigaDownloads\'),($WorkingFoldertouse+'Temp\'),($WorkingFoldertouse+'HDFImage\'),($WorkingFoldertouse+'AmigaImageFiles\'),($WorkingFoldertouse+'\FAT32Partition\')
        }
        else{
            $NewFolders = ($WorkingFoldertouse+'Temp\'),($WorkingFoldertouse+'OutputImage\'),($WorkingFoldertouse+'HDFImage\'),($WorkingFoldertouse+'AmigaImageFiles\'),($WorkingFoldertouse+'\FAT32Partition\')
        }
        foreach ($NewFolder in $NewFolders) {
            if (Test-Path $NewFolder){
                $null = Remove-Item ($NewFolder) -Recurse -force
            }
        }                     
    }
}

function Get-Emu68ImagerDocumentation {
    param (
        $LocationtoDownload
    )

   # $LocationtoDownload ='E:\PiStorm\Docs\'

    $DownloadURLs = "https://mja65.github.io/Emu68-Imager/index.html", `
                    "https://mja65.github.io/Emu68-Imager/requirements.html", `
                    "https://mja65.github.io/Emu68-Imager/download.html", `
                    "https://mja65.github.io/Emu68-Imager/installation.html",
                    "https://mja65.github.io/Emu68-Imager/quickstart.html", `
                    "https://mja65.github.io/Emu68-Imager/instructions.html", `
                    "https://mja65.github.io/Emu68-Imager/amigautilities.html", `
                    "https://mja65.github.io/Emu68-Imager/packages.html", `
                    "https://mja65.github.io/Emu68-Imager/included.html", `
                    "https://mja65.github.io/Emu68-Imager/faqs.html", `
                    "https://mja65.github.io/Emu68-Imager/support.html", `
                    "https://mja65.github.io/Emu68-Imager/credits.html", `
                    "https://mja65.github.io/Emu68-Imager/images/screenshot1.png", `
                    "https://mja65.github.io/Emu68-Imager/images/screenshot2.png"

    foreach ($URL in $DownloadURLs){
        If ((Split-Path $URL -Leaf) -eq 'index.html'){
            $OutfileLocation = $LocationtoDownload 
        }
        elseif (((Split-Path $URL -Leaf) -eq 'screenshot1.png') -or ((Split-Path $URL -Leaf) -eq 'screenshot2.png')) {
            $OutfileLocation = $LocationtoDownload+'images\'
        }
        else {
            $OutfileLocation = ($LocationtoDownload+'html\')
        }
        if (-not (test-path $OutfileLocation)){
                $null = New-Item $OutfileLocation -ItemType Directory
        }
        Invoke-WebRequest $URL -OutFile ($OutfileLocation+(Split-Path $URL -Leaf))

        if (($OutfileLocation+(Split-Path $URL -Leaf)).IndexOf('.html') -gt 0){
            $URLContent = Get-Content ($OutfileLocation+(Split-Path $URL -Leaf))
            $RevisedURLContent = $null
            foreach ($Line in $URLContent){
                If ((Split-Path $URL -Leaf) -eq 'index.html'){
                    $Line = $Line -replace '<a href="/Emu68-Imager/', '<a href="./html/'
                    $Line = $Line -replace '<a href="https://mja65.github.io/Emu68-Imager/', '<a href="./index.html'
                    $Line = $Line -replace '<img src="/Emu68-Imager/images' , '<img src="./images'
                }
                else{
                    $Line = $Line -replace '<a href="/Emu68-Imager/', '<a href="../html/'
                    $Line = $Line -replace '<a href="https://mja65.github.io/Emu68-Imager/', '<a href="../index.html'
                    $Line = $Line -replace '<img src="/Emu68-Imager/images' , '<img src="../images'
                }
                $RevisedURLContent += $Line+"`r`n"
            }
            Set-Content -Path ($OutfileLocation+(Split-Path $URL -Leaf)+'NEW') -Value $RevisedURLContent
            $null = remove-item ($OutfileLocation+(Split-Path $URL -Leaf))
            $null = rename-item ($OutfileLocation+(Split-Path $URL -Leaf)+'NEW') ($OutfileLocation+(Split-Path $URL -Leaf)) 
            If ((Split-Path $URL -Leaf) -eq 'index.html'){
                if (-not (Test-Path ($LocationtoDownload+'html\'))){
                    $Null = New-Item ($LocationtoDownload+'html\') -ItemType Directory   
                }
                $Null = Copy-Item -Path ($OutfileLocation+(Split-Path $URL -Leaf)) -Destination ($LocationtoDownload+'html\Emu68-Imager.html')
            }
        }
    }
}

function Get-ListofInstallFiles {
    param (
        $ListofInstallFilesCSV
        )       

        #$ListofInstallFilesCSV = ($InputFolder+'ListofInstallFiles.csv')

        $ListofInstallFilesImported = Import-Csv $ListofInstallFilesCSV -delimiter ';'

        $RevisedListofInstallFiles = [System.Collections.Generic.List[PSCustomObject]]::New()
        foreach ($Line in $ListofInstallFilesImported ) {
            $CountofVariables = ([regex]::Matches($line.Kickstart_Version, "," )).count
            if ($CountofVariables -gt 0){
                $Counter = 0
                do {
                    $RevisedListofInstallFiles += [PSCustomObject]@{
                        Kickstart_Version = ($line.Kickstart_Version -split ',')[$Counter] 
                        Kickstart_VersionFriendlyName = ($line.Kickstart_VersionFriendlyName -split ',')[$Counter] 
                        InstallSequence = $line.InstallSequence
                        ADF_Name = $line.ADF_Name
                        FriendlyName = $line.FriendlyName
                        AmigaFiletoInstall = $line.AmigaFiletoInstall
                        DrivetoInstall = $line.DrivetoInstall
                        LocationtoInstall = $line.LocationtoInstall
                        NewFileName = $line.NewFileName
                        ExcludedFolders = $line.ExcludedFolder
                        ExcludedFiles = $line.ExcludedFiles 
                        Uncompress = $line.Uncompress
                        ModifyScript = $line.ModifyScript
                        ScriptNameofChange = $line.ScriptNameofChange
                        ScriptInjectionStartPoint = $line.ScriptInjectionStartPoint
                        ScriptInjectionEndPoint = $line.ScriptInjectionEndPoint
                        ModifyInfoFileTooltype = $line.ModifyInfoFileTooltype
                    }
                    $counter ++
                } until (
                    $Counter -eq ($CountofVariables+1)
                )
            }
            else{
                $RevisedListofInstallFiles  += [PSCustomObject]@{
                    Kickstart_Version = $line.Kickstart_Version  
                    Kickstart_VersionFriendlyName = $line.Kickstart_VersionFriendlyName 
                    InstallSequence = $line.InstallSequence
                    ADF_Name = $line.ADF_Name
                    FriendlyName = $line.FriendlyName
                    AmigaFiletoInstall = $line.AmigaFiletoInstall
                    DrivetoInstall = $line.DrivetoInstall
                    LocationtoInstall = $line.LocationtoInstall
                    NewFileName = $line.NewFileName
                    ExcludedFolders = $line.ExcludedFolder
                    ExcludedFiles = $line.ExcludedFiles 
                    Uncompress = $line.Uncompress
                    ModifyScript = $line.ModifyScript
                    ScriptNameofChange = $line.ScriptNameofChange
                    ScriptInjectionStartPoint = $line.ScriptInjectionStartPoint
                    ScriptInjectionEndPoint = $line.ScriptInjectionEndPoint
                    ModifyInfoFileTooltype = $line.ModifyInfoFileTooltype
                }
            }
        }
        return $RevisedListofInstallFiles
}

function Get-ListofPackagestoInstall {
    param (
        $ListofPackagestoInstallCSV
        )       

        #$ListofPackagestoInstallCSV = ($InputFolder+'ListofPackagestoInstall.csv') 

        $ListofPackagestoInstallImported = Import-Csv $ListofPackagestoInstallCSV -delimiter ';'

        $RevisedListofPackagestoInstall = [System.Collections.Generic.List[PSCustomObject]]::New()
        foreach ($Line in $ListofPackagestoInstallImported) {
            $CountofVariables = ([regex]::Matches($line.KickstartVersion, "," )).count
            if ($CountofVariables -gt 0){
                $Counter = 0
                do {
                    $RevisedListofPackagestoInstall += [PSCustomObject]@{
                        InstallFlag = $line.InstallFlag
                        KickstartVersion = ($line.KickstartVersion -split ',')[$Counter] 
                        PackageName = $line.PackageName
                        SearchforUpdatedPackage = $line.SearchforUpdatedPackage
                        UpdatePackageSearchTerm = $line.UpdatePackageSearchTerm    
                        UpdatePackageSearchExclusionTerm  = $line.UpdatePackageSearchExclusionTerm
                        UpdatePackageSearchMinimumDate  = $line.UpdatePackageSearchMinimumDate  
                        Source = $line.Source     
                        InstallType = $line.InstallType       
                        SourceLocation = $line.SourceLocation          
                        FileDownloadName = $line.FileDownloadName         
                        PerformHashCheck = $line.PerformHashCheck    
                        Hash = $line.Hash        
                        FilestoInstall = $line.FilestoInstall        
                        DrivetoInstall = $line. DrivetoInstall    
                        LocationtoInstall = $line.LocationtoInstall    
                        CreateFolderInfoFile = $line.CreateFolderInfoFile    
                        NewFileName = $line.NewFileName       
                        ModifyUserStartup = $line.ModifyUserStartup  
                        ModifyStartupSequence = $line.ModifyStartupSequence 
                        StartupSequenceInjectionStartPoint = $line.StartupSequenceInjectionStartPoint
                        StartupSequenceInjectionEndPoint  =$line.StartupSequenceInjectionEndPoint
                        ModifyInfoFileTooltype = $line.ModifyInfoFileTooltype    
                        PiSpecificStorageDriver = $line.PiSpecificStorageDriver 
                    }
                    $counter ++
                } until (
                    $Counter -eq ($CountofVariables+1)
                )
            }
            else{
                $RevisedListofPackagestoInstall   += [PSCustomObject]@{
                    InstallFlag = $line.InstallFlag
                    KickstartVersion = $line.KickstartVersion 
                    PackageName = $line.PackageName
                    SearchforUpdatedPackage = $line.SearchforUpdatedPackage
                    UpdatePackageSearchTerm = $line.UpdatePackageSearchTerm    
                    UpdatePackageSearchExclusionTerm  = $line.UpdatePackageSearchExclusionTerm
                    UpdatePackageSearchMinimumDate  = $line.UpdatePackageSearchMinimumDate  
                    Source = $line.Source     
                    InstallType = $line.InstallType       
                    SourceLocation = $line.SourceLocation          
                    FileDownloadName = $line.FileDownloadName         
                    PerformHashCheck = $line.PerformHashCheck    
                    Hash = $line.Hash        
                    FilestoInstall = $line.FilestoInstall        
                    DrivetoInstall = $line. DrivetoInstall    
                    LocationtoInstall = $line.LocationtoInstall    
                    CreateFolderInfoFile = $line.CreateFolderInfoFile    
                    NewFileName = $line.NewFileName       
                    ModifyUserStartup = $line.ModifyUserStartup  
                    ModifyStartupSequence = $line.ModifyStartupSequence 
                    StartupSequenceInjectionStartPoint = $line.StartupSequenceInjectionStartPoint
                    StartupSequenceInjectionEndPoint  =$line.StartupSequenceInjectionEndPoint
                    ModifyInfoFileTooltype = $line.ModifyInfoFileTooltype    
                }
            }
        }
        return $RevisedListofPackagestoInstall
}

function Get-GUIADFKickstartReport {
    param (
        $Text,
        $Title,
        $DatatoPopulate,
        $WindowWidth,
        $WindowHeight,
        $DataGridWidth,
        $DataGridHeight,
        $GridLinesVisibility,
        $FieldsSorted
    )
     
    # $Title = 'ADFs to be used'
    # $Text = 'The following ADFs will be used:'
    # $DatatoPopulate = $Script:AvailableADFs 
    # $WindowWidth =700 
    # $WindowHeight =350 
    # $DataGridWidth =570 
    # $DataGridHeight =200 
    # $GridLinesVisibility ='None' 
    # $FieldsSorted = ('Status','ADF Name','Path')

    $inputXML_ADFKickstartReporting = 
@"
<Window x:Name="Window" 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            xmlns:local="clr-namespace:WpfApp14"
            mc:Ignorable="d"
               Title="$Title" Height="$WindowHeight" Width="$WindowWidth" HorizontalAlignment="Center" VerticalAlignment="Center" Topmost="True" WindowStartupLocation="CenterOwner">
    <Grid Background="#FFE5E5E5">
        <DataGrid Name="Datagrid" IsReadOnly="True"  HorizontalAlignment="Center" Margin="5,40,0,0" Height="200" VerticalAlignment="Top" HorizontalScrollBarVisibility="Auto" GridLinesVisibility="$GridLinesVisibility" HorizontalGridLinesBrush="#FF505050" VerticalGridLinesBrush="#FF505050" >

        </DataGrid>
        <Button x:Name="OK_Button" Content="OK" HorizontalAlignment="Center" Margin="5,5,5,5" VerticalAlignment="Bottom" Width="40"/>
        <TextBox x:Name="TextBox" HorizontalAlignment="Center"  Margin="7,0,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
    </Grid>

</Window>
"@

    $XAML_ADFKickstartReporting = Format-XMLtoXAML -inputXML $inputXML_ADFKickstartReporting
    $Form_ADFKickstartReporting = Read-XAML -xaml $XAML_ADFKickstartReporting 
    Remove-Variable -Scope Script -Name WPF_UI_ADF_*
    $XAML_ADFKickstartReporting.SelectNodes("//*[@Name]") | ForEach-Object{
    #    "Trying item $($_.Name)";
        try {
            Set-Variable -Scope Script -Name "WPF_UI_ADF_$($_.Name)" -Value $Form_ADFKickstartReporting.FindName($_.Name) -ErrorAction Stop
        }
        catch{
            throw
        }
    }
   
    $Form_ADFKickstartReporting.Top=300
    $Form_ADFKickstartReporting.Left=300

    If ($FieldsSorted){
        $Fields = $FieldsSorted
    }
    else{
        $Fields = (($DatatoPopulate | Get-Member -MemberType NoteProperty).Name)
    }


    $Datatable = New-Object System.Data.DataTable
    [void]$Datatable.Columns.AddRange($Fields)
    foreach ($line in $DatatoPopulate)
    {
        $Array = @()
        Foreach ($Field in $Fields)
        {
            $array += $line.$Field
        }
        [void]$Datatable.Rows.Add($array)
    }
     
    $WPF_UI_ADF_TextBox.Text = $Text
    
    $WPF_UI_ADF_Datagrid.ItemsSource = $Datatable.DefaultView
    if ($DataGridWidth){
        $WPF_UI_ADF_Datagrid.Width = "$DataGridWidth"
    }
    if($DataGridHeight){
        $WPF_UI_ADF_Datagrid.Height = "$DataGridHeight"
    }
   

    $WPF_UI_ADF_OK_Button.Add_Click({
        $Form_ADFKickstartReporting.Close() | out-null
    })
    
    $Form_ADFKickstartReporting.ShowDialog() | out-null

}

function Confirm-NoLockonFile {
    param (
        $FileToTest,
        $SecondsToTest,
        $SecondsBetweenRetries
    )
    
    $startDate = Get-Date
    $IsSuccess = $false
    $Counter = 1    
    Start-Sleep -Seconds 1

    while ($IsSuccess -eq $false -and $startDate.AddSeconds($SecondsToTest) -gt (Get-Date)) {
        try {
            Write-InformationMessage -Message ('Checking that there is no lock on .HDF file. Attempt #'+$Counter) -NoLog
            $FileStream = [System.IO.File]::Open($FileToTest,'Open','write')
        }
        catch {
            Write-InformationMessage -Message 'File still locked' -NoLog
            $Counter ++
            Start-Sleep -Seconds $SecondsBetweenRetries
        }
        if ($FileStream.CanWrite -eq $true){
            $FileStream.Close()
            $FileStream.Dispose()
            Write-InformationMessage -Message 'File is not locked!'
            $IsSuccess = $true
        }
             
    }
   
    if ($IsSuccess -eq $true){
        return $true
    }
    else{
        return $false
    }
}

function Get-LocalvsNetwork {
    param (
        $PathtoCheck,
        $PreventNetworkPath
    )

    $Msg_Header = 'Network Locations Selected'
    $MSG_Body_Error = 
@"
You have chosen a network location. Only paths on local drives allowed! 
"@   
$MSG_Body_Error_UNC = 
@"
You have chosen an UNC network location ('\\....'). Only mapped network drives or local drives allowed! 
"@   

    $MSG_Body_Warning = 
@"
You have chosen a network location. Please ensure that you have appropriate access rights to the folder! 
"@   


 #   $PathtoCheck = 'Y:\'
#    $PathtoCheck = $PathtoCheck.TrimEnd(':\')
    If (($PathtoCheck.Length -ge 2) -and ($PathtoCheck.Substring(0,2) -eq '\\')){
        $result = 'Network-UNC'
    }
    else{
        $EndPosition = $PathtoCheck.IndexOf(':\')
        $DriveLetter = $PathtoCheck.Substring(0,$EndPosition)
        $MappedDrives = Get-PSDrive -PSProvider FileSystem | Select-Object Name, DisplayRoot | Where-Object {$null -ne $_.DisplayRoot} | Where-Object {$_.Name -eq $DriveLetter}
        $AllDrives =  Get-PSDrive -PSProvider FileSystem | Select-Object Name | Where-Object {$null -eq $_.DisplayRoot} | Where-Object {$_.Name -eq $DriveLetter}
    
        if ($AllDrives){
            if ($MappedDrives){
                $result = 'Network-MappedDrive'
            }
            else {
                $result = 'Local'
            }
        }
        else{
            $result = 'Invalid'
        }   
    }
    
    If ($PreventNetworkPath -eq 'LocalOnly'){
        If (($result -eq 'Network-MappedDrive')  -or ($result -eq 'Network-UNC')){
            $null = [System.Windows.MessageBox]::Show($MSG_Body_Error, $Msg_Header,0,16)
        }
    }
    elseif ($PreventNetworkPath -eq 'LocalandMappedDrivesOnly'){
        if($result -eq 'Network-UNC'){
            $null = [System.Windows.MessageBox]::Show($MSG_Body_Error_UNC, $Msg_Header,0,16)
        }
        elseif ($result -eq 'Network-MappedDrive') {
            $null = [System.Windows.MessageBox]::Show($MSG_Body_Warning, $Msg_Header,0,48)
        }
    }
    return $result    
}

### End Functions

######################################################################### End Functions #############################################################################################################


#$WPF_UI_DiskPartition_Grid.ColumnDefinitions
####################################################################### GUI XML for Main Environment ##################################################################################################

$inputXML_UserInterface = @"
<Window x:Name="MainWindow" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp14"
        mc:Ignorable="d"
           Title="Emu68 Imager v$Script:Version" Height="700" Width="1054" HorizontalAlignment="Left" VerticalAlignment="Top" ResizeMode="NoResize">
    <Grid x:Name="Overall_Grid" Background="Transparent" Visibility="Visible">
        <Grid x:Name="Main_Grid" Background="#FFE5E5E5" Visibility="Visible" >
            <GroupBox x:Name="DiskSetup_GroupBox" Header="Disk Setup" Margin="0,60,0,0" VerticalAlignment="Top" Height="173" Background="Transparent" HorizontalAlignment="Center">
                <Grid Background="Transparent">
                    <Grid x:Name="DiskPartition_Grid" ToolTip="Once you have selected a SD card, drag the sliders to resize the partitions" Background="Transparent" Height="50" Width="1028" MaxWidth="1028" VerticalAlignment="Center">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="50"/>
                        </Grid.RowDefinitions>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*" />
                            <ColumnDefinition Width="auto" />
                            <ColumnDefinition Width="*" />
                            <ColumnDefinition Width="auto" />
                            <ColumnDefinition Width="*" />
                            <ColumnDefinition Width="auto" />
                            <ColumnDefinition Width="*" />
                            <ColumnDefinition Width="auto" />
                            <ColumnDefinition Width="*" />
                        </Grid.ColumnDefinitions>
                        <ListView x:Name="Fat32Size_Listview" Grid.Row="0" Grid.Column="0" Background="#FF3B67A2" 
                  HorizontalAlignment="Stretch" 
                  VerticalAlignment="Stretch" 
                  ScrollViewer.VerticalScrollBarVisibility="Disabled"  
                  ScrollViewer.HorizontalScrollBarVisibility="Disabled" IsTabStop="True"
              >
                            <ListViewItem x:Name="FAT32Size_ListViewItem" Content="FAT32" Height="50" Width="Auto" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </ListView>
                        <GridSplitter x:Name="FAT32_Splitter" Grid.Row="0" Grid.Column="1" Margin="2,0,2,0"
               Width="3" Background="Purple" 
               VerticalAlignment="Stretch" 
               HorizontalAlignment="Center" 
               IsEnabled="False" 
              />
                        <ListView x:Name="WorkbenchSize_Listview" Grid.Row="0" Grid.Column="2" Background="#FFFFA997" 
                  HorizontalAlignment="Stretch" 
                  VerticalAlignment="Stretch" 
                  ScrollViewer.VerticalScrollBarVisibility="Disabled"  
                  ScrollViewer.HorizontalScrollBarVisibility="Disabled" IsTabStop="True"
           
                  >
                            <ListViewItem x:Name="WorkbenchSize_ListViewItem" Content="Workbench" Height="50" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </ListView>
                        <GridSplitter x:Name="Workbench_Splitter" Grid.Row="0" Grid.Column="3" Margin="2,0,2,0"
               Width="3" Background="Purple" 
               VerticalAlignment="Stretch" 
               HorizontalAlignment="Center" 
               IsEnabled="False" 
              />
                        <ListView x:Name="WorkSize_Listview" Grid.Row="0" Grid.Column="4" Background="#FFAA907C" 
                  HorizontalAlignment="Stretch" 
                  VerticalAlignment="Stretch" 
                  ScrollViewer.VerticalScrollBarVisibility="Disabled"  
                  ScrollViewer.HorizontalScrollBarVisibility="Disabled" IsTabStop="True"
              >
                            <ListViewItem x:Name="WorkSize_ListViewItem" Content="Work" Height="50" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </ListView>
                        <GridSplitter x:Name="Work_Splitter" Grid.Row="0" Grid.Column="5" Margin="2,0,2,0"
               Width="3" Background="Purple" 
               VerticalAlignment="Stretch" 
               HorizontalAlignment="Center" 
               IsEnabled="False" 
              />
                        <ListView x:Name="FreeSpace_Listview" Grid.Row="0" Grid.Column="6" Background="#FF7B7B7B" 
                  HorizontalAlignment="Stretch" 
                  VerticalAlignment="Stretch" 
                  ScrollViewer.VerticalScrollBarVisibility="Disabled"  
                  ScrollViewer.HorizontalScrollBarVisibility="Disabled" IsTabStop="True"
              >
                            <ListViewItem x:Name="FreeSpace_ListViewItem" Content="Free Space" Height="50" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </ListView>
                        <GridSplitter x:Name="Image_Splitter" Grid.Row="0" Grid.Column="7" Margin="2,0,2,0"
               Width="3" Background="Purple" 
               VerticalAlignment="Stretch" 
               HorizontalAlignment="Center" 
               IsEnabled="False" 
              />
                        <ListView x:Name="Unallocated_Listview" Grid.Row="0" Grid.Column="8" Background="#FFAFAFAF" 
                    HorizontalAlignment="Stretch" 
                    VerticalAlignment="Stretch" 
                    ScrollViewer.VerticalScrollBarVisibility="Disabled"  
                    ScrollViewer.HorizontalScrollBarVisibility="Disabled" IsTabStop="True"
                >
                            <ListViewItem x:Name="Unallocated_ListViewItem" Content="Not Used" Height="50" HorizontalContentAlignment="Center" HorizontalAlignment="Center" Focusable="False" VerticalAlignment="Center"/>
                        </ListView>
                    </Grid>


                    <TextBox x:Name="Fat32Size_Label" HorizontalAlignment="Left" Margin="36,104,0,0" TextWrapping="Wrap" Text="FAT32 (GiB)" VerticalAlignment="Top" Width="82" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="WorkbenchSize_Label" HorizontalAlignment="Left" Margin="178,104,0,0" TextWrapping="Wrap" Text="Workbench (GiB)" VerticalAlignment="Top" Width="113" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="WorkSize_Label" HorizontalAlignment="Left" Margin="347,104,0,0" TextWrapping="Wrap" Text="Work (GiB)" VerticalAlignment="Top" Width="63" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="WorkSizeNote_Label" HorizontalAlignment="Left" Margin="410,104,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="16" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontSize="17" />
                    <TextBox x:Name="Unallocated_Label" HorizontalAlignment="Left" Margin="875,104,0,0" TextWrapping="Wrap" Text="Not Used (GiB)" VerticalAlignment="Top" Width="105" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="ImageSize_Label" HorizontalAlignment="Left" Margin="653,104,0,0" TextWrapping="Wrap" Text="Total Image Size (GiB)" VerticalAlignment="Top" Width="144" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="FreeSpace_Label" HorizontalAlignment="Left" Margin="510,104,0,0" TextWrapping="Wrap" Text="Free Space (GiB)" VerticalAlignment="Top" Width="108" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

                    <TextBox x:Name="FAT32Size_Value" Text="" HorizontalAlignment="Left" Margin="20,126,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                    <TextBox x:Name="WorkbenchSize_Value" Text="" HorizontalAlignment="Left" Margin="173,126,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                    <TextBox x:Name="WorkSize_Value" Text="" HorizontalAlignment="Left" Margin="317,126,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                    <TextBox x:Name="Unallocated_Value" Text="0" HorizontalAlignment="Left" Margin="884,126,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" BorderBrush="Transparent"/>
                    <TextBox x:Name="ImageSize_Value" Text="" HorizontalAlignment="Left" Margin="664,126,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                    <TextBox x:Name="FreeSpace_Value" Text="" HorizontalAlignment="Left" Margin="493,126,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>

                    <Rectangle x:Name="Fat32_Key" HorizontalAlignment="Left" Height="10" Margin="22,110,0,0" VerticalAlignment="Top" Width="10" Fill="#FF3B67A2" />
                    <Rectangle x:Name="Workbench_Key" HorizontalAlignment="Left" Height="10" Margin="165,110,0,0" VerticalAlignment="Top" Width="10" Fill="#FFFFA997"  />
                    <Rectangle x:Name="Work_Key" HorizontalAlignment="Left" Height="10" Margin="328,110,0,0" VerticalAlignment="Top" Width="10" Fill="#FFAA907C"  />
                    <Rectangle x:Name="FreeSpace_Key" HorizontalAlignment="Left" Height="10" Margin="489,110,0,0" VerticalAlignment="Top" Width="10" Fill="#FF7B7B7B" />
                    <Rectangle x:Name="Unallocated_Key" HorizontalAlignment="Left" Height="10" Margin="860,110,0,0" VerticalAlignment="Top" Width="10" Fill="#FFAFAFAF"  />

                    <TextBox x:Name="MediaSelect_Label" HorizontalAlignment="Left" Margin="10,10,0,0" TextWrapping="Wrap" Text="Select Media to Use" VerticalAlignment="Top" Width="140" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontWeight="Bold" FontSize="14"/>
                    <ComboBox x:Name="MediaSelect_DropDown" ToolTip="Select the SD card you wish to use" HorizontalAlignment="Left" Margin="160,8,0,0" VerticalAlignment="Top" Width="340"/>
                    <Button x:Name="MediaSelect_Refresh" ToolTip="Refresh available SD cards on your PC" Content="Refresh Available Media" HorizontalAlignment="Left" Margin="510,0,0,0" VerticalAlignment="Top" Width="150" Height="40" Background="#FF6688BB" Foreground="White" FontWeight="Bold" BorderBrush="Transparent"/>
                    <Button x:Name="DefaultAllocation_Refresh" Content="Reset Partitions to Default" HorizontalAlignment="Right" Margin="0,0,10,0" VerticalAlignment="Top" Width="160" Height="40" Background="#FF6688BB" Foreground="White" FontWeight="Bold" BorderBrush="Transparent"/>
                </Grid>
            </GroupBox>
            <GroupBox x:Name="SourceFiles_GroupBox" Header="Source Files" Height="200" Background="Transparent" Margin="7,235,0,128" Width="500" VerticalAlignment="Top" HorizontalAlignment="Left">
                <Grid Background="Transparent" HorizontalAlignment="Left" VerticalAlignment="Top">
                <TextBox x:Name="KickstartVersion_Label" HorizontalAlignment="Left" Margin="10,10,0,0" TextWrapping="Wrap" Text="Select OS Version" VerticalAlignment="Top" Width="200" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center" FontWeight="Bold" FontSize="14"/>
                    <ComboBox x:Name="KickstartVersion_DropDown" ToolTip="Select the Kickstart version you wish to use (e.g. 3.1 or 3.2)" HorizontalAlignment="Left" Margin="10,32,0,0" VerticalAlignment="Top" Width="245"/>

                    <Button x:Name="ADFpath_Button" Content="Click to set custom ADF folder" HorizontalAlignment="Left" Margin="10,94,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
                    <Button x:Name="ADFpath_Button_Check" ToolTip="Check availability of ADF files" Content="Check" HorizontalAlignment="Left" Margin="215,94,0,0" VerticalAlignment="Top"  Width="40" Height="30" FontSize="10"/>
                    <TextBox x:Name="ADFPath_Label" HorizontalAlignment="Left" Margin="263,100,0,0" TextWrapping="Wrap" Text="Using default ADF folder" VerticalAlignment="Top" Width="260" Height="20"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

                    <Button x:Name="Rompath_Button" Content="Click to set custom Kickstart folder" HorizontalAlignment="Left" Margin="10,59,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
                    <Button x:Name="Rompath_Button_Check" ToolTip="Check availability of Kickstart file" Content="Check" HorizontalAlignment="Left" Margin="215,59,0,0" VerticalAlignment="Top"  Width="40" Height="30" FontSize="10"/>
                    <TextBox x:Name="ROMPath_Label" HorizontalAlignment="Left" Margin="263,65,0,0" TextWrapping="Wrap" Text="Using default Kickstart folder" VerticalAlignment="Top" Width="260" Height="20"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

                    <Button x:Name="MigratedFiles_Button" Content="Click to set Transfer folder" HorizontalAlignment="Left" Margin="10,129,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
                    <TextBox x:Name="MigratedPath_Label" HorizontalAlignment="Left" Margin="263,139,0,0" TextWrapping="Wrap" Text="No transfer path selected" VerticalAlignment="Top" Width="260" Height="20"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

                </Grid>
            </GroupBox>
            <GroupBox x:Name="Settings_GroupBox" Header="Settings" Height="150" Background="Transparent" Margin="0,235,10,128" Width="500" VerticalAlignment="Top" HorizontalAlignment="Right">
                <Grid>
                    <ComboBox x:Name="ScreenMode_Dropdown" ToolTip="Select if you wish to use a specific output resolution on your Raspberry Pi" HorizontalAlignment="Left" Margin="10,26,0,0" VerticalAlignment="Top" Width="375"/>
                    <TextBox x:Name="ScreenMode_Label" HorizontalAlignment="Center" Margin="10,0,0,0" TextWrapping="Wrap" Width="320" Text="Select ScreenMode for Raspberry Pi to Output" VerticalAlignment="Top" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center" FontWeight="Bold" FontSize="14"/>
   
                    <TextBox x:Name="SSID_Label" HorizontalAlignment="Left" Margin="12,77,0,0" TextWrapping="Wrap" Text="Enter your SSID" VerticalAlignment="Top" Width="150" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="Password_Label" HorizontalAlignment="Left" Margin="6,100,0,0" TextWrapping="Wrap" Text="Enter your Wifi password"  VerticalAlignment="Top" Width="150" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center"/>
                    <TextBox x:Name="SSID_Textbox" ToolTip="Set your SSID for wifi on the Amiga (leave empty if you wish to configure on the Amiga)" HorizontalAlignment="Left" Margin="187,77,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="200" />
                    <TextBox x:Name="Password_Textbox" ToolTip="Set your password for wifi on the Amiga (leave empty if you wish to configure on the Amiga)" HorizontalAlignment="Left" Margin="187,100,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="200" />
                    <TextBox x:Name="WIfiSettings_Label" HorizontalAlignment="Center" Visibility="Visible" TextWrapping="Wrap" Text="WiFi Settings" VerticalAlignment="Center" Width="120" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center" Margin="0,-4,0,0" Height="20" FontWeight="Bold" FontSize="14"/>

                </Grid>

            </GroupBox>
            <GroupBox x:Name="RunOptions_GroupBox" Header="Run Options" Margin="7,435,0,0" Background="Transparent" HorizontalAlignment="Left" Width="500" VerticalAlignment="Top" >
                <Grid Background="Transparent" >
                    <CheckBox x:Name="SetUpDiskOnly_CheckBox" ToolTip="Partition the SD card, copy the Emu68 and Kickstart files to the FAT32 partition. Amiga partitions will be empty." Content="Partition disk and install Emu68 only. Do not install packages." HorizontalAlignment="Left" Margin="7,5,0,0" Height="15" VerticalAlignment="Top"/>
                    <CheckBox x:Name="ImageOnly_CheckBox" Content="Do not write to SD card. A .img file will be created for later writing to disk." HorizontalAlignment="Left" Margin="7,25,0,0" Height="15" VerticalAlignment="Top"/>
                    <CheckBox x:Name="DeleteFiles_CheckBox" Content="Delete ALL files from Working Folder when done" HorizontalAlignment="Left" Margin="7,45,0,0" Height="15" VerticalAlignment="Top"/>
                    <CheckBox x:Name="SkipEmptySpace_CheckBox" Visibility="Hidden" Content="Skip empty space (only applicable if writing to SD Card)." ToolTip="Unchecking this option will copy ALL sectors to the SD card which will take a long time for large SD cards"  IsChecked = "TRUE" HorizontalAlignment="Left" Margin="7,45,0,0" Height="15" VerticalAlignment="Top"/>
                  <Button x:Name="Workingpath_Button" ToolTip="Set this if you wish to use a different folder to run the tool (e.g. you have insufficient space in the default path)" Content="Click to set custom Working folder" HorizontalAlignment="Left" Margin="7,65,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
                 <TextBox x:Name="Workingpath_Label" HorizontalAlignment="Left" Margin="212,70,0,0" TextWrapping="Wrap" Text="Using default Working folder" VerticalAlignment="Top" Width="260" Height="20" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

                    </Grid>
            </GroupBox>
            <Button x:Name="Start_Button" Content="Missing information and/or insufficient space on Work partition for transferred files! Press button to see further details" HorizontalAlignment="Center" Margin="0,610,0,0" VerticalAlignment="Top" Width="890" Height="40" Background = "Red" Foreground="Black" BorderBrush="Transparent"/>
            <GroupBox x:Name="Space_GroupBox" Header="Space Requirements" Height="170" Background="Transparent" Margin="0,385,10,0" Width="500" VerticalAlignment="Top" HorizontalAlignment="Right">
                <Grid>

                    <TextBox x:Name="RequiredSpace_TextBox" HorizontalAlignment="Left" Margin="20,57,0,0" TextWrapping="Wrap" Text="Required space to run tool is:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="RequiredSpaceValue_TextBox" HorizontalAlignment="Right" Margin="0,57,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                    <TextBox x:Name="AvailableSpace_TextBox" HorizontalAlignment="Left" Margin="20,77,0,0" TextWrapping="Wrap" Text="Free space after tool is run:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontWeight="Bold"/>
                    <TextBox x:Name="AvailableSpaceValue_TextBox" HorizontalAlignment="Right" Margin="0,77,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Green" Foreground="White" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                    <TextBox x:Name="RequiredSpaceTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="20,10,0,0" TextWrapping="Wrap" Text="Required space for transferred files:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                    <TextBox x:Name="RequiredSpaceValueTransferredFiles_TextBox" HorizontalAlignment="Right" Margin="0,10,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                    <TextBox x:Name="AvailableSpaceTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="20,31,0,0" TextWrapping="Wrap" Text="Free space after files transferred is:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontWeight="Bold"/>
                    <TextBox x:Name="AvailableSpaceValueTransferredFiles_TextBox" HorizontalAlignment="Right" Margin="0,31,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                    <TextBox x:Name="RequiredSpaceMessage_TextBox" HorizontalAlignment="Left" Margin="20,107,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="358" BorderBrush="Transparent" Foreground="Red" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" Focusable="False" Height="35" IsHitTestVisible="False"/>
                </Grid>

            </GroupBox>
            <TextBox x:Name="WorkSizeNoteFooter_Label" HorizontalAlignment="Left" Margin="15,585,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="480" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
       <Button x:Name="Documentation_Button" ToolTip="Browser will open and display documentation on how to use the tool" Content="Click for Documentation" HorizontalAlignment="Right" Margin="0,10,7,0" VerticalAlignment="Top" Height="50" Width="275" FontSize="18" BorderBrush="Transparent" Background="#FF6688BB" FontWeight="Bold" Foreground="White"/>
            
            <Button x:Name="LoadSettings_Button" ToolTip="Load settings from a file" Content="Load Settings" HorizontalAlignment="Right" Margin="0,10,290,0" VerticalAlignment="Top" Height="20" Width="110" BorderBrush="Transparent" Foreground="White" Background="#FF6688BB" FontWeight="Bold"/>
            <Button x:Name="SaveSettings_Button" ToolTip="Save settings to a file" Content="Save Settings" HorizontalAlignment="Right" Margin="0,40,290,0" VerticalAlignment="Top" Height="20" Width="110" BorderBrush="Transparent" Foreground="White" Background="#FF6688BB" FontWeight="Bold"/>
            <TextBox x:Name="ToolTitle" HorizontalAlignment="Left" Height="50" Margin="7,0,0,0" TextWrapping="Wrap" Text="Emu68 Imager " VerticalAlignment="Top" Width="260" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontSize="36" FontWeight="Bold"/>
           
                  </Grid>
        <Grid x:Name="Reporting_Grid" Background="#FFE5E5E5" Visibility="Hidden">
            <Button x:Name="GoBack_Button" Content="Back" HorizontalAlignment="Left" Margin="20,523,0,0" Background="red" VerticalAlignment="Top" Height="40" Width="200"/>
            <Button x:Name="Process_Button" Content="Run" HorizontalAlignment="Right" Margin="0,523,20,0" Background="green" VerticalAlignment="Top" Height="40" Width="200"/>

              <TextBox x:Name="Reporting_Header_TextBox" HorizontalAlignment="Center" Margin="0,55,0,0" TextWrapping="Wrap" Text="Tool will be run with the following options:  " VerticalAlignment="Top" Width="438" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center" FontWeight="Bold" FontSize="14"/>

             <TextBox x:Name="DiskName_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,110,0,0" TextWrapping="Wrap" Text="DiskName to Write:" VerticalAlignment="Top" Width="260" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
            <TextBox x:Name="DiskNameValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,110,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="ScreenMode_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,130,0,0" TextWrapping="Wrap" Text="ScreenMode to Use:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="ScreenModeValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,130,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

            <TextBox x:Name="Kickstart_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,150,0,0" TextWrapping="Wrap" Text="Kickstart to Use:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
            <TextBox x:Name="KickstartValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,150,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="SSID_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,170,0,0" TextWrapping="Wrap" Text="SSID to configure:" VerticalAlignment="Top" Width="260" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
            <TextBox x:Name="SSIDValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,170,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="Password_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,190,0,0" TextWrapping="Wrap" Text="Password to set:" VerticalAlignment="Top" Width="260" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="PasswordValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,190,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="ImageSize_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,210,0,0" TextWrapping="Wrap" Text="Total Image Size:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="ImageSizeValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,210,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="Fat32Size_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,230,0,0" TextWrapping="Wrap" Text="Fat32 Size:" VerticalAlignment="Top" Width="260" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="Fat32SizeValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,230,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="WorkbenchSize_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,250,0,0" TextWrapping="Wrap" Text="Workbench Size:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="WorkbenchSizeValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,250,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="WorkSize_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,270,0,0" TextWrapping="Wrap" Text="Work Size:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
            <TextBox x:Name="WorkSizeValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,270,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="WorkingPath_Detail_TextBox" HorizontalAlignment="Left" Margin="100,290,0,0" TextWrapping="Wrap" Text="Working Folder:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="WorkingPathValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,290,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="RomPath_Detail_TextBox" HorizontalAlignment="Left" Margin="100,310,0,0" TextWrapping="Wrap" Text="Rom Path:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="RomPathValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,310,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" />

            <TextBox x:Name="ADFPath_Detail_TextBox" HorizontalAlignment="Left" Margin="100,330,0,0" TextWrapping="Wrap" Text="ADF Path:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="ADFPathValue_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,330,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="TransferPath_Detail_TextBox" HorizontalAlignment="Left" Margin="100,350,0,0" TextWrapping="Wrap" Text="Transfer Path:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="TransferPathValue_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,350,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="WriteImageOnly_Reporting_Detail_TextBox" HorizontalAlignment="Left" Margin="100,370,0,0" TextWrapping="Wrap" Text="Write Image File Only:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="WriteImageOnlytoDiskValue_Reporting_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,370,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" />

            <TextBox x:Name="SetupDiskOnly_Detail_TextBox" HorizontalAlignment="Left" Margin="100,390,0,0" TextWrapping="Wrap" Text="Set disk up only:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="SetupDiskOnlyValue_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,390,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="DeleteAllWorkingPathFiles_Detail_TextBox" HorizontalAlignment="Left" Margin="100,410,0,0" TextWrapping="Wrap" Text="Delete ALL Working Folder files at completion:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />
            <TextBox x:Name="DeleteAllWorkingPathFilesValue_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,410,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

            <TextBox x:Name="LocationofImage_Detail_TextBox" HorizontalAlignment="Left" Margin="100,430,0,0" TextWrapping="Wrap" Text="Location of Image:" VerticalAlignment="Top" Width="260"  BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontWeight="Bold" />
            <TextBox x:Name="LocationofImageValue_Detail_TextBox" HorizontalAlignment="Right" HorizontalContentAlignment="Left" Margin="0,430,100,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="500" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" />

           
        </Grid>
    </Grid>
</Window>
"@

$XAML_UserInterface = Format-XMLtoXAML -inputXML $inputXML_UserInterface 
$Form_UserInterface = Read-XAML -xaml $XAML_UserInterface 

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
 
Remove-Variable -Name WPF_UI_*

$XAML_UserInterface.SelectNodes("//*[@Name]") | ForEach-Object{
#    "Trying item $($_.Name)";
    try {
        Set-Variable -Name "WPF_UI_$($_.Name)" -Value $Form_UserInterface.FindName($_.Name) -ErrorAction Stop
    }
    catch{
        throw
    }
}

# Get-FormVariables - If we need variables


#===========================================================================
# Use this space to add code to the various form elements in your GUI
#===========================================================================

$Script:ROMPath = $Script:UserLocation_Kickstarts 
$Script:ADFPath = $Script:UserLocation_ADFs 

#Width of bar

$Script:PartitionBarWidth =  1000
$Script:SetDiskupOnly = 'FALSE'
$Script:DeleteAllWorkingPathFiles = 'FALSE'
$DefaultDivisorFat32 = 15
$DefaultDivisorWorkbench = 15


$Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Script:WorkingPath)/1Kb # Available Space on Drive where script is running (Kilobytes)
$Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk
$Script:RequiredSpace_WorkingFolderDisk = 0 #In Kilobytes

$Script:Space_FilestoTransfer = 0 #In Kilobytes
$Script:WorkOverhead = 1024 #In Kilobytes
$Script:AvailableSpaceFilestoTransfer = 0 #In Kilobytes
$Script:SpaceThreshold_FilestoTransfer = 0
$Script:SizeofFilestoTransfer = 0 #In Kilobytes

$Script:SpaceThreshold_WorkingFolderDisk = 500*1024 #In Kilobytes
#$Script:SpaceThreshold_FilestoTransfer = 25*1024 #In Kilobytes

$WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk 
$WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk

$WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = '' 
$WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = ''

$Script:RemovableMedia = Get-RemovableMedia
foreach ($Disk in $Script:RemovableMedia){
    $WPF_UI_MediaSelect_Dropdown.AddChild($Disk.FriendlyName)
}

$WPF_UI_MediaSelect_Dropdown.Add_SelectionChanged({
    If (-not($Script:RemovableMedia)){
        $Script:RemovableMedia  = Get-RemovableMedia
    }
    if ($WPF_UI_MediaSelect_DropDown.SelectedItem) {
        $WPF_UI_FAT32_Splitter.IsEnabled = "True"
        $WPF_UI_Workbench_Splitter.IsEnabled = "True"
        $WPF_UI_Work_Splitter.IsEnabled = "True"
        $WPF_UI_Image_Splitter.IsEnabled = "True"
        $WPF_UI_WorkbenchSize_Value.IsEnabled = "True"
        $WPF_UI_WorkSize_Value.IsEnabled = "True"
        $WPF_UI_ImageSize_Value.IsEnabled = "True"
        $WPF_UI_FAT32Size_Value.IsEnabled = "True"
        $WPF_UI_FreeSpace_Value.IsEnabled = "True"

       

        foreach ($Disk in $Script:RemovableMedia){        
            if ($Disk.FriendlyName -eq $WPF_UI_MediaSelect_DropDown.SelectedItem){
                $Script:HSTDiskName = $Disk.HSTDiskName
                $Script:HSTDiskNumber = $Disk.HSTDiskNumber
                $Script:HSTDiskDeviceID =$Disk.DeviceID
                $Script:PartitionBarPixelperKB = [decimal](($PartitionBarWidth)/$Disk.SizeofDisk)
                $Script:PartitionBarKBperPixel = [decimal]($Disk.SizeofDisk/($PartitionBarWidth))
                break
            }

        }
        $Script:DiskFriendlyName = $WPF_UI_MediaSelect_DropDown.SelectedItem  
        $Script:SizeofDisk = $Disk.SizeofDisk
        if ($Script:IsLoadedSettings -ne $true){
            $Script:SizeofImage = $Script:SizeofDisk
        }
        $Script:SizeofFat32_Pixels_Minimum = [decimal]($Script:PartitionBarPixelperKB * $Script:Fat32Minimum) 
        $Script:SizeofPartition_System_Pixels_Minimum = [decimal]($Script:PartitionBarPixelperKB * $Script:WorkbenchMinimum)
        $Script:SizeofPartition_Other_Pixels_Minimum = [decimal]($Script:PartitionBarPixelperKB * $Script:WorkMinimum)

        $Script:SizeofFreeSpace_Pixels_Minimum = 0
        $Script:SizeofFreeSpace_Minimum = 0

        $Script:SizeofUnallocated_Pixels_Minimum = 0
        $Script:SizeofUnallocated_Minimum = 0
              
        if ($Script:IsLoadedSettings -ne $true){
            if ($Script:SizeofImage /$DefaultDivisorFat32 -ge $Script:Fat32DefaultMaximum){
                $Script:SizeofFAT32 = $Script:Fat32DefaultMaximum
                $Script:SizeofFAT32_Pixels = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofFAT32)   
            }
            else{
                $Script:SizeofFAT32 = $Script:SizeofImage/$DefaultDivisorFat32
                $Script:SizeofFAT32_Pixels = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofFAT32)   
            }
    
            if ($Script:SizeofImage/$DefaultDivisorWorkbench -ge $Script:WorkbenchDefaultMaximum){
                $Script:SizeofPartition_System = $Script:WorkbenchDefaultMaximum 
                $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB) 
            }
            else{
                $Script:SizeofPartition_System = $Script:SizeofImage/$DefaultDivisorWorkbench
                $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB) 
            }
    
            $Script:SizeofPartition_Other = ($Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32)
            $Script:SizeofPartition_Other_Pixels = [decimal]($Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB)
    
            $Script:SizeofUnallocated = $Script:SizeofDisk-$Script:SizeofImage
            $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
    
            $Script:SizeofFreeSpace = $Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32-$Script:SizeofPartition_Other
            $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
        }
        $Script:IsLoadedSettings = $null
        
        Set-PartitionMaximums

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
        
        $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck  $Script:WorkingPath)/1Kb 
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }

        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
              
        Set-GUIPartitionValues

        $null = Confirm-UIFields

    }
})
   


$WPF_UI_DefaultAllocation_Refresh.add_Click({
        if (($null -ne $Script:HSTDiskName)  -and ($Script:HSTDiskName -eq ('\'+(($WPF_UI_MediaSelect_DropDown.SelectedItem).Split(' ',3)[0])+(($WPF_UI_MediaSelect_DropDown.SelectedItem).Split(' ',3)[1])))){
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = 1
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 1

        $Script:SizeofFat32_Pixels_Minimum = [decimal]($Script:PartitionBarPixelperKB * $Script:Fat32Minimum) 
        $Script:SizeofPartition_System_Pixels_Minimum = [decimal]($Script:PartitionBarPixelperKB * $Script:WorkbenchMinimum)
        $Script:SizeofPartition_Other_Pixels_Minimum = [decimal]($Script:PartitionBarPixelperKB * $Script:WorkMinimum)
    
        $Script:SizeofFreeSpace_Pixels_Minimum = 0
        $Script:SizeofFreeSpace_Minimum = 0
    
        $Script:SizeofUnallocated_Pixels_Minimum = 0
        $Script:SizeofUnallocated_Minimum = 0
        
      
        $Script:SizeofImage = $Script:SizeofDisk
        if ($Script:SizeofImage /$DefaultDivisorFat32 -ge $Fat32DefaultMaximum){
            $Script:SizeofFAT32 = $Fat32DefaultMaximum
            $Script:SizeofFAT32_Pixels = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofFAT32)   
        }
        else{
            $Script:SizeofFAT32 = $Script:SizeofImage/$DefaultDivisorFat32
            $Script:SizeofFAT32_Pixels = [decimal]($Script:PartitionBarPixelperKB * $Script:SizeofFAT32)   
        }
    
        if ($Script:SizeofImage/$DefaultDivisorWorkbench -ge $Script:WorkbenchDefaultMaximum){
            $Script:SizeofPartition_System = $Script:WorkbenchDefaultMaximum 
            $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB) 
        }
        else{
            $Script:SizeofPartition_System = $Script:SizeofImage/$DefaultDivisorWorkbench
            $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB) 
        }
    
        $Script:SizeofPartition_Other = ($Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32)
        $Script:SizeofPartition_Other_Pixels = [decimal]($Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB)
    
        $Script:SizeofUnallocated = $Script:SizeofDisk-$Script:SizeofImage
        $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
    
        $Script:SizeofFreeSpace = $Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32-$Script:SizeofPartition_Other
        $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
        
        Set-PartitionMaximums
            
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
        
        if ($Script:SizeofPartition_Other -ge $Script:PFSLimit){
            $TotalNumberWorkPartitions = [math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)
            $WPF_UI_WorkSizeNote_Label.Text='*'
            $WPF_UI_WorkSizeNoteFooter_Label.Text=('Due to PFS limitations, Work will be split into '+$TotalNumberWorkPartitions+' partitions of equal size')
        }
        else{
            $WPF_UI_WorkSizeNote_Label.Text=''
            $WPF_UI_WorkSizeNoteFooter_Label.Text='' 
        }

        Set-GUIPartitionValues

               
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Script:SizeofUnallocated -Scale 'GiB'
        
        if ($WPF_UI_Unallocated_Value.Text -eq 0){
            $Script:UI_Unallocated_Value = 0
        }
        else{
            $Script:UI_Unallocated_Value = $WPF_UI_Unallocated_Value.Text      
        }        
        
        $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck  $Script:WorkingPath)/1Kb 

        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }

        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
        
        $null = Confirm-UIFields
    }
})

$WPF_UI_Fat32Size_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'FAT32'   
    if ($Script:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value -ge $Script:SizeofFat32_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFat32_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value -le $Script:SizeofFat32_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFat32_Pixels_Minimum
        }

        if ([math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }      

        if ([math]::round($Script:PartitionBarWidth- $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4) -le 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = 0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = [math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4)
        }
        
        if ([math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -le 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width =0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }

        Set-GUISizeofPartitions
        
        Set-GUIPartitionValues
                
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
   
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }
        
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
        
        $null = Confirm-UIFields
      
    }
})   

$WPF_UI_WorkbenchSize_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Workbench'
    if ($Script:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value -ge $Script:SizeofPartition_System_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value -le $Script:SizeofPartition_System_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels_Minimum
        }

        if ([math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }      

        if ([math]::round($Script:PartitionBarWidth- $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4) -le 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = 0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = [math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4)
        }
        
        if ([math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -le 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width =0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }
        
        Set-GUISizeofPartitions

        Set-GUIPartitionValues       
        
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }
      
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
       
        $null = Confirm-UIFields
    }   
})

$WPF_UI_WorkSize_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Work'
    if ($Script:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value -ge $Script:SizeofPartition_Other_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value -le $Script:SizeofPartition_Other_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels_Minimum
        }

        if ([math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }      

        if ([math]::round($Script:PartitionBarWidth- $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4) -le 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = 0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = [math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4)
        }
        
        if ([math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -le 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width =0
        }
        else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }

    Set-GUISizeofPartitions                                                                                                
  
    Set-GUIPartitionValues
   
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }
       
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
        
        $null = Confirm-UIFields
    }   
})

$WPF_UI_FreeSpace_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Free'
    if ($Script:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value -ge $Script:SizeofFreeSpace_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value -le $Script:SizeofFreeSpace_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels_Minimum
        }
        
        if ([math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value-$WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }     
        
        Set-GUISizeofPartitions 
        
        Set-GUIPartitionValues       

        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }
      
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)
        
        $null = Confirm-UIFields    

    }    
})

$WPF_UI_Unallocated_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Unallocated'
    if ($Script:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value -ge $Script:SizeofUnallocated_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value -le $Script:SizeofUnallocated_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels_Minimum
        }

        
    Set-GUISizeofPartitions               

    Set-GUIPartitionValues     
        
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
  
        if ($Script:SizeofPartition_Other){
            $Script:Space_FilestoTransfer = ($Script:SizeofPartition_Other/([math]::ceiling($Script:SizeofPartition_Other/$Script:PFSLimit)))  - $Script:WorkOverhead
        }
        else{
            $Script:Space_FilestoTransfer = 0
        }
  
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer          
        $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)

        $null = Confirm-UIFields
    
    }
})

$WPF_UI_LoadSettings_Button.Add_Click({
    $Script:SettingsFile = Get-SettingsLoadPath
    if ($Script:SettingsFile){  
        Read-SettingsFile -SettingsFile $Script:SettingsFile
        if ($Script:DiskFriendlyName -ne ''){
            $WPF_UI_MediaSelect_DropDown.SelectedItem = $Script:DiskFriendlyName

        }
        $WPF_UI_KickstartVersion_DropDown.SelectedItem = ($Script:KickstartVersiontoUseFriendlyName).tostring()
        $WPF_UI_ScreenMode_Dropdown.SelectedItem = $Script:ScreenModetoUseFriendlyName
        if ($Script:DeleteAllWorkingPathFiles -eq 'TRUE'){
            $WPF_UI_DeleteFiles_CheckBox.IsChecked = 'TRUE'
        }        
        if ($Script:SetDiskupOnly -eq 'TRUE'){
            $WPF_UI_SetUpDiskOnly_CheckBox.IsChecked = 'TRUE'
        }
        if ($Script:ImageOnly -eq 'TRUE'){
            $WPF_UI_ImageOnly_CheckBox.IsChecked = 'TRUE'
        }
        if ($Script:WriteMethod -eq 'SkipEmptySpace'){
            $WPF_UI_SkipEmptySpace_CheckBox.IsChecked = 'TRUE'
        }
        $WPF_UI_SSID_Textbox.Text=$Script:SSID
        $WPF_UI_Password_Textbox.Text=$Script:WifiPassword        
       
        Confirm-UIFields
    }
})


$WPF_UI_SaveSettings_Button.Add_Click({
    $Script:SettingsFile = Get-SettingsSavePath
    if ($Script:SettingsFile){
        if (-not (Test-path (split-path $Script:SettingsFile -Parent))){
            $null = New-Item (split-path $Script:SettingsFile -Parent) -ItemType Directory
        }
        Write-SettingsFile -SettingsFile $Script:SettingsFile
    }
})

$WPF_UI_MediaSelect_Refresh.Add_Click({
    $Script:HSTDiskName = $null
    $Script:DiskFriendlyName = $null
    $Script:HSTDiskNumber = $null
    $Script:HSTDiskDeviceID = $null
    $Script:SizeofDisk = $null
    $Script:SizeofImage = $null
    $Script:SizeofFat32_Pixels_Minimum = $null
    $Script:SizeofPartition_System_Pixels_Minimum = $null
    $Script:SizeofPartition_Other_Pixels_Minimum = $null
    $Script:SizeofFreeSpace_Pixels_Minimum = $null
    $Script:SizeofFreeSpace_Minimum = $null
    $Script:SizeofUnallocated_Pixels_Minimum = $null
    $Script:SizeofUnallocated_Minimum = $null
    $Script:SizeofFAT32 = $null
    $Script:SizeofFAT32_Pixels = $null
    $Script:SizeofPartition_System = $null
    $Script:SizeofPartition_System_Pixels = $null
    $Script:SizeofPartition_Other = $null
    $Script:SizeofPartition_Other_Pixels = $null
    $Script:SizeofUnallocated = $null
    $Script:SizeofUnallocated_Pixels = $null
    $Script:SizeofFreeSpace = $null
    $Script:SizeofFreeSpace_Pixels = $null
    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = '*'
    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = '*'
    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = '*'
    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = '*'
    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = '*'
    $Script:RequiredSpace_WorkingFolderDisk = 0 #In Kilobytes
    $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck  $Script:WorkingPath)/1Kb 
    $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
    $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk
    $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk 
    $WPF_UI_WorkSizeNote_Label.Text=''
    $WPF_UI_WorkSizeNoteFooter_Label.Text='' 
    $WPF_UI_WorkbenchSize_Value.Text = ''
    $WPF_UI_WorkbenchSize_Value.Background = 'White'
    $WPF_UI_WorkSize_Value.Text = ''
    $WPF_UI_WorkSize_Value.Background = 'White'
    $WPF_UI_ImageSize_Value.Text = ''
    $WPF_UI_ImageSize_Value.Background = 'White'
    $WPF_UI_FAT32Size_Value.Text = ''
    $WPF_UI_Fat32Size_Value.Background = 'White'
    $WPF_UI_FreeSpace_Value.Text = ''
    $WPF_UI_FreeSpace_Value.Background = 'White'
    $WPF_UI_Unallocated_Value.Text = ''
    $Script:RemovableMedia = Get-RemovableMedia    
    $WPF_UI_FAT32_Splitter.IsEnabled = ""
    $WPF_UI_Workbench_Splitter.IsEnabled = ""
    $WPF_UI_Work_Splitter.IsEnabled = ""
    $WPF_UI_Image_Splitter.IsEnabled = ""
    $WPF_UI_WorkbenchSize_Value.IsEnabled = ""
    $WPF_UI_WorkSize_Value.IsEnabled = ""
    $WPF_UI_ImageSize_Value.IsEnabled = ""
    $WPF_UI_FAT32Size_Value.IsEnabled = ""
    $WPF_UI_MediaSelect_Dropdown.Items.Clear()
    foreach ($Disk in $Script:RemovableMedia){
        $WPF_UI_MediaSelect_Dropdown.AddChild($Disk.FriendlyName)
    }
})

$WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Add_TextChanged({
    $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer
})


$WPF_UI_Password_Textbox.add_LostFocus({
    if ($WPF_UI_Password_Textbox.Text){
        $Script:WifiPassword = $WPF_UI_Password_Textbox.Text
    }
})

$WPF_UI_SSID_Textbox.add_LostFocus({
    if ($WPF_UI_SSID_Textbox.Text){
        $Script:SSID = $WPF_UI_SSID_Textbox.Text    
    }    
})


$WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Add_TextChanged({
    $null = Confirm-UIFields    
    
})


$WPF_UI_AvailableSpaceValue_TextBox.Add_TextChanged({
    $null = Confirm-UIFields
    
})

$WPF_UI_FAT32Size_Value.add_LostFocus({
    if (GuiValueIsNumber -ValuetoCheck $WPF_UI_FAT32Size_Value){
        if (-not(GuiValueIsSame -ValuetoCheck  $WPF_UI_FAT32Size_Value -ValuetoCheckAgainst $Script:UI_FAT32Size_Value)){
            $ValueinKB = (([Double]$WPF_UI_FAT32Size_Value.Text)*1024*1024)
            if (($ValueinKB -le $Script:FAT32Maximum) -and ($ValueinKB -ge $Script:FAT32Minimum)){
                $ValueDifference = $ValueinKB-$Script:SizeofFAT32
#                Write-host ('Value difference is '+$ValueDifference) 
                $FreeSpaceDifference = $Script:SizeofFreeSpace-$ValueDifference
#                Write-host ('Free Space difference is '+$FreeSpaceDifference) 
                $UnallocatedDifference = $Script:SizeofUnallocated-$ValueDifference
#                Write-host ('Unallocated difference is '+$UnallocatedDifference)
                $CombinedDifference = ($Script:SizeofUnallocated+$Script:SizeofFreeSpace)-$ValueDifference
#                Write-host ('Combined difference is '+$CombinedDifference)
                if ($FreeSpaceDifference -ge 0){
                    $Script:SizeofFreeSpace -= $ValueDifference 
                    $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                    $Script:SizeofFAT32 = $ValueinKB
                    $Script:SizeofFAT32_Pixels = [decimal]($Script:SizeofFAT32 * $Script:PartitionBarPixelperKB)
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels 
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
                    $WPF_UI_FAT32Size_Value.Background = 'White'
                    $Script:UI_FAT32Size_Value=$WPF_UI_FAT32Size_Value.Text                
                }
                elseif ($CombinedDifference -ge 0){
                    $Script:SizeofFreeSpace = 0
                    $Script:SizeofFreeSpace_Pixels = 0
                    $Script:SizeofUnallocated -= ($FreeSpaceDifference+$UnallocatedDifference)
                    $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
                    $Script:SizeofFAT32 = $ValueinKB
                    $Script:SizeofFAT32_Pixels = [decimal]($Script:SizeofFAT32 * $Script:PartitionBarPixelperKB)
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
                    $WPF_UI_FAT32Size_Value.Background = 'White'
                    $Script:UI_FAT32Size_Value=$WPF_UI_FAT32Size_Value.Text       
                }
                else{
                    $WPF_UI_FAT32Size_Value.Background = 'Red'
                }
            }
        }        
    }
})

$WPF_UI_WorkbenchSize_Value.add_LostFocus({
    if (GuiValueIsNumber -ValuetoCheck $WPF_UI_WorkbenchSize_Value){
        if (-not(GuiValueIsSame -ValuetoCheck  $WPF_UI_WorkbenchSize_Value -ValuetoCheckAgainst $Script:UI_WorkbenchSize_Value)){
            $ValueinKB = (([Double]$WPF_UI_WorkbenchSize_Value.Text)*1024*1024)
            if (($ValueinKB -le $Script:WorkbenchMaximum) -and ($ValueinKB -ge $Script:WorkbenchMinimum)){
                $ValueDifference = $ValueinKB-$Script:SizeofPartition_System
#                Write-host ('Value difference is '+$ValueDifference) 
                $FreeSpaceDifference = $Script:SizeofFreeSpace-$ValueDifference
#                Write-host ('Free Space difference is '+$FreeSpaceDifference) 
                $UnallocatedDifference = $Script:SizeofUnallocated-$ValueDifference
#                Write-host ('Unallocated difference is '+$UnallocatedDifference)
                $CombinedDifference = ($Script:SizeofUnallocated+$Script:SizeofFreeSpace)-$ValueDifference
#                Write-host ('Combined difference is '+$CombinedDifference)
                if ($FreeSpaceDifference -ge 0){
                    $Script:SizeofFreeSpace -= $ValueDifference 
                    $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                    $Script:SizeofPartition_System = $ValueinKB
                    $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB)
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels 
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
                    $WPF_UI_WorkbenchSize_Value.Background = 'White'
                    $Script:UI_WorkbenchSize_Value=$WPF_UI_WorkbenchSize_Value.Text                
                }
                elseif ($CombinedDifference -ge 0){
                    $Script:SizeofFreeSpace = 0
                    $Script:SizeofFreeSpace_Pixels = 0
                    $Script:SizeofUnallocated -= ($FreeSpaceDifference+$UnallocatedDifference)
                    $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
                    $Script:SizeofPartition_System = $ValueinKB
                    $Script:SizeofPartition_System_Pixels = [decimal]($Script:SizeofPartition_System * $Script:PartitionBarPixelperKB)
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
                    $WPF_UI_WorkbenchSize_Value.Background = 'White'
                    $Script:UI_WorkbenchSize_Value=$WPF_UI_WorkbenchSize_Value.Text       
                }
                else{
                    $WPF_UI_WorkbenchSize_Value.Background = 'Red'
                }
            }
        }        
    }
})

$WPF_UI_WorkSize_Value.add_LostFocus({
    if (GuiValueIsNumber -ValuetoCheck $WPF_UI_WorkSize_Value){
        if (-not(GuiValueIsSame -ValuetoCheck  $WPF_UI_WorkSize_Value -ValuetoCheckAgainst $Script:UI_WorkSize_Value)){
            $ValueinKB = (([Double]$WPF_UI_WorkSize_Value.Text)*1024*1024)
            if ($ValueinKB -ge $Script:WorkMinimum){
                $ValueDifference = $ValueinKB-$Script:SizeofPartition_Other
#                Write-host ('Value difference is '+$ValueDifference) 
                $FreeSpaceDifference = $Script:SizeofFreeSpace-$ValueDifference
#                Write-host ('Free Space difference is '+$FreeSpaceDifference) 
                $UnallocatedDifference = $Script:SizeofUnallocated-$ValueDifference
#                Write-host ('Unallocated difference is '+$UnallocatedDifference)
                $CombinedDifference = ($Script:SizeofUnallocated+$Script:SizeofFreeSpace)-$ValueDifference
#                Write-host ('Combined difference is '+$CombinedDifference)
                if ($FreeSpaceDifference -ge 0){
                    $Script:SizeofFreeSpace -= $ValueDifference 
                    $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                    $Script:SizeofPartition_Other = $ValueinKB
                    $Script:SizeofPartition_Other_Pixels = [decimal]($Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB)
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels 
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
                    $WPF_UI_WorkSize_Value.Background = 'White'
                    $Script:UI_WorkSize_Value=$WPF_UI_WorkSize_Value.Text                
                }
                elseif ($CombinedDifference -ge 0){
                    $Script:SizeofFreeSpace = 0
                    $Script:SizeofFreeSpace_Pixels = 0
                    $Script:SizeofUnallocated -= ($FreeSpaceDifference+$UnallocatedDifference)
                    $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
                    $Script:SizeofPartition_Other = $ValueinKB
                    $Script:SizeofPartition_Other_Pixels = [decimal]($Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB)
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
                    $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
                    $WPF_UI_WorkSize_Value.Background = 'White'
                    $Script:UI_WorkSize_Value=$WPF_UI_WorkSize_Value.Text       
                }
                else{
                    $WPF_UI_WorkSize_Value.Background = 'Red'
                }
            }
        }        
    }
})

$WPF_UI_FreeSpace_Value.add_LostFocus({
    if (GuiValueIsNumber -ValuetoCheck $WPF_UI_FreeSpace_Value){
        if (-not(GuiValueIsSame -ValuetoCheck  $WPF_UI_FreeSpace_Value -ValuetoCheckAgainst $Script:UI_FreeSpace_Value)){
            $ValueinKB = (([Double]$WPF_UI_FreeSpace_Value.Text)*1024*1024)
            $ValueDifference = $ValueinKB-$Script:SizeofFreeSpace
            # Write-Host "Difference in value for FreeSpace is: $ValueDifference"
            if ($ValueDifference -lt 0){
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
                $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels  
                $Script:UI_FreeSpace_Value= $WPF_UI_FreeSpace_Value.Text
            }
            elseif ($ValueDifference -eq 0){

            }
            elseif($ValueDifference -gt 0 -and ($Script:SizeofUnallocated - $ValueDifference) -gt 0){
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
                $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels  
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels  
                $Script:UI_FreeSpace_Value= $WPF_UI_FreeSpace_Value.Text
            }
            else{
                # Write-Host $WPF_UI_FreeSpace_Value.Text 
                # Write-Host $UI_FreeSpace_Value
                # Write-host 'Not enough free space for change!'
                # write-host $ValueDifference
                $WPF_UI_FreeSpace_Value.Background = 'Red'                
            }
        }
    }
})

$WPF_UI_ImageSize_Value.add_LostFocus({
    if (GuiValueIsNumber -ValuetoCheck $WPF_UI_ImageSize_Value){
        if (-not(GuiValueIsSame -ValuetoCheck  $WPF_UI_ImageSize_Value -ValuetoCheckAgainst $Script:UI_ImageSize_Value)){
            $ValueinKB = (([Double]$WPF_UI_ImageSize_Value.Text)*1024*1024)
            $ValueDifference = ($ValueinKB-$Script:SizeofImage)
            if ($ValueDifference -eq 0){

            }
            elseif (($ValueDifference -lt 0) -and ($ValueDifference+$Script:SizeofFreeSpace -gt 0)) {  # We are reducing image and need free space
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels  
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels  
                $UI_ImageSize_Value = $WPF_UI_ImageSize_Value.Text       
            }
            elseif (($ValueDifference -gt 0) -and ($Script:SizeofUnallocated -$ValueDifference -gt 0)) {  # We are reducing image and need free space    
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofUnallocated_Pixels = [decimal]($Script:SizeofUnallocated * $Script:PartitionBarPixelperKB)
                $Script:SizeofFreeSpace_Pixels = [decimal]($Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB)
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels  
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
                $UI_ImageSize_Value = $WPF_UI_ImageSize_Value.Text         
            }
            else {
                 $WPF_UI_ImageSize_Value.Background = 'Red'
            }
        }
    }
})

$WPF_UI_Workingpath_Button.Add_Click({
     $WorkingPathtoPopulate = Get-WorkingPath -CheckforEmptyFolder 'TRUE'
     if ($WorkingPathtoPopulate){
         $Script:WorkingPath = $WorkingPathtoPopulate
         $Script:WorkingPathDefault = $false
         $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Script:WorkingPath)/1kb
         if ($Script:SizeofImage){
             $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage 
         }
         $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk
     }
     elseif ((-not $WorkingPathtoPopulate)  -and ($Script:WorkingPath -ne ($Script:Scriptpath+'Working Folder\'))){
        $Script:WorkingPath = ($Script:Scriptpath+'Working Folder\')
        $Script:WorkingPathDefault = $true        
        $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Script:WorkingPath)/1kb
        if ($Script:SizeofImage){
            $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage    
        }
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk   
     }
     $null = Confirm-UIFields
})

$WPF_UI_RomPath_Button.Add_Click({
    $PathtoPopulate = Get-FolderPath -Message 'Select path to Kickstart' -InitialDirectory $Script:ROMPath
    if ($PathtoPopulate){
        $CheckifLocalDrive = (Get-LocalvsNetwork -PathtoCheck $PathtoPopulate -PreventNetworkPath 'LocalandMappedDrivesOnly') 
        if (($CheckifLocalDrive -eq 'Local') -or ($CheckifLocalDrive -eq 'Network-MappedDrive')){
            if ($PathtoPopulate -ne $Script:ROMPath) {
                $Script:ROMPath = $PathtoPopulate.TrimEnd('\')+'\'
                $Script:FoundKickstarttoUse = $null    
            }
        }
        else{
            if ($Script:ROMPath -ne $Script:UserLocation_Kickstarts){
                $Script:ROMPath = $Script:UserLocation_Kickstarts
                $Script:FoundKickstarttoUse = $null                        
            }
        }
    }
    else{
        if ($Script:ROMPath -ne $Script:UserLocation_Kickstarts){
            $Script:ROMPath = $Script:UserLocation_Kickstarts
            $Script:FoundKickstarttoUse = $null                        
        }
    }                     
    $null = Confirm-UIFields
})

$WPF_UI_ROMpath_Button_Check.Add_Click({
    if ($Script:KickstartVersiontoUse){
        $Script:FoundKickstarttoUse = Compare-KickstartHashes -PathtoKickstartHashes ($InputFolder+'RomHashes.csv') -PathtoKickstartFiles $Script:ROMPath -KickstartVersion $Script:KickstartVersiontoUse
        if (-not ($Script:FoundKickstarttoUse)){
            Write-GUINoKickstart
        }
        else{
            $Title = 'Kickstarts to be used'
            $Text = 'The following Kickstart will be used:'
            $DatatoPopulate = $Script:FoundKickstarttoUse | Select-Object @{Name='Kickstart';Expression='FriendlyName'},@{Name='Path';Expression='KickstartPath'}
            
            Get-GUIADFKickstartReport -Title $Title -Text $Text -DatatoPopulate $DatatoPopulate -WindowWidth 700 -WindowHeight 300 -DataGridWidth 570 -DataGridHeight 80 -GridLinesVisibility 'None'    
        }
    }
    else{
        Write-GUINoOSChosen -Type 'Kickstarts'
    }
    $null = Confirm-UIFields
})


$WPF_UI_ADFPath_Button.Add_Click({
    $PathtoPopulate = Get-FolderPath -Message 'Select path to ADFs' -InitialDirectory $Script:ADFPath
    if ($PathtoPopulate){
        $CheckifLocalDrive = (Get-LocalvsNetwork -PathtoCheck $PathtoPopulate -PreventNetworkPath 'LocalandMappedDrivesOnly') 
        if (($CheckifLocalDrive -eq 'Local') -or ($CheckifLocalDrive -eq 'Network-MappedDrive')){
            if ($PathtoPopulate -ne $Script:ADFPath) {
                $Script:ADFPath = $PathtoPopulate.TrimEnd('\')+'\'
                $Script:AvailableADFs = $null    
            }
        }
        else{
            if ($Script:ADFPath -ne $Script:UserLocation_ADFs){
                $Script:ADFPath = $Script:UserLocation_ADFs   
                $Script:AvailableADFs = $null
            }
        }
    }
    else{
        if ($Script:ADFPath -ne $Script:UserLocation_ADFs){
            $Script:ADFPath = $Script:UserLocation_ADFs   
            $Script:AvailableADFs = $null
        }
    }
    $null = Confirm-UIFields
})

$WPF_UI_ADFpath_Button_Check.Add_Click({
    if ($Script:KickstartVersiontoUse){
        $Script:AvailableADFs = Compare-ADFHashes -PathtoADFFiles $Script:ADFPath -PathtoADFHashes ($InputFolder+'ADFHashes.csv') -KickstartVersion $Script:KickstartVersiontoUse -PathtoListofInstallFiles ($InputFolder+'ListofInstallFiles.csv')            
        
        Update-ListofInstallFiles

        if (($Script:AvailableADFs | Select-Object 'IsMatched' -unique).IsMatched -eq 'FALSE'){
            $Title = 'Missing ADFs'
            $Text = 'You have missing ADFs. You need to correct this before you can run the tool. List of ADFs located and missing is below'
        }
        else {                         
            $Title = 'ADFs to be used'
            $Text = 'The following ADFs will be used:'
        }
        
        $DatatoPopulate = $AvailableADFs  | Select-Object @{Name='Status';Expression='IsMatched'},@{Name='Source';Expression='Source'},@{Name='ADF Name';Expression='FriendlyName'},@{Name='Path';Expression='Path'},@{Name='MD5 Hash';Expression='Hash'} | Sort-Object -Property 'Status'

        $FieldsSorted = ('Status','Source','ADF Name','Path','MD5 Hash')

        foreach ($ADF in $DatatoPopulate ){
            if ($ADF.Status -eq 'TRUE'){
                $ADF.Status = 'Located'
            }
            else{
                $ADF.Status = 'Missing!'
            }
        }

        Get-GUIADFKickstartReport -Title $Title -Text $Text -DatatoPopulate $DatatoPopulate -WindowWidth 800 -WindowHeight 350 -DataGridWidth 670 -DataGridHeight 200 -GridLinesVisibility 'None' -FieldsSorted $FieldsSorted                    
    }
    
    else {
        Write-GUINoOSChosen -Type 'ADFs'
    }
    $null = Confirm-UIFields 
})

$WPF_UI_MigratedFiles_Button.Add_Click({
    if ($Script:TransferLocation){
        $Script:TransferLocation =$null
        $Script:SizeofFilestoTransfer = 0
    }
    else{
        $PathtoPopulate = Get-FolderPath -Message 'Select Transfer folder' -RootFolder 'MyComputer'
        if ($PathtoPopulate){
            Write-host $PathtoPopulate
            $CheckifLocalDrive = (Get-LocalvsNetwork -PathtoCheck $PathtoPopulate -PreventNetworkPath 'LocalandMappedDrivesOnly') 
            if (($CheckifLocalDrive -eq 'Local') -or ($CheckifLocalDrive -eq 'Network-MappedDrive')){
                $PathtoPopulate = $PathtoPopulate.TrimEnd('\')+'\'
                $Msg = @'
Calculating space requirements. This may take some time if you have selected a large folder for transfer!
'@                  
                $null = [System.Windows.MessageBox]::Show($Msg, 'Calculating Space',0,0)
                $Script:TransferLocation = $PathtoPopulate            
                $Script:SizeofFilestoTransfer = Get-TransferredFilesSpaceRequired -FoldertoCheck $Script:TransferLocation
                $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer
                $Script:SpaceThreshold_FilestoTransfer = ($Script:Space_FilestoTransfer*0.2)      
            }
            else{
                $Script:TransferLocation =$null
                $Script:SizeofFilestoTransfer = 0                
            }       
        }
        else{
            $Script:TransferLocation =$null
            $Script:SizeofFilestoTransfer = 0            
        }
    }     
    $null = Confirm-UIFields
})

$AvailableKickstarts =  Get-ListofInstallFiles -ListofInstallFilesCSV ($Script:InputFolder+'ListofInstallFiles.csv') | Where-Object 'Kickstart_VersionFriendlyName' -ne "" | Select-Object 'Kickstart_Version','Kickstart_VersionFriendlyName' -unique 

foreach ($Kickstart in $AvailableKickstarts) {
    $WPF_UI_KickstartVersion_Dropdown.AddChild(($Kickstart.Kickstart_VersionFriendlyName).tostring())
}

$WPF_UI_KickstartVersion_Dropdown.Add_SelectionChanged({    
    foreach ($Kickstart in $AvailableKickstarts) {
        if ($Kickstart.Kickstart_VersionFriendlyName -eq $WPF_UI_KickstartVersion_Dropdown.SelectedItem){
            if ($Kickstart.Kickstart_Version -ne $Script:KickstartVersiontoUse){
                $Script:KickstartVersiontoUse  = $Kickstart.Kickstart_Version 
                $Script:KickstartVersiontoUseFriendlyName = $WPF_UI_KickstartVersion_Dropdown.SelectedItem
                $Script:AvailableADFs = $null
                $Script:FoundKickstarttoUse = $null
            } 
        }
   }

   $null = Confirm-UIFields
   
})

$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.csv') -delimiter ';' | Where-Object 'Include' -eq 'TRUE'

foreach ($ScreenMode in $AvailableScreenModes) {
    $WPF_UI_ScreenMode_Dropdown.AddChild($ScreenMode.FriendlyName)
}

$Script:ScreenModetoUseFriendlyName = 'Automatic'
$WPF_UI_ScreenMode_Dropdown.SelectedItem = $Script:ScreenModetoUseFriendlyName 
$Script:ScreenModetoUse = 'Auto'

$WPF_UI_ScreenMode_Dropdown.Add_SelectionChanged({
    foreach ($ScreenMode in $AvailableScreenModes) {
        if ($ScreenMode.FriendlyName -eq $WPF_UI_ScreenMode_Dropdown.SelectedItem){
            $Script:ScreenModetoUse = $ScreenMode.Name
            $Script:ScreenModetoUseFriendlyName = $WPF_UI_ScreenMode_Dropdown.SelectedItem           
        }
    }

    $null = Confirm-UIFields
    
})

$WPF_UI_DeleteFiles_CheckBox.Add_Checked({
    $Script:DeleteAllWorkingPathFiles = 'TRUE'
    $null = Confirm-UIFields
})

$WPF_UI_DeleteFiles_CheckBox.Add_UnChecked({
    $Script:DeleteAllWorkingPathFiles = 'FALSE'
    $null = Confirm-UIFields
})

$WPF_UI_ImageOnly_CheckBox.Add_Checked({
    if ($Script:ImageOnly -ne 'TRUE'){
        $Script:ImageOnly ='TRUE'
        $Script:SetDiskupOnly = 'FALSE'  
        $null = Confirm-UIFields
    }
})

$WPF_UI_ImageOnly_CheckBox.Add_UnChecked({
    if ($Script:ImageOnly -eq 'TRUE'){
        $Script:ImageOnly ='FALSE'
        $null = Confirm-UIFields
    }
})

$WPF_UI_SkipEmptySpace_CheckBox.Add_Checked({
    if ($Script:WriteMethod -ne 'SkipEmptySpace'){
        $Script:WriteMethod = 'SkipEmptySpace'
        $null = Confirm-UIFields
    }
})

$WPF_UI_SkipEmptySpace_CheckBox.Add_UnChecked({
    $Script:WriteMethod = 'Normal'
    $null = Confirm-UIFields
})

$WPF_UI_SetUpDiskOnly_CheckBox.Add_Checked({
    if ($Script:SetDiskupOnly -ne 'TRUE'){
        $Script:SetDiskupOnly = 'TRUE'
        $Script:ImageOnly ='FALSE'
        $Script:TransferLocation = $null
        $Script:AvailableADFs = $null
        $Script:ADFPath = $Script:UserLocation_ADFs
        If ($Script:HSTDiskName){
            $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
            $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk    
        } 
        $null = Confirm-UIFields    
    } 
})

$WPF_UI_SetUpDiskOnly_CheckBox.Add_UnChecked({
    if ($Script:SetDiskupOnly -eq 'TRUE'){
        $Script:SetDiskupOnly = 'FALSE'   
        If ($Script:HSTDiskName){
            $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
            $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
        } 
        $null = Confirm-UIFields   
    } 

})

$WPF_UI_Documentation_Button.Add_Click({
    Start-Process $Script:Documentation_URL
})


$WPF_UI_Start_Button.Add_Click({
    $ErrorCount = 0
    if ((Get-TransferFileCheck -TransferLocationtocheck $Script:TransferLocation -TransferSpaceThreshold $Script:SpaceThreshold_FilestoTransfer -TransferAvailableSpace $Script:AvailableSpaceFilestoTransfer) -eq $false) {
        $ErrorCount += 1
    }
    else{
        $ErrorCount = $ErrorCount
    }
    $ErrorCheck = Confirm-UIFields
    if ($ErrorCheck){
        $null = [System.Windows.MessageBox]::Show($ErrorCheck, 'Error! Go back and correct')
        $ErrorCount += 1  
    } 
    if ($ErrorCount -eq 0){
        if (Get-ImageSizevsDiskSize -UnallocatedSpace $Script:SizeofUnallocated -ThresholdtocheckMiB 10 -DiskSizetocheck $Script:SizeofDisk -ImageSizetocheck $Script:SizeofImage){
            $ErrorCount = $ErrorCount
        }
        else{
            $ErrorCount += 1  
        }   
    }
    if ($ErrorCount -eq 0){
        if ($Script:AvailableSpace_WorkingFolderDisk -le -$Script:SpaceThreshold_WorkingFolderDisk){
            if ((Get-SpaceCheck -AvailableSpace $Script:AvailableSpace_WorkingFolderDisk -SpaceThreshold $Script:SpaceThreshold_WorkingFolderDisk) -eq $true){
                $ErrorCount = $ErrorCount
    
            }
            else{
                $ErrorCount += 1  
                $Script:ExitType = 2
                if ($Script:ExitType -eq 2){
                    Write-ErrorMessage -Message 'Exiting - User has insufficient space' -NoLog
                    $Form_UserInterface.Close() | out-null
                    exit
                }
            }
        }
        $Script:KickstartPath = $Script:FoundKickstarttoUse.KickstartPath
        $Script:KickstartNameFAT32=$Script:FoundKickstarttoUse.Fat32Name
        $Script:SizeofImage_HST = (($Script:SizeofImage-($Script:SizeofFAT32)).ToString()+'kb')
        $Script:SizeofImage_Powershell=($Script:SizeofImage-$Script:SizeofFAT32)
        $Script:SizeofFAT32_hdf2emu68 = $Script:SizeofFAT32/1024
        $Script:LocationofImage = $Script:WorkingPath+'OutputImage\'

        if (-not $Script:ListofInstallFiles){
            Update-ListofInstallFiles 
        }

        If ($Script:WorkingPath -ne ($Script:Scriptpath+'Working Folder\')){
            $NewFolders = ('Temp\'),('HDFImage\'),('OutputImage\'),('AmigaImageFiles\'),('FAT32Partition\')
            foreach ($NewFolder in $NewFolders) {
                if (Test-Path ($Script:WorkingPath+$NewFolder)){
                    $null = Remove-Item ( $Script:WorkingPath+$NewFolder) -Recurse
                }
            }
        }
        $WPF_UI_Main_Grid.Visibility="Hidden"
        Write-GUIReporttoUseronOptions
        $WPF_UI_Reporting_Grid.Visibility="Visible"        
    }  
})

$WPF_UI_GoBack_Button.add_Click({
        $null = Confirm-UIFields
        $WPF_UI_Reporting_Grid.Visibility="Hidden"
        $WPF_UI_Main_Grid.Visibility="Visible"
})

$WPF_UI_Process_Button.add_Click({
        Write-SettingsFile -SettingsFile ($Script:SettingsFolder+$Script:LogDateTime+'_AutomatedSettingsSave.e68')
        $Form_UserInterface.Close() | out-null
        $Script:ExitType = 1
})

####################################################################### End GUI XML for Main Environment ##################################################################################################

####################################################################### GUI XML for Test Administrator ##################################################################################################
$InputXML_AdministratorWindow = @"

<Window x:Name="NoAdministratorMode" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp14"
        mc:Ignorable="d"
        Title="Not Run as Administrator" Height="200" Width="910" HorizontalAlignment="Center" HorizontalContentAlignment="Center" UseLayoutRounding="True" ScrollViewer.VerticalScrollBarVisibility="Disabled" ResizeMode="NoResize">
    <Grid Background="#FFAAAAAA">
        <Button x:Name="Button_Acknowledge" HorizontalContentAlignment="Center" Content="Acknowledge" HorizontalAlignment="Center" Margin="0,100,0,0" VerticalAlignment="Top" Height="40" Width="320" BorderBrush="Black" UseLayoutRounding="False" Background="#FF6688BB"/>
        <TextBox x:Name="TextBox_Message" HorizontalContentAlignment="Center" HorizontalAlignment="center" Margin="0,60,0,0" Background="Transparent" TextWrapping="Wrap" Text="You must run the tool in Administrator Mode!" VerticalAlignment="Top" Width="600" IsReadOnly="True"  FontSize="24" FontWeight="Bold" Foreground="Red" BorderThickness="0,0,0,0" SelectionOpacity="0"/>        
    </Grid>
</Window>
"@

$XAML_AdministratorWindow = Format-XMLtoXAML -inputXML $InputXML_AdministratorWindow
$Form_Administrator = Read-XAML -xaml $XAML_AdministratorWindow

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================

Remove-Variable -Name WPF_Admin_*

$XAML_AdministratorWindow.SelectNodes("//*[@Name]") | ForEach-Object{
    #    "Trying item $($_.Name)";
    try {
        Set-Variable -Name "WPF_Admin_$($_.Name)" -Value $Form_Administrator.FindName($_.Name) -ErrorAction Stop
    }
    catch{
        throw
    }
}

# Get-FormVariables - If we need variables

$WPF_Admin_Button_Acknowledge.Add_Click({
    $Form_Administrator.Close() | out-null
})

####################################################################### End GUI XML for Test Administrator ##################################################################################################


####################################################################### GUI XML for Disclaimer ##################################################################################################

$InputXML_DisclaimerWindow = @"
<Window x:Name="Disclaimer" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp14"
        mc:Ignorable="d"
        Title="Disclaimer and Acknowledgements" Height="400" Width="1054" HorizontalAlignment="Center" HorizontalContentAlignment="Center" ScrollViewer.VerticalScrollBarVisibility="Disabled" ResizeMode="NoResize" WindowStyle="ToolWindow">
    <Grid Background="#FFAAAAAA" >
        <Button x:Name="Button_Acknowledge" Content="Acknowledge and Continue" HorizontalAlignment="Center" Height="40" VerticalAlignment="Bottom" Width="320" BorderBrush="Black" UseLayoutRounding="False" Background="#FF6688BB" Margin="0,0,0,15"/>
        <TextBox x:Name="TextBox_Message" HorizontalAlignment="Center" Margin="0,50,0,0" TextWrapping="Wrap" Background="Transparent" BorderBrush="Transparent"
                 Text="This software is used at your own risk! While efforts have been made to test the software, it should be used with caution.  Data will be written to physical media attached to your computer and all data on that media will be erased. If the incorrect media is chosen, data on that media will also be erased!&#xA;&#xA;If you do not accept this risk, then do not use this software! No one likes reading manuals! However, you are strongly encouraged to read at least the Quick Start section of the documentation! This can be accessed through the link below along links to the other section. &#xA;&#xA;A link to the documentation is also available in the tool should you wish to access from there." 
                 VerticalAlignment="Top" Width="874" IsReadOnly="True" Height="160" VerticalScrollBarVisibility="Disabled" FontSize="14" BorderThickness="0,0,0,0" SelectionOpacity="0"
                 />
        <TextBox x:Name="TextBox_Header" HorizontalAlignment="Center" Margin="0,20,0,0" TextWrapping="Wrap" Background="Transparent" BorderBrush="Transparent"
            Text="Emu68 Imager v$Script:Version" FontSize="14" BorderThickness="0,0,0,0" SelectionOpacity="0"
            VerticalAlignment="Top" Width="772" IsReadOnly="True" Height="20" VerticalScrollBarVisibility="Disabled" HorizontalContentAlignment="Center" FontWeight="Bold"
                 />
        <Button x:Name="LinktoQuickstart_Button" Content="Link to Quick Start Guide" HorizontalAlignment="Center" Margin="0,210,0,0" VerticalAlignment="Top" Height="80" Width="400"/>
    </Grid>
</Window>
"@

$XAML_DisclaimerWindow = Format-XMLtoXAML -inputXML $InputXML_DisclaimerWindow
$Form_Disclaimer = Read-XAML -xaml $XAML_DisclaimerWindow

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================

Remove-Variable -Name WPF_Disclaimer_*

$XAML_DisclaimerWindow.SelectNodes("//*[@Name]") | ForEach-Object{
    #    "Trying item $($_.Name)";
    try {
        Set-Variable -Name "WPF_Disclaimer_$($_.Name)" -Value $Form_Disclaimer.FindName($_.Name) -ErrorAction Stop
    }
    catch{
        throw
    }
}

# Get-FormVariables - If we need variables

$WPF_Disclaimer_Button_Acknowledge.Add_Click({
    $Form_Disclaimer.Close() | out-null
    $Script:IsDisclaimerAccepted = $True
})

$WPF_Disclaimer_LinktoQuickstart_Button.Add_Click({
    Start-Process $Script:QuickStart_URL
})

####################################################################### End GUI XML for Disclaimer ##################################################################################################

####################################################################### Test for Administrator ############################################################################################################

if (-not (Test-Administrator)){
    $Form_Administrator.ShowDialog() | out-null
}
else {
    $IsAdministrator = $true 
}

if (-not ($IsAdministrator)){
    exit

}
####################################################################### End Test for Administrator ############################################################################################################


################################# Set Working Folder Default #########################################################################################

$Script:WorkingPath = ($Script:Scriptpath+'Working Folder\')
if (-not (Test-Path $Script:WorkingPath)){
    $null = New-Item $Script:WorkingPath -ItemType Directory
}
$Script:WorkingPathDefault = $true    
$Script:WriteMethod = 'SkipEmptySpace'
$Script:SetDiskupOnly = 'FALSE'
$Script:DeleteAllWorkingPathFiles = 'FALSE'
$Script:ImageOnly = 'FALSE'

$Form_Disclaimer.ShowDialog() | out-null

if (-not ($Script:IsDisclaimerAccepted -eq $true)){
    Write-ErrorMessage 'Exiting - Disclaimer Not Accepted'
    exit    
}

################################ End Set Working Folder Default #########################################################################################

##################################################################### Peform Pre-GUI Checks ##############################################################################################################

$ErrorMessage = $null
$ErrorMessage += Test-ExistenceofFiles -PathtoTest $SourceProgramPath -PathType 'Folder'
$ErrorMessage += Test-ExistenceofFiles -PathtoTest $InputFolder -PathType 'Folder'
$ErrorMessage += Test-ExistenceofFiles -PathtoTest $LocationofAmigaFiles -PathType 'Folder'
$ErrorMessage += Test-ExistenceofFiles -PathtoTest ($SourceProgramPath+'hdf2emu68.exe') -PathType 'File'
$ErrorMessage += Test-ExistenceofFiles -PathtoTest ($SourceProgramPath+'7z.exe') -PathType 'File'
$ErrorMessage += Test-ExistenceofFiles -PathtoTest ($SourceProgramPath+'7z.dll') -PathType 'File'

if (-not (Test-ExistenceofFiles -PathtoTest $InputFolder -PathType 'Folder')){
    $ListofPackagestoInstall = Get-ListofPackagestoInstall -ListofPackagestoInstallCSV ($InputFolder+'ListofPackagestoInstall.csv') | Where-Object {$_.Source -eq 'Local'} | Where-Object {$_.InstallType -ne 'StartupSequenceOnly'} |Where-Object {$_.InstallFlag -eq 'TRUE'}
    $ListofPackagestoInstall |  Select-Object SourceLocation -Unique | Where-Object SourceLocation -NotMatch 'Onetime' | ForEach-Object {
        $ErrorMessage += Test-ExistenceofFiles -PathtoTest ($LocationofAmigaFiles+$_.SourceLocation) -PathType 'File'
    }
}

if ($ErrorMessage){
        $Msg_Header ='Missing Files'    
        $Msg_Body = @"  
One or more Programs and/or files is missing and/or has been altered! Cannot Continue! Re-download file and try again. Tool will now exit. 

The following files are affected:

$ErrorMessage
"@  
    $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,16) 
    exit
}

# Check Integrity of CSVs

$CSVHashestoCheck = Import-Csv -Path ($InputFolder+'CSVHASH') -Delimiter ';'

$CSVHashesFound = $null
$CSVHashesFound += Get-FileHash ($InputFolder+'*.CSV') -Algorithm MD5
$CSVHashesFound += Get-FileHash (Get-ChildItem -Path ($LocationofAmigaFiles) -Recurse | Where-Object { $_.PSIsContainer -eq $false }).FullName -Algorithm MD5
$CSVHashesFound += Get-FileHash (Get-ChildItem -Path ($SourceProgramPath) -Recurse | Where-Object { $_.PSIsContainer -eq $false }).FullName -Algorithm MD5
$CSVHashesFound += Get-FileHash (Get-ChildItem -Path ($ScriptPath+'Script\') -Recurse | Where-Object { $_.PSIsContainer -eq $false }).FullName -Algorithm MD5

# foreach ($CSVHashtoCheck in $CSVHashestoCheck){
#     $HashMatch = $false
#     foreach ($CSVHash in $CSVHashesFound){
#         $Length = ($CSVHash.Path).Length
#         $StartPoint = ($Script:Scriptpath).Length
#         $Path = ($CSVHash.Path).Substring($StartPoint,($Length-$StartPoint))    
#         if (($CSVHashtoCheck.Path+$CSVHashtoCheck.Hash) -eq ($Path+$CSVHash.Hash)){
#             $HashMatch = $true
#         }
#     }
#     if ($HashMatch -eq $false) {
#         $Msg_Header ='Integrity Issue with Files'    
#         $Msg_Body = @"  
# One or more files is missing and/or has been altered!' 
        
# Re-download Emu68 Imager and try again. Tool will now exit.
# "@     
#     $null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,16) 
#     exit
#     }
# }

### Clean up

Remove-WorkingFolderData -DefaultFolder 'TRUE'

### End Clean up

####################################################################### End Pre GUI Checks #################################################################################################################

####################################################################### Show Main Gui     ##################################################################################################################
$Form_UserInterface.ShowDialog() | out-null

######################################################################## Command line portion of Script ################################################################################################


if  ($RunMode -eq 1){
    get-process -id $Pid | set-windowstate -State SHOWDEFAULT
} 

if ($Script:ExitType -eq 2){
    Write-ErrorMessage -Message 'Exiting - User has insufficient space' -NoLog
    exit
}
elseif (-not ($Script:ExitType-eq 1)){
    Write-ErrorMessage -Message 'Exiting - UI Window was closed' -NoLog
    exit
}

#[System.Windows.Window].GetEvents() | select Name, *Method, EventHandlerType

#[System.Windows.Controls.GridSplitter].GetEvents() | Select-Object Name, *Method, EventHandlerType
#[System.Windows.Controls.CheckBox].GetEvents() | Select-Object Name, *Method, EventHandlerType

#Get-FormVariables

if (-not (Test-Path $Script:WorkingPath)){
    $null = New-Item -Path $Script:WorkingPath -Force -ItemType Directory
}

Set-Location  $Script:WorkingPath

if (((split-path  $Script:WorkingPath  -Parent)+'\') -eq $Script:Scriptpath) {
    if (-not (Test-Path ($Script:Scriptpath+'Working Folder\'))){
        $null = New-Item ($Script:Scriptpath+'Working Folder\') -ItemType Directory
    }
}

Remove-WorkingFolderData

$FAT32Partition = $Script:WorkingPath+'FAT32Partition\'

if (-not(Test-Path $FAT32Partition)){
    $null = New-Item $FAT32Partition -ItemType Directory    
}

$AmigaDownloads = $Script:WorkingPath+'AmigaDownloads\'
if (-not(Test-Path $AmigaDownloads)){
    $null = New-Item $AmigaDownloads -ItemType Directory    
}

$ProgramsFolder= $Script:WorkingPath+'Programs\'
if (-not (Test-Path $ProgramsFolder)){
    $null = New-Item $ProgramsFolder -ItemType Directory
}

$TempFolder = $Script:WorkingPath +'Temp\'
if (-not (Test-Path $TempFolder)){
    $null = New-Item $TempFolder -ItemType Directory
}

#$Script:LocationofImage = $Script:WorkingPath+'OutputImage\' #Set in click button

if (-not (Test-Path $Script:LocationofImage)){
    $null = New-Item $Script:LocationofImage -ItemType Directory
}

$AmigaDrivetoCopy = $Script:WorkingPath+'AmigaImageFiles\'
if (-not (Test-Path $AmigaDrivetoCopy)){
    $null = New-Item $AmigaDrivetoCopy -ItemType Directory
}

$HSTImagePath = $ProgramsFolder+'HST-Imager\hst.imager.exe'
$HSTAmigaPath = $ProgramsFolder+'HST-Amiga\hst.amiga.exe'
$LZXPath = $ProgramsFolder+'unlzx.exe'

$HDFImageLocation = $Script:WorkingPath+'HDFImage\'

$NameofImage = ('Pistorm'+$Script:KickstartVersiontoUse+'.HDF')

if ($Script:SetDiskupOnly -eq 'FALSE'){
    $Script:TotalSections = 17
}
else{
    $TotalSections = 6
}

if (($Script:SetDiskupOnly -eq 'FALSE') -and (-not $Script:TransferLocation)){
    $TotalSections = $TotalSections - 1
}

if (($Script:ImageOnly -eq 'TRUE')){
    $TotalSections = $TotalSections - 1
}

if (($Script:DeleteAllWorkingPathFiles -eq 'FALSE')){
    $TotalSections = $TotalSections - 1
}

Write-Emu68ImagerLog -StartorContinue 'Continue' -LocationforLog $Script:LogLocation

$Script:CurrentSection = 1
$StartDateandTime = (Get-Date -Format HH:mm:ss)
Write-InformationMessage -Message "Starting execution at $StartDateandTime"

if ($Script:ImageOnly -eq 'FALSE'){
    Write-StartTaskMessage -Message 'Setting up SD card'
    
    Write-StartSubTaskMessage -Message 'Clearing Contents of SD Card' -SubtaskNumber 1 -TotalSubtasks 3
    
    # if (-not(Clear-Emu68ImagerSDDisk -DiskNumbertoUse $Script:HSTDiskNumber)){
    #     Write-ErrorMessage 'Unable to clear disk! Program halting!'
    #     exit
    # }
    
    if (-not (Repair-SDDisk -DiskNumbertoUse $Script:HSTDiskNumber -TempFoldertoUse $TempFolder)){
       Write-ErrorMessage 'Unable to clean disk! Program halting!'
       exit
    }   
        
    Write-StartSubTaskMessage -Message 'Adding Partitions to SD Card'-SubtaskNumber 2 -TotalSubtasks 3
    
    Write-InformationMessage ('Creating Partition for FAT32 Partition for Disk: '+$Script:HSTDiskNumber+' with size '+($Script:SizeofFAT32.ToString()+'KB')) 
    try {
        $null = New-Partition -DiskNumber $Script:HSTDiskNumber -Size ($Script:SizeofFAT32*1024)  -MbrType FAT32 | format-volume -filesystem FAT32 -newfilesystemlabel EMU68BOOT
    }
    catch {
        Write-ErrorMessage 'Error creating FAT32 Partition!'
        exit
    
    }
    
    Write-StartSubTaskMessage -message ('Creating Partition for Amiga Drives for Disk: '+$Script:HSTDiskNumber+' with size '+($Script:SizeofImage_Powershell.ToString()+'KB')) -SubtaskNumber 3 -TotalSubtasks 3
    try {
        $null = New-Partition -DiskNumber $Script:HSTDiskNumber  -Size ($Script:SizeofImage_Powershell*1024) -MbrType FAT32
    }
    catch {
        Write-ErrorMessage 'Error creating Amiga Partition!'
        exit
    }
    
    Write-InformationMessage -message 'Setting Amiga Partition to ID 76'
    try {
        Set-Partition -DiskNumber $Script:HSTDiskNumber -PartitionNumber 2 -MbrType 0x76
    }
    catch {
        Write-ErrorMessage 'Error setting Partition ID to 76! Exiting!'
        exit
    }
    
    if ((Get-Disk -Number $Script:HSTDiskNumber).PartitionStyle -ne 'MBR'){
        Write-ErrorMessage 'Card is not set up as MBR!'
        exit
    }

    if ([System.Convert]::ToString((((Get-Partition -DiskNumber $Script:HSTDiskNumber) | Where-Object {$_.PartitionNumber -eq 2}).MbrType),16) -ne 76){
        Write-ErrorMessage 'Amiga Partition is not set up as ID 76!'
        exit
    }
    
    if ([System.Convert]::ToString((((Get-Partition -DiskNumber $Script:HSTDiskNumber) | Where-Object {$_.PartitionNumber -eq 1}).MbrType),16) -ne 'c'){
        Write-ErrorMessage 'FAT32 Partition is not set up as FAT32!'
        exit
    }
    Write-TaskCompleteMessage -Message 'Setting up SD card - Complete!'
}

### Download HST-Imager and HST-Amiga

Write-StartTaskMessage -Message 'Downloading HST Packages'

Write-StartSubTaskMessage -Message 'Downloading HST Imager' -SubtaskNumber 1 -TotalSubtasks 2

if (-not(Get-GithubRelease -GithubRelease $HSTImagerreleases -Tag_Name '1.1.350' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTImager.zip') -LocationforProgram ($ProgramsFolder+'HST-Imager\') -Sort_Flag '')){
    Write-ErrorMessage -Message 'Error downloading HST-Imager! Cannot continue!'
    exit
}

if ($Script:SetDiskupOnly -eq 'FALSE'){
    Write-StartSubTaskMessage -Message 'Downloading HST Amiga' -SubtaskNumber 2 -TotalSubtasks 2
    
    if (-not(Get-GithubRelease -GithubRelease $HSTAmigareleases -Tag_Name '0.3.163' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTAmiga.zip') -LocationforProgram ($ProgramsFolder+'HST-Amiga\') -Sort_Flag '')){
        Write-ErrorMessage -Message 'Error downloading HST-Amiga! Cannot continue!'
        exit
    }
}

Write-TaskCompleteMessage -Message 'Downloading HST Packages - Complete!'

#### Download Emu68 Files

Write-StartTaskMessage -Message 'Downloading Emu68 Packages'

$PathstoTest='Emu68Pistorm','Emu68Pistorm32Lite','Emu68Tools'

foreach($Path in $PathstoTest){
    if(Test-Path ($TempFolder+$Path)){
        Remove-Item ($TempFolder+$Path) -Force -Recurse
    }
}

$PathstoTest='Emu68Pistorm.zip','Emu68Pistorm32Lite.zip','Emu68Tools.zip'

foreach($Path in $PathstoTest){
    if(Test-Path ($AmigaDownloads+$Path)){
        Remove-Item ($AmigaDownloads+$Path) -Force -Recurse
    }
}

Write-StartSubTaskMessage -Message 'Downloading Emu68Pistorm' -SubtaskNumber '1' -TotalSubtasks '3'

if (-not(Get-GithubRelease -GithubRelease $Emu68releases -OnlyReleaseVersions 'TRUE' -Name 'Emu68-pistorm.' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm\') -Sort_Flag 'SORT')){
    Write-ErrorMessage -Message'Error downloading Emu68Pistorm! Cannot continue!'
    exit
}

Write-StartSubTaskMessage -Message 'Downloading Emu68Pistorm32lite' -SubtaskNumber '2' -TotalSubtasks '3'

if (-not(Get-GithubRelease -GithubRelease $Emu68releases -OnlyReleaseVersions 'TRUE' -Name 'Emu68-pistorm32lite.' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm32lite.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm32lite\') -Sort_Flag 'SORT')){
    Write-ErrorMessage -Message 'Error downloading Emu68Pistorm32lite! Cannot continue!'
    exit
}

Write-StartSubTaskMessage -Message 'Downloading Emu68Tools' -SubtaskNumber '3' -TotalSubtasks '3'

if (-not(Get-GithubRelease -GithubRelease $Emu68Toolsreleases -Tag_Name "nightly" -Name 'Emu68-tools' -LocationforDownload ($AmigaDownloads+'Emu68Tools.zip') -LocationforProgram ($tempfolder+'Emu68Tools\') -Sort_Flag 'SORT')){
    Write-ErrorMessage -Message 'Error downloading Emu68Tools! Cannot continue! Quitting!'
    exit
}

Write-TaskCompleteMessage -Message 'Downloading Emu68 Packages - Complete'

### End Download Emu68

### Begin Download UnLzx

if ($Script:SetDiskupOnly -eq 'FALSE'){
    Write-StartTaskMessage -Message 'Downloading UnLZX'
    
    if (-not (Test-Path ($ProgramsFolder+'unlzx.exe'))){
        If (-not (Get-AmigaFileWeb -URL $UnLZXURL -NameofDL 'W95unlzx.lha' -LocationforDL $TempFolder)){
            Write-ErrorMessage -Message 'Error downloading UnLZX! Quitting'
            exit
        }
        if (-not(Expand-Zipfiles -SevenzipPathtouse $7zipPath -TempFoldertouse $TempFolder -InputFile ($TempFolder+'W95unlzx.lha') -OutputDirectory $ProgramsFolder -FiletoExtract 'unlzx.exe')){
            Write-InformationMessage -Message ('Deleting package '+($TempFolder+'W95unlzx.lha'))
            $null=Remove-Item -Path ($TempFolder+'W95unlzx.lha') -Force
            Write-ErrorMessage -Message 'Error extracting UnLZX! Quitting'
            exit
        }
    }
    else{
        Write-InformationMessage -Message "Unlzx already exists."
    }
    
    Write-TaskCompleteMessage -Message 'Downloading LZX - Complete!'

}

### End Download UnLzx

Write-StartTaskMessage -Message 'Preparing Amiga Image'

if (Test-Path ($HDFImageLocation +$NameofImage)){
    $null = Remove-Item -Path ($HDFImageLocation +$NameofImage)
}

if (-not (Start-HSTImager -Command "Blank" -DestinationPath ($HDFImageLocation +$NameofImage) -ImageSize $Script:SizeofImage_HST -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 

& $Script:FindLockPath ($HDFImageLocation+$NameofImage) >($TempFolder+'FindLockLog.txt')
$CheckforLock = Get-Content -Path ($TempFolder+'FindLockLog.txt')

if ($CheckforLock -ne 'File is not locked!'){
    Write-ErrorMessage -Message 'Unable to continue! Another process (e.g. antimalware and/or antivirus) has locked access to the file!'
    Write-ErrorMessage -Message $CheckforLock
    exit

}

if (-not (Start-HSTImager -Command "rdb init" -DestinationPath ($HDFImageLocation +$NameofImage) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 

if (-not (Start-HSTImager -Command "rdb filesystem add" -DestinationPath ($HDFImageLocation +$NameofImage) -FileSystemPath ($Script:WorkingPath+'Programs\HST-Imager\pfs3aio') -DosType 'PFS3' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 

## Setting up Amiga Partitions List

$AmigaPartitionsList = Get-AmigaPartitionList   -SizeofPartition_System_param  ($Script:SizeofPartition_System) `
                                                -SizeofPartition_Other_param ($Script:SizeofPartition_Other) `
                                                -VolumeName_System_param $VolumeName_System `
                                                -DeviceName_System_param $DeviceName_System `
                                                -PFSLimit $Script:PFSLimit  `
                                                -VolumeName_Other_param $VolumeName_Other `
                                                -DeviceName_Other_param $DeviceName_Other `
                                                -DeviceName_Prefix_param $DeviceName_Prefix
 
                                              

foreach ($AmigaPartition in $AmigaPartitionsList) {
    if ($AmigaPartition.PartitionNumber -ne 0){
        Write-InformationMessage -Message ('Preparing Partition Device: '+$AmigaPartition.DeviceName+' VolumeName '+$AmigaPartition.VolumeName)
        if ($AmigaPartition.VolumeName -eq $VolumeName_System){
            if (-not (Start-HSTImager -Command "rdb part add" -DestinationPath ($HDFImageLocation+$NameofImage) -DeviceName $AmigaPartition.DeviceName -DosType $AmigaPartition.DosType -SizeofPartition $AmigaPartition.SizeofPartition_HST -Options '--bootable' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                exit
            } 
        }
        else{
            if (-not (Start-HSTImager -Command "rdb part add" -DestinationPath ($HDFImageLocation +$NameofImage) -DeviceName $AmigaPartition.DeviceName -DosType $AmigaPartition.DosType -SizeofPartition $AmigaPartition.SizeofPartition_HST -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                exit
            } 
        }
    }
}

if (-not (Start-HSTImager -Command "rdb part format" -DestinationPath ($HDFImageLocation +$NameofImage) -PartitionNumber 1 -VolumeName $VolumeName_System -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 
if (-not (Start-HSTImager -Command "rdb part format" -DestinationPath ($HDFImageLocation +$NameofImage) -PartitionNumber 2 -VolumeName $VolumeName_Other -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 

# foreach ($AmigaPartition in $AmigaPartitionsList) {
#     if ($AmigaPartition.PartitionNumber -ne 0){
#         if (-not (Start-HSTImager -Command "rdb part format" -DestinationPath ($HDFImageLocation +$NameofImage) -PartitionNumber ($AmigaPartition.PartitionNumber).tostring() -VolumeName $AmigaPartition.VolumeName -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
#         exit
#         } 
#     }
# }


if ($Script:SetDiskupOnly -eq 'FALSE'){
    #### Begin - Create NewFolder.info file
    if (($Script:KickstartVersiontoUse -eq 3.1) -or (($Script:KickstartVersiontoUse -ge 3.2) -and ($GlowIcons -eq 'FALSE'))) {
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\Monitors.info') -DestinationPath ($TempFolder.TrimEnd('\'))  -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        }
        if (Test-Path ($TempFolder+'def_drawer.info')){
            $null = Remove-Item ($TempFolder+'def_drawer.info')
        }
        $null = Rename-Item ($TempFolder+'Monitors.info') ($TempFolder+'def_drawer.info')
    }
    elseif(($Script:KickstartVersiontoUse -ge 3.2) -and ($GlowIcons -eq 'TRUE')){
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($GlowIconsADF+'\Prefs\Env-Archive\Sys\def_drawer.info') -DestinationPath ($TempFolder.TrimEnd('\')) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        }
    }
    
    if (Test-Path ($TempFolder+'NewFolder.info')){
        $null = Remove-Item ($TempFolder+'NewFolder.info')
    } 
    $null = Rename-Item ($TempFolder+'def_drawer.info') ($TempFolder+'NewFolder.info') -Force
    
    #### End - Create NewFolder.info file


    ### Begin Basic Drive Setup

    if (Test-path $AmigaDrivetoCopy){
        $null=Remove-Item -Path ($AmigaDrivetoCopy+'*') -Recurse -Force
    }

    Add-AmigaFolder -AmigaFolderPath ($VolumeName_System+'\Programs\') -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    Add-AmigaFolder -AmigaFolderPath ($VolumeName_System+'\Storage\DataTypes\') -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    
    if ($Script:KickstartVersiontoUse -eq 3.1){
    
        if (-not (test-path ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\'))){
            $null = new-item ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\') -ItemType Directory
        } 
    
        if (-not (test-path ($AmigaDrivetoCopy+$VolumeName_System+'\Devs\Keymaps\'))){
            $null = new-item ($AmigaDrivetoCopy+$VolumeName_System+'\Devs\Keymaps\') -ItemType Directory -Force
        }  
    
    }
    
     if (-not (test-path ($AmigaDrivetoCopy + $VolumeName_System + '\Expansion\'))) {
        $null = new-item ($AmigaDrivetoCopy + $VolumeName_System + '\Expansion\') -ItemType Directory -Force
    }  
    
    if (-not (Test-Path ($AmigaDrivetoCopy+$VolumeName_Other))){
        $null = New-Item -path ($AmigaDrivetoCopy+$VolumeName_Other) -ItemType Directory -Force 
        
    }
    
    if ($Script:KickstartVersiontoUse -eq 3.1){
        $SourcePath = ($InstallADF+'\Update\disk.info') 
    }
    
    elseif ($Script:KickstartVersiontoUse -ge 3.2){
        $SourcePath = ($GlowIconsADF+'\Prefs\Env-Archive\Sys\def_harddisk.info') 
    }   

    Write-InformationMessage -Message ('Copying Icons to Work Partition. Source is: '+$SourcePath+' Destination is: '+$DestinationPathtoUse)
    $DestinationPathtoUse = ($AmigaDrivetoCopy+$VolumeName_Other)
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePath -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                exit
    }

    if ($Script:KickstartVersiontoUse -ge 3.2){
        Rename-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\def_harddisk.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info') 
        if (-not (Write-AmigaIconPostition -HSTAmigaPathtouse $HSTAmigaPath -TempFoldertouse $TempFolder -IconPath ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info') -XPos 15 -YPos 65)){
            Write-ErrorMessage -Message 'Unable to reposition icon!'
        }
    }
   
    # foreach ($AmigaPartition in $AmigaPartitionsList) {
    #     if ($AmigaPartition.PartitionNumber -gt 2){
    #         $SourcePathtoUse = ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info')  #Using Work disk.info extracted to Windows to copy to RDB for additional Work partitions
    #         $DestinationPathtoUse = ($HDFImageLocation +$NameofImage+'\rdb\'+$AmigaPartition.DeviceName+'\disk.info')
    #         Write-InformationMessage -Message ('Copying Icons to extra Work Partition(s). Source is: '+$SourcePathtoUse+' Destination is: '+$DestinationPathtoUse) 
    #         if (-not (Start-HSTImager -Command 'fs copy' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    #                  exit
    #      }
    #     }
    # }   

    Write-TaskCompleteMessage -Message 'Preparing Amiga Image - Complete!'

}

if ($Script:SetDiskupOnly -eq 'FALSE'){
    ### End Basic Drive Setup
    
    ### Begin Copy Install files from ADF
    
    Write-StartTaskMessage -Message 'Processing and Installing ADFs'
    
    $TotalItems=$ListofInstallFiles.Count
    
    $ItemCounter=1
    
    Foreach($InstallFileLine in $ListofInstallFiles){
        Write-StartSubTaskMessage -SubtaskNumber $ItemCounter -TotalSubtasks $TotalItems -Message ('Processing ADF:'+$InstallFileLine.FriendlyName+' Files: '+$InstallFileLine.AmigaFiletoInstall)
        $SourcePathtoUse = ($InstallFileLine.Path+'\'+($InstallFileLine.AmigaFiletoInstall -replace '/','\'))
        if ($InstallFileLine.Uncompress -eq "TRUE"){
            Write-InformationMessage -Message 'Extracting files from ADFs containing .Z files'
            if ($InstallFileLine.LocationtoInstall.Length -eq 0){        
                $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName)
            }
            else{  
                $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+($InstallFileLine.LocationtoInstall -replace '/','\')) 
            }
            if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                exit
            }
            Expand-AmigaZFiles  -SevenzipPathtouse $7zipPath -WorkingFoldertouse $TempFolder -LocationofZFiles $DestinationPathtoUse
        }    
        elseif (($InstallFileLine.NewFileName -ne "")  -or ($InstallFileLine.ModifyScript -ne 'FALSE') -or ($InstallFileLine.ModifyInfoFileTooltype -ne 'FALSE')){
            if ($InstallFileLine.LocationtoInstall -ne '`*'){
                $LocationtoInstall=(($InstallFileLine.LocationtoInstall -replace '/','\')+'\')
            }
            else{
                $LocationtoInstall=$null
            }
            if ($InstallFileLine.NewFileName -ne ""){
                $FullPath = $AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$InstallFileLine.NewFileName
            }
            else{
                $FullPath = $AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+(Split-Path ($InstallFileLine.AmigaFiletoInstall -replace '/','\') -Leaf) 
            }
            $filename = Split-Path $FullPath -leaf
            Write-InformationMessage -Message 'Extracting files from ADFs where changes needed'
            if ($InstallFileLine.LocationtoInstall.Length -eq 0){
                $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName)
            }
            else{        
                $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+($InstallFileLine.LocationtoInstall -replace '/','\'))
            }
            if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                exit
            }
            if ($InstallFileLine.NewFileName -ne ""){
                $NameofFiletoChange=$InstallFileLine.AmigaFiletoInstall.split("/")[-1]  
                if (Test-Path ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$InstallFileLine.NewFileName)){
                    Remove-Item ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$InstallFileLine.NewFileName)
                }
                $null = rename-Item -Path ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$NameofFiletoChange) -NewName $InstallFileLine.NewFileName            
            }
            if ($InstallFileLine.ModifyInfoFileTooltype -eq 'Modify'){
                if (-not (Read-AmigaTooltypes -IconPath ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$filename) -TooltypesPath ($TempFolder+$filename+'.txt') -HSTAmigaPathtouse $HSTAmigaPath -TempFoldertouse $TempFolder)){
                    exit
                }                 
                $OldToolTypes = Get-Content($TempFolder+$filename+'.txt')
                $TooltypestoModify = Import-Csv ($LocationofAmigaFiles+$LocationtoInstall+'\'+$filename+'.txt') -Delimiter ';'
                Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $TooltypestoModify | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
                if (-not (Write-AmigaTooltypes -IconPath ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$filename) -ToolTypesPath ($TempFolder+$fileName+'amendedtoimport.txt') -TempFoldertouse $TempFolder -HSTAmigaPathtouse $HSTAmigaPath)){
                    exit
                }                 
            }        
            if ($InstallFileLine.ModifyScript -eq'Remove'){
                Write-InformationMessage -Message  ('Modifying '+$FileName+' for: '+$InstallFileLine.ScriptNameofChange)
                $ScripttoEdit = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$FileName)
                $ScripttoEdit = Edit-AmigaScripts -ScripttoEdit $ScripttoEdit -Action 'remove' -name $InstallFileLine.ScriptNameofChange -Startpoint $InstallFileLine.ScriptInjectionStartPoint -Endpoint $InstallFileLine.ScriptInjectionEndPoint                    
                Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$FileName) -DatatoExport $ScripttoEdit -AddLineFeeds 'TRUE'
            }   
        }
        else {
            Write-InformationMessage -Message 'Extracting files from ADFs to .hdf file'
            if ($InstallFileLine.LocationtoInstall.Length -eq 0){
               $DestinationPathtoUse = ($HDFImageLocation +$NameofImage+'\rdb\'+$DeviceName_System)
            }
            else{
               $DestinationPathtoUse = ($HDFImageLocation +$NameofImage+'\rdb\'+$DeviceName_System+'\'+($InstallFileLine.LocationtoInstall -replace '/','\'))
            }
            if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                exit
            }
        }         
        $ItemCounter+=1    
    }
    
    Write-TaskCompleteMessage -Message 'Processing and Installing ADFs - Complete!'
    
    ### End Copy Install files from ADF
    
    #######################################################################################################################################################################################################################################
    
    $ListofPackagestoInstall = Get-ListofPackagestoInstall -ListofPackagestoInstallCSV ($InputFolder+'ListofPackagestoInstall.csv') |  Where-Object {$_.KickstartVersion -eq $Script:KickstartVersiontoUse} | Where-Object {$_.InstallFlag -eq 'TRUE'} #| Sort-Object -Property 'InstallSequence','PackageName'
    
    $ListofPackagestoInstall | Add-Member -NotePropertyName DrivetoInstall_VolumeName -NotePropertyValue $null
    
    foreach ($line in $ListofPackagestoInstall){
        if ($line.DrivetoInstall -eq 'System'){
            $line.DrivetoInstall_VolumeName = $VolumeName_System
        }
    }
    
    $PackageCheck=$null
    
    # Download and expand packages
    
    Write-StartTaskMessage -Message 'Downloading Packages'
    
    
    $TotalItems=(
        $ListofPackagestoInstall | Where-Object InstallType -ne 'CopyOnly' |  Where-Object InstallType -ne 'StartupSequenceOnly' | Select-Object -Unique -Property PackageName
        ).count 
    
    $ItemCounter=1
    
    foreach($PackagetoFind in $ListofPackagestoInstall) {
        if (($PackagetoFind.InstallType -ne 'CopyOnly') -and ($PackagetoFind.InstallType -ne 'StartupSequenceOnly')){
            if ($PackageCheck -ne $PackagetoFind.PackageName){
                Write-StartSubTaskMessage -SubtaskNumber $ItemCounter -TotalSubtasks $TotalItems -Message ('Downloading (or Copying) package '+$PackagetoFind.PackageName)
                if ($PackagetoFind.Source -eq "ADF") {
                    if ($PackagetoFind.SourceLocation -eq 'StorageADF'){
                        $ADFtoUse = $StorageADF
                        $SourcePathtoUse = ($ADFtoUse+'\'+$PackagetoFind.FilestoInstall)
                        $DestinationPathtoUse = ($TempFolder+$PackagetoFind.FileDownloadName).Trim('\')       
                        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                            exit
                        }
                    }
                }
                Elseif ($PackagetoFind.Source -eq "Web"){
                    if(($PackagetoFind.SearchforUpdatedPackage -eq 'TRUE') -and ($PackagetoFind.PackageName -ne 'WHDLoadWrapper')){
                        $PackagetoFind.SourceLocation=Find-LatestAminetPackage -PackagetoFind $PackagetoFind.PackageName -Exclusion $PackagetoFind.UpdatePackageSearchExclusionTerm -DateNewerthan $PackagetoFind.UpdatePackageSearchMinimumDate -Architecture 'm68k-amigaos'   
                    }
                    if(($PackagetoFind.SearchforUpdatedPackage -eq 'TRUE') -and ($PackagetoFind.PackageName -eq 'WHDLoadWrapper')){
                        $PackagetoFind.SourceLocation=(Find-WHDLoadWrapperURL -SearchCriteria 'WHDLoadWrapper' -ResultLimit '10') 
                    }
                    if (Test-Path ($AmigaDownloads+$PackagetoFind.FileDownloadName)){
                        Write-InformationMessage -Message "Download already completed"
                    } 
                    else{
                        if (-not (Get-AmigaFileWeb -URL $PackagetoFind.SourceLocation -NameofDL $PackagetoFind.FileDownloadName -LocationforDL $AmigaDownloads)){
                            Write-ErrorMessage -Message 'Unrecoverable error with download(s)!'
                            exit
                        }                    
                    }
                    if ($PackagetoFind.PerformHashCheck -eq 'TRUE'){
                        if (-not (Compare-FileHash -FiletoCheck ($AmigaDownloads+$PackagetoFind.FileDownloadName) -HashtoCheck $PackagetoFind.Hash)){
                            Write-ErrorMessage -Message 'Error in downloaded packages! Unable to continue!'
                            Write-InformationMessage -Message ('Deleting package '+($AmigaDownloads+$PackagetoFind.FileDownloadName))
                            $null=Remove-Item -Path ($AmigaDownloads+$PackagetoFind.FileDownloadName) -Force 
                            exit
                        }
                    }
                }
                Elseif (($PackagetoFind.Source -eq "Local") -and ($PackagetoFind.InstallType -eq "Full")){
                    Write-InformationMessage -Message ('Copying local file '+$PackagetoFind.SourceLocation)
                    if (Test-Path ($AmigaDownloads+$PackagetoFind.FileDownloadName)){
                        Write-InformationMessage -Message 'File already copied'
                    }
                    else {
                        Copy-Item ($LocationofAmigaFiles+$PackagetoFind.SourceLocation) ($AmigaDownloads+$PackagetoFind.FileDownloadName)
                    }
                }
                if ($PackagetoFind.InstallType -eq "Full"){
                    Write-InformationMessage -Message ('Expanding archive file for package '+$PackagetoFind.PackageName)
                    if ([System.IO.Path]::GetExtension($PackagetoFind.FileDownloadName) -eq '.lzx'){
                        Expand-LZXArchive -LZXPathtouse $LZXPath -WorkingFoldertouse  $Script:WorkingPath -LZXFile ($AmigaDownloads+$PackagetoFind.FileDownloadName) -TempFoldertouse $TempFolder -DestinationPath ($TempFolder+$PackagetoFind.FileDownloadName) 
                    } 
                    if ([System.IO.Path]::GetExtension($PackagetoFind.FileDownloadName) -eq '.lha'){
                        if (-not(Expand-Zipfiles -SevenzipPathtouse $7zipPath -TempFoldertouse $TempFolder -InputFile ($AmigaDownloads+$PackagetoFind.FileDownloadName) -OutputDirectory ($TempFolder+$PackagetoFind.FileDownloadName))){
                            Write-ErrorMessage -Message 'Error in extracting!' 
                            Write-InformationMessage -Message ('Deleting package '+($AmigaDownloads+$PackagetoFind.FileDownloadName))
                            $null=Remove-Item -Path ($AmigaDownloads+$PackagetoFind.FileDownloadName) -Force
                            exit
                        }
                                   
                    } 
                }
    
                $ItemCounter+=1    
            }
            $PackageCheck=$PackagetoFind.PackageName
                
        }
    }
    
    Write-TaskCompleteMessage -Message 'Downloading Packages - Complete!'
    
    $PackageCheck=$null
    $UserStartup=$null
    $StartupSequence = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\Startup-Sequence') 
    $StartupSequenceversion = Get-StartupSequenceVersion -StartupSequencetoCheck $StartupSequence
    
    Write-StartTaskMessage -Message 'Installing Packages'
    
    $TotalItems=(
        $ListofPackagestoInstall | Select-Object -Unique -Property PackageName
        ).count 
    
    $ItemCounter=1
    
    foreach($PackagetoFind in $ListofPackagestoInstall) {
        if ($PackageCheck -ne $PackagetoFind.PackageName){
            Write-StartSubTaskMessage -SubtaskNumber $ItemCounter -TotalSubtasks $TotalItems -Message ('Installing package '+$PackagetoFind.PackageName)       
            if ($PackagetoFind.ModifyUserStartup -eq'TRUE'){
                Write-InformationMessage -Message ('Modifying S/User-Startup file for: '+$PackagetoFind.PackageName)
                $UserStartup += Edit-AmigaScripts -name $PackagetoFind.PackageName -Action 'Append' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'S\User-Startup_'+$PackagetoFind.PackageName))
                
            }
            if ($PackagetoFind.ModifyStartupSequence -eq'Add'){
                Write-InformationMessage -Message ('Modifying S/Startup-Sequence file for: '+$PackagetoFind.PackageName) 
                $InjectionPoint=Get-StartupSequenceInjectionPointfromVersion -SSversion $StartupSequenceversion -InjectionPointtoParse $PackagetoFind.StartupSequenceInjectionStartPoint
                $StartupSequence = Edit-AmigaScripts -ScripttoEdit $StartupSequence -Action 'inject' -injectionpoint 'before' -name $PackagetoFind.PackageName -Startpoint $InjectionPoint -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'S\Startup-Sequence_'+$PackagetoFind.PackageName))            
            }
            $ItemCounter+=1    
        }   
        if (($PackagetoFind.InstallType -eq 'CopyOnly') -or
           ($PackagetoFind.InstallType -eq 'Full') -or
           ($PackagetoFind.InstallType -eq 'Extract')){
               ### Determining Source Paths
               $DestinationPathtoUse =($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall) 
               if ($PackagetoFind.Source -eq 'Web'){
                   $SourcePathtoUse=($TempFolder+$PackagetoFind.FileDownloadName+'\'+$PackagetoFind.FilestoInstall)  
               }
               if ($PackagetoFind.Source -eq 'Emu68' ){
                   $SourcePathtoUse=($TempFolder+$PackagetoFind.SourceLocation)       
               }
               elseif ($PackagetoFind.Source -eq 'ADF' ) {
                   $SourcePathtoUse=($TempFolder+$PackagetoFind.FilestoInstall)     
               }
               elseif (($PackagetoFind.Source -eq 'Local') -and ($PackagetoFind.InstallType -eq 'CopyOnly')){
                   $SourcePathtoUse=($LocationofAmigaFiles+$PackagetoFind.SourceLocation)
               }
               elseif (($PackagetoFind.Source -eq 'Local') -and ($PackagetoFind.InstallType -eq 'Full')){
                   $SourcePathtoUse=($TempFolder+$PackagetoFind.FileDownloadName+'\'+$PackagetoFind.FilestoInstall)     
               }
               #### End Determining SourcePaths
               Write-InformationMessage -Message ('Creating directories where required - Folder '+$PackagetoFind.LocationtoInstall)
               if (-not (Test-Path ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall))){
                   $null = New-Item ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall) -ItemType Directory
               }
               if ($PackagetoFind.CreateFolderInfoFile -eq 'TRUE'){
                   Add-AmigaFolder -AmigaFolderPath ($PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall) -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
               }
               #### Copy Files
               if ($PackagetoFind.NewFileName.Length -ne 0){
                   $DestinationPathtoUse=$DestinationPathtoUse+$PackagetoFind.NewFileName
                   Write-InformationMessage -Message ('Copying files to drive. Source path is: '+$SourcePathtoUse+' Destination path is: '+$DestinationPathtoUse+' (New Name is '+$PackagetoFind.NewFileName+')')
               }
               else{
                Write-InformationMessage -Message ('Copying files to drive. Source path is: '+$SourcePathtoUse+' Destination path is: '+$DestinationPathtoUse)        
               }
               Copy-Item -Path $SourcePathtoUse  -Destination $DestinationPathtoUse -Recurse -force  
               #### End Copy Files
               if (($PackagetoFind.ModifyInfoFileTooltype -eq 'Replace') -or ($PackagetoFind.ModifyInfoFileTooltype -eq 'Modify')) {
                Write-InformationMessage -Message  ('Tooltypes for relevant .info files for: '+$PackagetoFind.PackageName)
                   if ($PackagetoFind.NewFileName){
                       $filename=$PackagetoFind.NewFileName
                   }
                   else{
                       $filename=(Split-Path $PackagetoFind.FilestoInstall -Leaf)
                   }        
                   $Tooltypes=Import-Csv ($LocationofAmigaFiles+$PackagetoFind.LocationtoInstall+$filename+'.txt') -Delimiter ';'
                   if ($PackagetoFind.ModifyInfoFileTooltype -eq 'Replace'){
                       $Tooltypes.NewValue | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
                   }
                   if ($PackagetoFind.ModifyInfoFileTooltype -eq 'Modify'){
                       If (-not(Read-AmigaTooltypes -IconPath ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall+$filename) -TooltypesPath ($TempFolder+$filename+'.txt') -HSTAmigaPathtouse $HSTAmigaPath -TempFoldertouse $TempFolder)){
                           exit 
                    } 
                       $OldToolTypes= Get-Content($TempFolder+$filename+'.txt')
                       Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $Tooltypes  | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
                   }
                   if (-not (Write-AmigaTooltypes -IconPath ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall+$filename) -ToolTypesPath ($TempFolder+$filename+'amendedtoimport.txt') -TempFoldertouse $TempFolder -HSTAmigaPathtouse $HSTAmigaPath)){
                       exit
                }                             
               }
               else {
               }    
           }
        $PackageCheck=$PackagetoFind.PackageName  
    }
    
    Write-TaskCompleteMessage -Message 'Installing Packages -Complete!'
    
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\Startup-Sequence') -DatatoExport $StartupSequence -AddLineFeeds 'TRUE'
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\User-Startup') -DatatoExport $UserStartup -AddLineFeeds 'TRUE'
    
    ### Wireless Prefs
    
    #Update-OutputWindow -OutputConsole_Title_Text 'Creating Wireless Prefs file' -ProgressbarValue_Overall 50 -ProgressbarValue_Overall_Text '50%'
    
    Write-StartTaskMessage -Message 'Creating Wireless Prefs file'

    
    Write-StartTaskMessage -Message 'Creating Documentation files'
    
    if (-not (Test-path ($AmigaDrivetoCopy+$VolumeName_System+'\PiStorm\Docs\'))){
        $null = New-Item ($AmigaDrivetoCopy+$VolumeName_System+'\PiStorm\Docs\') -ItemType Directory
    } 

    Get-Emu68ImagerDocumentation -LocationtoDownload ($AmigaDrivetoCopy+$VolumeName_System+'\PiStorm\Docs\')
    
    Write-TaskCompleteMessage -Message 'Creating Documentation files - Complete!'
    
    if (-not (Test-Path ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\'))){
        $null = New-Item -path ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys') -ItemType Directory -Force 
    
    }
    
    $WirelessPrefs = "network={",
                     "   ssid=""$Script:SSID""",
                     "   psk=""$Script:WifiPassword""",
                     "}"
                     
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\wireless.prefs') -DatatoExport $WirelessPrefs -AddLineFeeds 'TRUE'                
    
    Write-TaskCompleteMessage -Message 'Creating Wireless Prefs File - Complete!'
    
    ### End Wireless Prefs
    
    ### Fix WBStartup
    
    Write-StartTaskMessage -Message 'Fix WBStartup'
    
    If ($Script:KickstartVersiontoUse -ge 3.2){
        Write-Host 'Fixing Menutools'
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\WBStartup\MenuTools') -DestinationPath ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup') -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        }
        
        $WBStartup = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\Menutools') 
        $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Wait' -Injectionpoint 'after' -Startpoint 'ADDRESS WORKBENCH' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_1')) -ArexxFlag 'AREXX'
        $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Offline and Online Menus' -Injectionpoint 'before' -Startpoint 'EXIT' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_2')) -ArexxFlag 'AREXX'
        
        Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\Menutools') -DatatoExport $WBStartup -AddLineFeeds 'TRUE'
    }
    
    Write-TaskCompleteMessage -Message 'Fix WB Startup - Complete!'
    
    ## Clean up AmigaImageFiles
    
    Write-StartTaskMessage -Message 'Clean up AmigaImageFiles'
    
    if (Test-Path ($AmigaDrivetoCopy+$VolumeName_System+'\Disk.info')){
        Remove-Item ($AmigaDrivetoCopy+$VolumeName_System+'\Disk.info')
    }
    
    Write-TaskCompleteMessage -Message 'Clean up AmigaImageFiles - Complete!'
}

If ($Script:ImageOnly -eq 'FALSE'){
    Add-PartitionAccessPath -DiskNumber $Script:HSTDiskNumber -PartitionNumber 1 -AssignDriveLetter
    $Script:Fat32DrivePath = ((Get-Partition -DiskNumber $Script:HSTDiskNumber -PartitionNumber 1).DriveLetter)+':\'
}
else {
    $Script:Fat32DrivePath = $FAT32Partition
}


#### Set up FAT32

Write-StartTaskMessage -Message 'Setting up FAT32 files'

Write-InformationMessage -Message 'Copying Emu68Pistorm and Emu68Pistorm32lite files' 

if (($Script:KickstartVersiontoUse -ge 3.2) -and ($Script:SetDiskupOnly -eq 'FALSE')){
    $SourcePath = ($GlowIconsADF+'\Prefs\Env-Archive\Sys\def_harddisk.info')
    $DestinationPathtoUse = ($Script:Fat32DrivePath).TrimEnd('\') 
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePath -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    }
    Rename-Item ($Script:Fat32DrivePath+'def_harddisk.info') ($Script:Fat32DrivePath+'disk.info') 
    if (-not(Write-AmigaIconPostition -HSTAmigaPathtouse $HSTAmigaPath -TempFoldertouse $TempFolder -IconPath ($Script:Fat32DrivePath+'disk.info') -XPos 109 -YPos 65)){
        Write-ErrorMessage -Message 'Unable to reposition icon!'
    }
}
 
$null = copy-Item ($TempFolder+"Emu68Pistorm\*") -Destination ($Script:Fat32DrivePath )
$null = copy-Item ($TempFolder+"Emu68Pistorm32lite\*") -Destination ($Script:Fat32DrivePath )
$null= Remove-Item ($Script:Fat32DrivePath +'config.txt')
$null = copy-Item ($LocationofAmigaFiles+'FAT32\ps32lite-stealth-firmware.gz') -Destination ($Script:Fat32DrivePath )

if (-not (Test-Path ($Script:Fat32DrivePath+'Kickstarts\'))){
    $null = New-Item -path ($Script:Fat32DrivePath +'Kickstarts\') -ItemType Directory -Force
}

if (-not (Test-Path ($Script:Fat32DrivePath +'Install\'))){
    $null = New-Item -path ($Script:Fat32DrivePath +'Install\') -ItemType Directory -Force
}

Write-InformationMessage -Message 'Copying Cmdline.txt' 

Copy-Item ($LocationofAmigaFiles+'FAT32\cmdline_'+$Script:KickstartVersiontoUse+'.txt') -Destination ($Script:Fat32DrivePath+'cmdline.txt') 


$ConfigTxt = Get-Content -Path ($LocationofAmigaFiles+'FAT32\config.txt')

Write-InformationMessage -Message 'Preparing Config.txt'

$RevisedConfigTxt=$null

$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.CSV') -Delimiter (';') | Where-Object {$_.Include -eq 'TRUE'}
foreach ($AvailableScreenMode in $AvailableScreenModes){
    if ($AvailableScreenMode.Name -eq  $Script:ScreenModetoUse){
        $AvailableScreenMode.Selected = $true
    }
}

foreach ($Line in $ConfigTxt) {
    if ($line -eq '[ROMPATH]'){
        $RevisedConfigTxt+=('initramfs '+$KickstartNameFAT32)+"`n"
    }
    elseif ($line -eq '[VIDEOMODES]'){
        $RevisedConfigTxt+="# The following section defines the screenmode for your monitor for output from the Raspberry Pi. If you wish to `n"
        $RevisedConfigTxt+="# select a different screenmode you can comment out the existing mode and remove the comment marks from the new one.`n"
        foreach ($AvailableScreenMode in ($AvailableScreenModes | Sort-Object -Property 'Selected' -Descending)){
            if ($AvailableScreenMode.Selected -eq $true){
                $RevisedConfigTxt+="`n"
                $RevisedConfigTxt+=('# ScreenMode: '+$AvailableScreenMode.FriendlyName)+' (Currently Selected)'+"`n"
                if (-not ($AvailableScreenMode.hdmi_group.Length -eq 0)){
                    $RevisedConfigTxt+=('hdmi_group='+$AvailableScreenMode.hdmi_group)+"`n"
                }
                if (-not ($AvailableScreenMode.hdmi_mode.Length -eq 0)){
                    $RevisedConfigTxt+=('hdmi_mode='+$AvailableScreenMode.hdmi_mode)+"`n"
                }
                if (-not ($AvailableScreenMode.hdmi_cvt.length -eq 0)){
                    $RevisedConfigTxt+=('hdmi_cvt='+$AvailableScreenMode.hdmi_cvt)+"`n"
                }
                if (-not ($AvailableScreenMode.max_framebuffer_width.length -eq 0)){
                    $RevisedConfigTxt+=('max_framebuffer_width='+$AvailableScreenMode.max_framebuffer_width)+"`n"
                }
                if (-not ($AvailableScreenMode.max_framebuffer_height.length -eq 0)){
                    $RevisedConfigTxt+=('max_framebuffer_height='+$AvailableScreenMode.max_framebuffer_height)+"`n"
                }
                if (-not ($AvailableScreenMode.hdmi_pixel_freq_limit.length -eq 0)){
                    $RevisedConfigTxt+=('hdmi_pixel_freq_limit='+$AvailableScreenMode.hdmi_pixel_freq_limit)+"`n"
                }
                if (-not ($AvailableScreenMode.disable_overscan.length -eq 0)){
                    $RevisedConfigTxt+=('disable_overscan='+$AvailableScreenMode.disable_overscan)+"`n"
                }
            }
            else{
                $RevisedConfigTxt+="`n"
                $RevisedConfigTxt+=('# ScreenMode: '+$AvailableScreenMode.FriendlyName)+"`n"
                if (-not ($AvailableScreenMode.hdmi_group.Length -eq 0)){
                    $RevisedConfigTxt+=('# hdmi_group='+$AvailableScreenMode.hdmi_group)+"`n"
                }
                if (-not ($AvailableScreenMode.hdmi_mode.Length -eq 0)){
                    $RevisedConfigTxt+=('# hdmi_mode='+$AvailableScreenMode.hdmi_mode)+"`n"
                }
                if (-not ($AvailableScreenMode.hdmi_cvt.length -eq 0)){
                    $RevisedConfigTxt+=('# hdmi_cvt='+$AvailableScreenMode.hdmi_cvt)+"`n"
                }
                if (-not ($AvailableScreenMode.max_framebuffer_width.length -eq 0)){
                    $RevisedConfigTxt+=('# max_framebuffer_width='+$AvailableScreenMode.max_framebuffer_width)+"`n"
                }
                if (-not ($AvailableScreenMode.max_framebuffer_height.length -eq 0)){
                    $RevisedConfigTxt+=('# max_framebuffer_height='+$AvailableScreenMode.max_framebuffer_height)+"`n"
                }
                if (-not ($AvailableScreenMode.hdmi_pixel_freq_limit.length -eq 0)){
                    $RevisedConfigTxt+=('# hdmi_pixel_freq_limit='+$AvailableScreenMode.hdmi_pixel_freq_limit)+"`n"
                }
                if (-not ($AvailableScreenMode.disable_overscan.length -eq 0)){
                    $RevisedConfigTxt+=('# disable_overscan='+$AvailableScreenMode.disable_overscan)+"`n"
                }            
            }            
        }
    }
    else{
        $RevisedConfigTxt += ($Line+"`n")
    }    
}
Export-TextFileforAmiga -DatatoExport $RevisedConfigTxt -ExportFile ($Script:Fat32DrivePath+'config.txt') -AddLineFeeds 'TRUE' 

Write-InformationMessage -Message 'Copying Kickstart file to FAT32 partition'
$null = copy-Item -LiteralPath $KickstartPath -Destination ($Script:Fat32DrivePath+$KickstartNameFAT32)


Write-TaskCompleteMessage -Message 'Setting up FAT32 Files - Complete!'

### Transfer files to Work partition

if ($Script:TransferLocation) {
    Write-StartTaskMessage -Message 'Transferring files to Work Partition. This might take some time depending on how many files you are transferring'
    Write-InformationMessage -Message ('Transferring files from '+$TransferLocation+' to "'+$MigratedFilesFolder+'" directory on Work drive')
    $SourcePathtoUse = $TransferLocation.TrimEnd('\')+('\*')
    if (Test-Path ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')){
        Remove-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')
    }
    $null = Copy-Item ($TempFolder+'NewFolder.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')
    if (-not(Start-HSTImager -Command 'fs copy' -SourcePath $SourcePathtoUse -DestinationPath ($HDFImageLocation +$NameofImage+'\rdb\'+$DeviceName_Other+'\'+$MigratedFilesFolder) -HSTImagePathtouse $HSTImagePath -TempFoldertouse $TempFolder)){
        exit
    }
    Write-TaskCompleteMessage -Message 'Transferring Migrated Files to Work Partition - Complete!'
}

if ($Script:SetDiskupOnly -eq 'FALSE'){

    Write-StartTaskMessage -Message 'Transferring Amiga Files to Image'
    
    Write-StartSubTaskMessage -SubtaskNumber 1 -TotalSubtasks 2 -Message 'Transferring files to Workbench Partition'

    if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_System) -DestinationPath ($HDFImageLocation +$NameofImage+'\rdb\'+$DeviceName_System) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    } 

    Write-StartSubTaskMessage -SubtaskNumber 2 -TotalSubtasks 2 -Message 'Transferring files to Work Partition'

    if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_Other) -DestinationPath ($HDFImageLocation +$NameofImage+'\rdb\'+$DeviceName_Other) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    }  
    
    Write-TaskCompleteMessage -Message 'Transferring Amiga Files to Image - Complete!'
}

If ($Script:ImageOnly -eq 'TRUE'){
    Write-StartTaskMessage -Message 'Creating Image'
    
    Set-Location $Script:LocationofImage
    
    #Update-OutputWindow -OutputConsole_Title_Text 'Creating Image' -ProgressbarValue_Overall 83 -ProgressbarValue_Overall_Text '83%'
    
    & $HDF2emu68Path ($HDFImageLocation +$NameofImage) $Script:SizeofFAT32_hdf2emu68 ($FAT32Partition).Trim('\')
    $null= rename-Item ($Script:LocationofImage+'emu68_converted.img') -NewName ('Emu68Workbench'+$Script:KickstartVersiontoUse+'.img')
    
    Write-TaskCompleteMessage -Message ('Creating Image - Complete! Your image can be found at the following location: '+$Script:LocationofImage+('Emu68Workbench'+$Script:KickstartVersiontoUse+'.img')) 

}

If ($Script:ImageOnly -eq 'FALSE'){
    Write-StartTaskMessage -Message 'Writing Image to Disk'
    
    Set-location  $Script:WorkingPath
    
    # TBC - to use to round partition sizes so they always equal a whole number of sectors. Current code works to a maximum of 1048. If always 512 then can be removed and rely on ddtc calculations
    $SectorSize = (Get-WmiObject -Class Win32_DiskPartition | Select-Object -Property DiskIndex, Name, Index, BlockSize, Description, BootPartition | Where-Object DiskIndex -eq $Script:HSTDiskNumber | where-object Index -eq 0).BlockSize
    $Offset = (Get-WmiObject -Class Win32_DiskPartition | Select-Object -Property DiskIndex, Name, Index, BlockSize, Description, StartingOffset,BootPartition | Where-Object DiskIndex -eq $Script:HSTDiskNumber | where-object Index -eq 1).StartingOffset/$SectorSize
    
    if ($SectorSize -eq 0 -or $SectorSize -eq ""){
        Write-ErrorMessage 'Incorrect sector size!'
        exit
    } 

    Write-InformationMessage ('Offset being used is: '+$Offset+' Sector size is: '+$SectorSize)
    if ($SectorSize -ne $Script:AmigaBlockSize){
        Write-InformationMessage -Message 'The sector size of your SD card ('+$SectorSize+') does not match the Amiga Blocksize ('+$Script:AmigaBlockSize+'). Using standard write method.'
        $Script:WriteMethod = 'Normal'
    }

    if ($Script:WriteMethod -eq 'Normal'){
        & $Script:DDTCPath ($HDFImageLocation +$NameofImage) $Script:HSTDiskDeviceID -offset $Offset -sectorsize $SectorSize
    }
    elseif ($Script:WriteMethod -eq 'SkipEmptySpace'){
        $RDBStartBlock = ($AmigaPartitionsList | Where-Object {$_.PartitionNumber -eq 0} | Select-Object 'StartSector').StartSector
#        $RDBEndBlock = ($AmigaPartitionsList | Where-Object {$_.PartitionNumber -eq 0} | Select-Object 'EndSector').EndSector
#        $SystemStartBlock = ($AmigaPartitionsList | Where-Object {$_.PartitionNumber -eq 1} | Select-Object 'StartSector').StartSector
        $SystemEndBlock = ($AmigaPartitionsList | Where-Object {$_.PartitionNumber -eq 1} | Select-Object 'EndSector').EndSector
        $WorkStartBlock = ($AmigaPartitionsList | Where-Object {$_.PartitionNumber -eq 2} | Select-Object 'StartSector').StartSector
        $WorkEndBlock = ($AmigaPartitionsList | Where-Object {$_.PartitionNumber -eq 2} | Select-Object 'EndSector').EndSector
        
        Write-StartSubTaskMessage -SubtaskNumber 1 -TotalSubtasks 3 -Message 'Determing Free Space locations in partitions'

        Write-InformationMessage -Message 'Determining start of free space - Workbench Partition (this may take some time)'
        & $Script:FindFreeSpacePath ($HDFImageLocation +$NameofImage) -sectorsize $SectorSize .\InputFiles-begincrop $RDBStartBlock -endcrop $SystemEndBlock -result ($TempFolder+'FindFreeSpaceLog.txt')
        $EmptySpaceStartBlock_System = ([decimal](Get-Content -Path ($TempFolder+'FindFreeSpaceLog.txt')))+$RDBStartBlock 
        Write-InformationMessage -Message ('FreeSpace found at: '+$EmptySpaceStartBlock_System+' (from start of .hdf file)')
        Write-InformationMessage -Message 'Determining start of free space - Workbench - Completed'              
    
        Write-InformationMessage -Message 'Determining start of free space - Work Partition (this may take some time)'
        & $Script:FindFreeSpacePath ($HDFImageLocation +$NameofImage) -sectorsize $SectorSize -begincrop $WorkStartBlock -endcrop $WorkEndBlock -result ($TempFolder+'FindFreeSpaceLog.txt')
        $EmptySpaceStartBlock_Work = ([decimal](Get-Content -Path ($TempFolder+'FindFreeSpaceLog.txt')))+$WorkStartBlock
        Write-InformationMessage -Message ('FreeSpace found at: '+$EmptySpaceStartBlock_Work+' (from start of .hdf file)')
        Write-InformationMessage -Message 'Determining start of free space - Work Partition - Completed'
        
        Write-StartSubTaskMessage -SubtaskNumber 2 -TotalSubtasks 3 -Message 'Writing .hdf to disk'
        
        Write-InformationMessage -Message ('Writing Workbench to Disk. Begin Crop is: ' + $RDBStartBlock + ' End Crop is: ' + $EmptySpaceStartBlock_System) 
        & $Script:DDTCPath ($HDFImageLocation +$NameofImage) $Script:HSTDiskDeviceID -offset $Offset -sectorsize $SectorSize -begincrop $RDBStartBlock -endcrop $EmptySpaceStartBlock_System
        Write-InformationMessage -Message ('Writing Work to Disk. Begin Crop is: ' + $WorkStartBlock + ' End Crop is: ' + $EmptySpaceStartBlock_Work) 
        & $Script:DDTCPath ($HDFImageLocation +$NameofImage) $Script:HSTDiskDeviceID -offset $Offset -sectorsize $SectorSize -begincrop $WorkStartBlock -endcrop $EmptySpaceStartBlock_Work    
        
        # Write blank space over reserved PFS space for unformatted Work partitions

        $AdditionalWorkPartitions = $AmigaPartitionsList | Where-Object {$_.PartitionNumber -gt 2}

        if ($AdditionalWorkPartitions){
            Write-StartSubTaskMessage -SubtaskNumber 3 -TotalSubtasks 3 -Message 'Writing blank space over PFS reserved space for any additional Work partitions'
            foreach ($AdditionalPartition in $AdditionalWorkPartitions){
                $StartBlock = [int]$AdditionalPartition.StartSector
                $SectorstoWrite = (10*1024*1024)/$Script:AmigaBlockSize # Write 10meg of blank space
                $EndBlock = $StartBlock + $SectorstoWrite
                Write-InformationMessage -Message ('Writing Empty Space to extra Work partition #'+($AdditionalPartition.PartitionNumber-2)+' (device '+$AdditionalPartition.DeviceName+') for Startblock: '+$StartBlock+' Endblock: '+$EndBlock)
                & $Script:DDTCPath ($HDFImageLocation +$NameofImage) $Script:HSTDiskDeviceID -offset $Offset -sectorsize $SectorSize -begincrop $StartBlock -endcrop $EndBlock 
            }
        }
    }

    Write-TaskCompleteMessage -Message 'Writing Image to Disk - Complete!'
}

if ($Script:DeleteAllWorkingPathFiles -eq 'TRUE'){
    if ($Script:ImageOnly -eq 'TRUE'){
        Write-StartTaskMessage -Message 'Deleting ALL Working Folder files (excluding .img file)'
    }
    else {
        Write-StartTaskMessage -Message 'Deleting ALL Working Folder files - Complete!'
    }

    Set-Location $Script:Scriptpath

    Remove-WorkingFolderData -AtEnd 'TRUE'

    if ($Script:ImageOnly -eq 'TRUE'){
        Write-TaskCompleteMessage -Message 'Deleting ALL Working Folder files (excluding .img file) - Complete!'
    }
    else{
        Write-TaskCompleteMessage -Message 'Deleting ALL Working Folder files - Complete!'
    }
}

Set-Location $Script:Scriptpath

$EndDateandTime = (Get-Date -Format HH:mm:ss)
$ElapsedTime = (New-TimeSpan -Start $StartDateandTime -End $EndDateandTime).TotalSeconds

Write-InformationMessage -message "Started at: $StartDateandTime Finished at: $EndDateandTime. Total time to run (in seconds) was: $ElapsedTime" 
Write-InformationMessage -message 'The tool has finished runnning. A log file was created and has been stored in the log subfolder.' 
Write-InformationMessage -message ('The full path to the file is: '+$Script:LogLocation)

$Msg_Header = 'Tool Completed'
$Msg_Body = @"

The tool has now completed! You can now close the terminal window.

"@

$null = [System.Windows.MessageBox]::Show($Msg_Body, $Msg_Header,0,0)
exit