##### Script

$UnLZXURL='http://aminet.net/util/arc/W95unlzx.lha'

$HSTImagerreleases= 'https://api.github.com/repos/henrikstengaard/hst-imager/releases'
$HSTAmigareleases= 'https://api.github.com/repos/henrikstengaard/hst-amiga/releases'
$Emu68releases= 'https://api.github.com/repos/michalsc/Emu68/releases'
$Emu68Toolsreleases= 'https://api.github.com/repos/michalsc/Emu68-tools/releases'

if ($env:TERM_PROGRAM){
   Write-Host "Run from Visual Studio Code!"
   $InteractiveMode=0
} 
elseif ($psISE){
   Write-Host "Run from Powershell ISE!"
   $InteractiveMode=0
}
else{
   $InteractiveMode=1
} 

If ($InteractiveMode -eq 1){
    Read-host 'Pistorm Imager. Please press enter to start'
}

if  ($InteractiveMode -eq 1){
    $Scriptpath = (Split-Path -Parent $MyInvocation.MyCommand.Definition)+'\'
} 

if  ($InteractiveMode -eq 0){
    $Scriptpath = 'C:\Users\Matt\OneDrive\Documents\Emu68Imager\'
    $WorkingFolder = 'D:\Test of Weird Path\'
    $SizeofImage='350'
    $SizeofPartition_System='100'
    $SizeofPartition_Other='100'
    $SizeofFAT32 ='135'
    $ROMPath = 'D:\Emulators\Amiga Files\Shared\rom\'
    $ADFPath = 'D:\Emulators\Amiga Files\Shared\adf\'
    $ScreenMode='1920*1080-60'
    $TransferLocation='D:\Emulators\Amiga Files\Shared\adf\OS32\Update\'
}

## Import Functions

Import-Module ($Scriptpath+'Functions.psm1')

if (Get-Check -NumberofIterations 5 -File ($Scriptpath+'check.dat')){
    throw
}

$SourceProgramPath=($Scriptpath+'Programs\')
$InputFolder=($Scriptpath+'InputFiles\')
$LocationofAmigaFiles=($Scriptpath+'AmigaFiles\')

#Generate CSV MD5 Hashes - Begin (To be disabled or removed for production version)
$CSVHashes = Get-FileHash ($InputFolder+'*.CSV') -Algorithm MD5

'Name;Hash' | Out-File -FilePath ($InputFolder+'CSVHASH')
Foreach ($CSVHash in $CSVHashes){
    ((Split-Path $CSVHash.Path -Leaf)+';'+$CSVHash.Hash) | Out-File -FilePath ($InputFolder+'CSVHASH') -Append
}

#Generate CSV MD5 Hashes - End

# Check Integrity of CSVs
Write-Host ''
Write-Host 'Performing integrity checks over input files'
Write-Host ''
$CSVHashestoCheck = Import-Csv -Path ($InputFolder+'CSVHASH') -Delimiter ';'
foreach ($CSVHashtoCheck in $CSVHashestoCheck){
    Write-Host ('Checking integrity of: '+$CSVHashtoCheck.Name)
    foreach ($CSVHash in $CSVHashes){
        if (($CSVHashtoCheck.Name+$CSVHashtoCheck.Hash) -eq ((split-path $CSVHash.Path -leaf)+($CSVHash.Hash))){
            $HashMatch=$true
        }
    }
    if ($HashMatch -eq $false) {
        Write-Host 'ERROR! One or more of input files is missing and/or has been altered!' -ForegroundColor Red
        throw
    }
    else{
        Write-Host 'File OK!'
    }
}
Write-Host 'Integrity checks complete!'
Write-Host ''

Write-host 'Checking existance of folders, programs, and files'
Write-Host ''
$ErrorCount = 0

$ErrorCount+= Test-ExistenceofFiles -PathtoTest $SourceProgramPath -PathType 'Folder'
$ErrorCount+= Test-ExistenceofFiles -PathtoTest $LocationofAmigaFiles -PathType 'Folder'
$ErrorCount+= Test-ExistenceofFiles -PathtoTest ($SourceProgramPath+'hdf2emu68.exe') -PathType 'File'
$ErrorCount+= Test-ExistenceofFiles -PathtoTest ($SourceProgramPath+'7z.exe') -PathType 'File'
$ErrorCount+= Test-ExistenceofFiles -PathtoTest ($SourceProgramPath+'7z.dll') -PathType 'File'

$ListofPackagestoInstall = Import-Csv ($InputFolder+'ListofPackagestoInstall.csv') -Delimiter ';' | Where-Object {$_.Source -eq 'Local'} | Where-Object {$_.InstallType -ne 'StartupSequenceOnly'} |Where-Object {$_.InstallFlag -eq 'TRUE'}
$ListofPackagestoInstall |  Select-Object SourceLocation -Unique | Where-Object SourceLocation -NotMatch 'Onetime' | ForEach-Object {
    $ErrorCount+= Test-ExistenceofFiles -PathtoTest ($LocationofAmigaFiles+$_.SourceLocation) -PathType 'File'
}

if ($ErrorCount -ge 1){
    throw
}
else {
    $null = $ErrorCount
    Write-Host 'All folders and files exist!'
}

$HDF2emu68Path=($SourceProgramPath+'hdf2emu68.exe')
$7zipPath=($SourceProgramPath+'7z.exe')

if ($InteractiveMode -eq 1){
    $WorkingFolder =  Get-FolderPath -Description 'Please enter the location of the Working Folder. You can create a new folder if you wish. Required sub-folders will be created if the the working folder does not contain them' -ShowNewFolderButton $true -RootFolder 'MyComputer'
    if (!$WorkingFolder){
        Write-Host 'Nothing selected. You are a Stronzo!' -ForegroundColor Red
        throw
    }
}

Set-Location $WorkingFolder

$ProgramsFolder=$WorkingFolder+'Programs\'
if (-not (Test-Path $ProgramsFolder)){
    $null = New-Item $ProgramsFolder -ItemType Directory
}

$TempFolder=$WorkingFolder+'Temp\'
if (-not (Test-Path $TempFolder)){
    $null = New-Item $TempFolder -ItemType Directory
}

$HSTImagePath=$ProgramsFolder+'HST-Imager\hst.imager.exe'
$HSTAmigaPath=$ProgramsFolder+'HST-Amiga\hst.amiga.exe'
$LZXPath=$ProgramsFolder+'unlzx.exe'

$LocationofImage=$WorkingFolder+'OutputImage\'
$AmigaDrivetoCopy=$WorkingFolder+'AmigaImageFiles\'
$AmigaDownloads=$WorkingFolder+'AmigaDownloads\'
$FAT32Partition=$WorkingFolder+'FAT32Partition\'

## Amiga Variables

$DeviceName_System ='SDH0'
$VolumeName_System ='Workbench'
$DeviceName_Other = 'SDH1'
$VolumeName_Other = 'Work'
#$InstallPathMUI='SYS:Programs/MUI'
#$InstallPathPicasso96='SYS:Programs/Picasso96'
#$InstallPathAmiSSL='SYS:Programs/AmiSSL'
$GlowIcons='TRUE'

If ($InteractiveMode -eq 1){
    $SizeofImage = Read-Host "Please enter the size of image (in Megabytes)"
}


$SizeofImage = $SizeofImage+'mb'

If ($InteractiveMode -eq 1){
    $SizeofPartition_System = Read-Host "Please enter the size of Workbench partition (in Megabytes)"
}


$SizeofPartition_System = $SizeofPartition_System+'mb'

If ($InteractiveMode -eq 1){
    $SizeofPartition_Other = Read-Host "Please enter the size of Work partition (in Megabytes)"
}


$SizeofPartition_Other = $SizeofPartition_Other+'mb'

If ($InteractiveMode -eq 1){
$SizeofFAT32 = Read-Host "Please enter the size of FAT32 (in Megabytes)"
}


$KickstartVersiontoUse = Read-Host "Please choose either Kickstart 3.2 or 3.1 (3.1, 3.2)"

$NameofImage=('Pistorm'+$KickstartVersiontoUse+'.HDF')

If ($InteractiveMode -eq 1){
    $TransferLocation =  Get-FolderPath -Description 'Please enter location of files to transfer. If you do not want to transfer anything, press cancel.' -ShowNewFolderButton $false -RootFolder 'MyComputer'
}

If ($InteractiveMode -eq 1){
    $SSID = Read-Host "Please enter your Wireless SSID"
    $WifiPassword= Read-Host "Please enter your wifi password" -MaskInput
}

If ($InteractiveMode -eq 1){
    $ROMPath =  Get-FolderPath -Description 'Please enter the folder location of the Amiga Kickstart Rom' -ShowNewFolderButton $false -RootFolder 'MyComputer'
    if (!$ROMPath){
        Write-Host 'Nothing selected. You are a Stronzo!' -ForegroundColor Red
        throw
    }
}

If ($InteractiveMode -eq 1){
    $ADFPath =  Get-FolderPath -Description 'Please enter the folder location of the Amiga Workbench ADF files' -ShowNewFolderButton $false -RootFolder 'MyComputer'
    if (!$ADFPath){
        Write-Host 'Nothing selected. You are a Stronzo!' -ForegroundColor Red
        throw
    }
}

If ($InteractiveMode -eq 1){
    $ScreenMode = Read-Host "Please enter the screenmode"
}


$StartDateandTime = (Get-Date -Format HH:mm:ss)

Write-Host "Starting execution at $StartDateandTime"

### Clean up

$NewFolders = ((split-path $TempFolder -leaf),(split-path $LocationofImage -leaf),((Split-Path $AmigaDrivetoCopy -Leaf)+'\'+$VolumeName_System),((Split-Path $AmigaDrivetoCopy -Leaf)+'\'+$VolumeName_Other),(split-path $FAT32Partition -leaf))

try {
    foreach ($NewFolder in $NewFolders) {
        if (Test-Path ($WorkingFolder+$NewFolder)){
            $null = Remove-Item ($WorkingFolder+$NewFolder) -Recurse -ErrorAction Stop
        }
        $null = New-Item -path ($WorkingFolder) -Name $NewFolder -ItemType Directory
    }    
}
catch {
    throw "Cannot delete temporary files!"    
}

if (-not(Test-Path ($WorkingFolder+'AmigaDownloads'))){
    $null = New-Item -path ($WorkingFolder) -Name 'AmigaDownloads' -ItemType Directory    
}

if (-not(Test-Path ($WorkingFolder+'Programs'))){
    $null = New-Item -path ($WorkingFolder) -Name 'Programs' -ItemType Directory      
}

### End Clean up

### Determine Kickstart Rom Path

$FoundKickstarttoUse = Compare-KickstartHashes -PathtoKickstartHashes ($InputFolder+'RomHashes.csv') -PathtoKickstartFiles $ROMPath -KickstartVersion $KickstartVersiontoUse

$KickstartPath = $FoundKickstarttoUse.KickstartPath

if (-not($KickstartPath)){
    throw "Error! No Kickstart file found!"
} 

$KickstartNameFAT32=$FoundKickstarttoUse.Fat32Name

Write-Host ('Kickstart to be used is: '+$KickstartPath)

$AvailableADFs = Compare-ADFHashes -PathtoADFFiles $ADFPath -PathtoADFHashes ($InputFolder+'ADFHashes.csv') -KickstartVersion $KickstartVersiontoUse -PathtoListofInstallFiles ($InputFolder+'ListofInstallFiles.csv') 

if (-not ($AvailableADFs)){
    throw "One or more ADF files is missing!"
} 

$ListofInstallFiles = Import-Csv ($InputFolder+'ListofInstallFiles.csv') -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersiontoUse} | Sort-Object -Property 'InstallSequence'

$ListofInstallFiles | Add-Member -NotePropertyName Path -NotePropertyValue $null
$ListofInstallFiles | Add-Member -NotePropertyName DrivetoInstall_VolumeName -NotePropertyValue $null

foreach ($InstallFileLine in $ListofInstallFiles) {
    if ($InstallFileLine.DrivetoInstall -eq 'System'){
        $InstallFileLine.DrivetoInstall_VolumeName = $VolumeName_System
    }
    foreach ($MatchedADF in $AvailableADFs ) {
        if ($InstallFileLine.ADF_Name -eq $MatchedADF.ADF_Name){
            $InstallFileLine.Path=$MatchedADF.PathtoADF
        }
        if ($MatchedADF.ADF_Name -match "GlowIcons"){
            $GlowIconsADF=$MatchedADF.PathtoADF
        }
        if ($MatchedADF.ADF_Name -match "Storage"){
            $StorageADF=$MatchedADF.PathtoADF
        }
        if ($MatchedADF.ADF_Name -match "Install"){
            $InstallADF=$MatchedADF.PathtoADF
        }
    }    
}

Write-Host 'ADF install images to be used are:'
$ListofInstallFiles |  Select-Object Path,FriendlyName -Unique | ForEach-Object {
    Write-host ($_.FriendlyName+' ('+$_.Path+')')
} 

### Download HST-Imager and HST-Amiga

Write-Host "Downloading HST Imager"
if (-not(Get-GithubRelease -GithubRelease $HSTImagerreleases -Tag_Name '1.1.350' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTImager.zip') -LocationforProgram ($ProgramsFolder+'HST-Imager\') -Sort_Flag '')){
    Write-Host 'Error downloading HST-Imager! Cannot continue!'
    throw
}

Write-Host "Downloading HST Amiga"
if (-not(Get-GithubRelease -GithubRelease $HSTAmigareleases -Tag_Name '0.3.163' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTAmiga.zip') -LocationforProgram ($ProgramsFolder+'HST-Amiga\') -Sort_Flag '')){
    Write-Host 'Error downloading HST-Amiga! Cannot continue!'
    throw
}

#### Download Emu68 Files


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

Write-Host "Downloading Emu68Pistorm"
if (-not(Get-GithubRelease -GithubRelease $Emu68releases -Tag_Name "nightly" -Name 'Emu68-pistorm-' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm\') -Sort_Flag 'SORT')){
    Write-Host 'Error downloading Emu68Pistorm! Cannot continue!' -ForegroundColor Red
    throw
}

Write-Host "Downloading Emu68Pistorm32lite"
if (-not(Get-GithubRelease -GithubRelease $Emu68releases -Tag_Name "nightly" -Name 'Emu68-pistorm32lite' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm32lite.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm32lite\') -Sort_Flag 'SORT')){
    Write-Host 'Error downloading Emu68Pistorm32lite! Cannot continue!' -ForegroundColor Red
    throw
}

Write-Host "Downloading Emu68Tools"
if (-not(Get-GithubRelease -GithubRelease $Emu68Toolsreleases -Tag_Name "nightly" -Name 'Emu68-tools' -LocationforDownload ($AmigaDownloads+'Emu68Tools.zip') -LocationforProgram ($tempfolder+'Emu68Tools\') -Sort_Flag 'SORT')){
    Write-Host 'Error downloading Emu68Tools! Cannot continue!' -ForegroundColor Red
    throw
}

### End Download HST

### Begin Download UnLzx

Write-Host "Downloading UnLZX"
if (-not (Test-Path ($ProgramsFolder+'unlzx.exe'))){
    If (-not (Get-AmigaFileWeb -URL $UnLZXURL -NameofDL 'W95unlzx.lha' -LocationforDL $TempFolder)){
        Write-host "Error downloading UnLZX! Quitting" -ForegroundColor Red
        throw
    }
    if (-not(Expand-Zipfiles -SevenzipPathtouse $7zipPath -TempFoldertouse $TempFolder -InputFile ($TempFolder+'W95unlzx.lha') -OutputDirectory $ProgramsFolder -FiletoExtract 'unlzx.exe')){
        Write-Host ('Deleting package '+($TempFolder+'W95unlzx.lha'))
        $null=Remove-Item -Path ($TempFolder+'W95unlzx.lha') -Force
        throw # Error in extracting
    }
}
else{
    Write-Host "Unlzx already exists."
}

### End Download UnLzx

Write-Host "Preparing Amiga Image"
if (-not (Start-HSTImager -Command "Blank" -DestinationPath ($LocationofImage+$NameofImage) -ImageSize $SizeofImage -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not (Start-HSTImager -Command "rdb init" -DestinationPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not (Start-HSTImager -Command "rdb filesystem add" -DestinationPath ($LocationofImage+$NameofImage) -FileSystemPath ($WorkingFolder+'Programs\HST-Imager\pfs3aio') -DosType 'PFS3' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not (Start-HSTImager -Command "rdb part add" -DestinationPath ($LocationofImage+$NameofImage) -DeviceName $DeviceName_System -DosType 'PFS3' -SizeofPartition $SizeofPartition_System -Options '--bootable' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not (Start-HSTImager -Command "rdb part add" -DestinationPath ($LocationofImage+$NameofImage) -DeviceName $DeviceName_Other -DosType 'PFS3' -SizeofPartition $SizeofPartition_Other -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not (Start-HSTImager -Command "rdb part format" -DestinationPath ($LocationofImage+$NameofImage) -PartitionNumber "1" -VolumeName $VolumeName_System -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not (Start-HSTImager -Command "rdb part format" -DestinationPath ($LocationofImage+$NameofImage) -PartitionNumber "2" -VolumeName $VolumeName_Other -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
#### Begin - Create NewFolder.info file
if (($KickstartVersiontoUse -eq 3.1) -or (($KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'FALSE'))) {
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\Monitors.info') -DestinationPath ($TempFolder.TrimEnd('\'))  -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        throw
    }
    if (Test-Path ($TempFolder+'def_drawer.info')){
        $null = Remove-Item ($TempFolder+'def_drawer.info')
    }
    $null = Rename-Item ($TempFolder+'Monitors.info') ($TempFolder+'def_drawer.info')
}
elseif(($KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'TRUE')){
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($GlowIconsADF+'\Prefs\Env-Archive\Sys\def_drawer.info') -DestinationPath ($TempFolder.TrimEnd('\')) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        throw
    }
}

if (Test-Path ($TempFolder+'NewFolder.info')){
    $null = Remove-Item ($TempFolder+'NewFolder.info')
} 
$null = Rename-Item ($TempFolder+'def_drawer.info') ($TempFolder+'NewFolder.info') -Force

#### End - Create NewFolder.info file

### Begin Basic Drive Setup
Add-AmigaFolder -AmigaFolderPath ($VolumeName_System+'\Programs\') -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
Add-AmigaFolder -AmigaFolderPath ($VolumeName_System+'\Storage\DataTypes\') -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy

if (-not (Test-Path ($AmigaDrivetoCopy+$VolumeName_Other))){
    $null = New-Item -path ($AmigaDrivetoCopy+$VolumeName_Other) -ItemType Directory -Force 
    
}

if ($KickstartVersiontoUse -eq 3.1){
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($InstallADF+'\Update\disk.info') -DestinationPath ($AmigaDrivetoCopy+$VolumeName_Other) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            throw
        }
}
elseif ($KickstartVersiontoUse -eq 3.2){
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($GlowIconsADF+'\Prefs\Env-Archive\Sys\def_harddisk.info') -DestinationPath ($AmigaDrivetoCopy+$VolumeName_Other) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            throw
        }
    Rename-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\def_harddisk.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info') 
}

### End Basic Drive Setup

### Begin Copy Install files from ADF

$TotalItems=$ListofInstallFiles.Count

$ItemCounter=1

Foreach($InstallFileLine in $ListofInstallFiles){
    Write-Host ''
    Write-Host ('('+$ItemCounter+'/'+$TotalItems+') Processing ADF:'+$InstallFileLine.FriendlyName+' Files: '+$InstallFileLine.AmigaFiletoInstall)
    $SourcePathtoUse = ($InstallFileLine.Path+'\'+($InstallFileLine.AmigaFiletoInstall -replace '/','\'))
    if ($InstallFileLine.Uncompress -eq "TRUE"){
        Write-host 'Extracting files from ADFs containing .Z files'
        if ($InstallFileLine.LocationtoInstall.Length -eq 0){        
            $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName)
        }
        else{  
            $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+($InstallFileLine.LocationtoInstall -replace '/','\')) 
        }
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            throw
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
        Write-host 'Extracting files from ADFs where changes needed'
        if ($InstallFileLine.LocationtoInstall.Length -eq 0){
            $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName)
        }
        else{        
            $DestinationPathtoUse = ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+($InstallFileLine.LocationtoInstall -replace '/','\'))
        }
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            throw
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
                throw
            }                 
            $OldToolTypes = Get-Content($TempFolder+$filename+'.txt')
            $TooltypestoModify = Import-Csv ($LocationofAmigaFiles+$LocationtoInstall+'\'+$filename+'.txt') -Delimiter ';'
            Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $TooltypestoModify | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
            if (-not (Write-AmigaTooltypes -IconPath ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$filename) -ToolTypesPath ($TempFolder+$fileName+'amendedtoimport.txt') -TempFoldertouse $TempFoldertouse -HSTAmigaPathtouse $HSTAmigaPath)){
                throw
            }                 
        }        
        if ($InstallFileLine.ModifyScript -eq'Remove'){
            Write-Host ('Modifying '+$FileName+' for: '+$InstallFileLine.ScriptNameofChange)
            $ScripttoEdit = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$FileName)
            $ScripttoEdit = Edit-AmigaScripts -ScripttoEdit $ScripttoEdit -Action 'remove' -name $InstallFileLine.ScriptNameofChange -Startpoint $InstallFileLine.ScriptInjectionStartPoint -Endpoint $InstallFileLine.ScriptInjectionEndPoint                    
            Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall_VolumeName+'\'+$LocationtoInstall+$FileName) -DatatoExport $ScripttoEdit -AddLineFeeds 'TRUE'
        }   
    }
    else {
        Write-host 'Extracting files from ADFs to .hdf file'
        if ($InstallFileLine.LocationtoInstall.Length -eq 0){
           $DestinationPathtoUse = ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System)
        }
        else{
           $DestinationPathtoUse = ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System+'\'+($InstallFileLine.LocationtoInstall -replace '/','\'))
        }
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            throw
        }
    }     
    $ItemCounter+=1    
}

### End Copy Install files from ADF

#######################################################################################################################################################################################################################################

$ListofPackagestoInstall = Import-Csv ($InputFolder+'ListofPackagestoInstall.csv') -Delimiter ';' |  Where-Object {$_.KickstartVersion -match $KickstartVersiontoUse} | Where-Object {$_.InstallFlag -eq 'TRUE'} #| Sort-Object -Property 'InstallSequence','PackageName'

$ListofPackagestoInstall | Add-Member -NotePropertyName DrivetoInstall_VolumeName -NotePropertyValue $null

foreach ($line in $ListofPackagestoInstall){
    if ($line.DrivetoInstall -eq 'System'){
        $line.DrivetoInstall_VolumeName = $VolumeName_System
    }
}


$PackageCheck=$null

# Download and expand packages

$TotalItems=(
    $ListofPackagestoInstall | Where-Object InstallType -ne 'CopyOnly' |  Where-Object InstallType -ne 'StartupSequenceOnly' | Select-Object -Unique -Property PackageName
    ).count 

$ItemCounter=1

foreach($PackagetoFind in $ListofPackagestoInstall) {
    if (($PackagetoFind.InstallType -ne 'CopyOnly') -and ($PackagetoFind.InstallType -ne 'StartupSequenceOnly')){
        if ($PackageCheck -ne $PackagetoFind.PackageName){
            Write-Host ''
            Write-host ('('+$ItemCounter+'/'+$TotalItems+') Downloading (or Copying) package '+$PackagetoFind.PackageName)
            if ($PackagetoFind.Source -eq "ADF") {
                if ($PackagetoFind.SourceLocation -eq 'StorageADF'){
                    $ADFtoUse = $StorageADF
                    $SourcePathtoUse = ($ADFtoUse+'\'+$PackagetoFind.FilestoInstall)
                    $DestinationPathtoUse = ($TempFolder+$PackagetoFind.FileDownloadName).Trim('\')       
                    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePathtoUse -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                        throw
                    }
                }
            }
            Elseif ($PackagetoFind.Source -eq "Web"){
                if(($PackagetoFind.SearchforUpdatedPackage -eq 'TRUE') -and ($PackagetoFind.PackageName -ne 'WHDLoadWrapper')){
                    $PackagetoFind.SourceLocation=Find-LatestAminetPackage -PackagetoFind $PackagetoFind.PackageName -Exclusion $PackagetoFind.UpdatePackageSearchExclusionTerm -DateNewerthan $PackagetoFind.UpdatePackageSearchMinimumDate -Architecture 'm68k-amigaos'
                   # Write-Host $PackagetoFind.SourceLocation           
                }
                if(($PackagetoFind.SearchforUpdatedPackage -eq 'TRUE') -and ($PackagetoFind.PackageName -eq 'WHDLoadWrapper')){
                    $PackagetoFind.SourceLocation=(Find-WHDLoadWrapperURL -SearchCriteria 'WHDLoadWrapper' -ResultLimit '10') 
                }
                if (Test-Path ($AmigaDownloads+$PackagetoFind.FileDownloadName)){
                    Write-Host "Download already completed"
                } 
                else{
                    if (-not (Get-AmigaFileWeb -URL $PackagetoFind.SourceLocation -NameofDL $PackagetoFind.FileDownloadName -LocationforDL $AmigaDownloads)){
                        Write-host "Unrecoverable error with download(s)!" -ForegroundColor Red
                        throw
                    }                    
                }
                if ($PackagetoFind.PerformHashCheck -eq 'TRUE'){
                    if (-not (Compare-FileHash -FiletoCheck ($AmigaDownloads+$PackagetoFind.FileDownloadName) -HashtoCheck $PackagetoFind.Hash)){
                        Write-Host "Error in downloaded packages! Unable to continue!" -ForegroundColor Red
                        Write-Host ('Deleting package '+($AmigaDownloads+$PackagetoFind.FileDownloadName))
                        $null=Remove-Item -Path ($AmigaDownloads+$PackagetoFind.FileDownloadName) -Force 
                        throw
                    }
                }
            }
            Elseif (($PackagetoFind.Source -eq "Local") -and ($PackagetoFind.InstallType -eq "Full")){
                Write-host "Copying local file"$PackagetoFind.SourceLocation
                if (Test-Path ($AmigaDownloads+$PackagetoFind.FileDownloadName)){
                    Write-host 'File already copied'
                }
                else {
                    Copy-Item ($LocationofAmigaFiles+$PackagetoFind.SourceLocation) ($AmigaDownloads+$PackagetoFind.FileDownloadName)
                }
            }
            if ($PackagetoFind.InstallType -eq "Full"){
                Write-Host 'Expanding archive file for package'$PackagetoFind.PackageName
                if ([System.IO.Path]::GetExtension($PackagetoFind.FileDownloadName) -eq '.lzx'){
                    Expand-LZXArchive -LZXPathtouse $LZXPath -WorkingFoldertouse $WorkingFolder -LZXFile ($AmigaDownloads+$PackagetoFind.FileDownloadName) -TempFoldertouse $TempFolder -DestinationPath ($TempFolder+$PackagetoFind.FileDownloadName) 
                } 
                if ([System.IO.Path]::GetExtension($PackagetoFind.FileDownloadName) -eq '.lha'){
                    if (-not(Expand-Zipfiles -SevenzipPathtouse $7zipPath -TempFoldertouse $TempFolder -InputFile ($AmigaDownloads+$PackagetoFind.FileDownloadName) -OutputDirectory ($TempFolder+$PackagetoFind.FileDownloadName))){
                        Write-Host ('Deleting package '+($AmigaDownloads+$PackagetoFind.FileDownloadName))
                        $null=Remove-Item -Path ($AmigaDownloads+$PackagetoFind.FileDownloadName) -Force
                        throw # Error in extracting
                    }
                               
                } 
            }

            $ItemCounter+=1    
        }
        $PackageCheck=$PackagetoFind.PackageName
            
    }
}

$PackageCheck=$null
$UserStartup=$null
$StartupSequence = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+'System\S\Startup-Sequence') 
$StartupSequenceversion = Get-StartupSequenceVersion -StartupSequencetoCheck $StartupSequence

$TotalItems=(
    $ListofPackagestoInstall | Select-Object -Unique -Property PackageName
    ).count 

$ItemCounter=1

foreach($PackagetoFind in $ListofPackagestoInstall) {
    if ($PackageCheck -ne $PackagetoFind.PackageName){
        Write-host ''
        Write-host ('('+$ItemCounter+'/'+$TotalItems+') Installing package '+$PackagetoFind.PackageName)       
        if ($PackagetoFind.ModifyUserStartup -eq'TRUE'){
            Write-Host 'Modifying S/User-Startup file for:'$PackagetoFind.PackageName
            $UserStartup += Edit-AmigaScripts -name $PackagetoFind.PackageName -Action 'Append' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'S\User-Startup_'+$PackagetoFind.PackageName))
            
        }
        if ($PackagetoFind.ModifyStartupSequence -eq'Add'){
            Write-Host 'Modifying S/Startup-Sequence file for:'$PackagetoFind.PackageName 
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
           Write-Host "Creating directories where required - Folder"$PackagetoFind.LocationtoInstall
           if (-not (Test-Path ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall))){
               $null = New-Item ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall) -ItemType Directory
           }
           if ($PackagetoFind.CreateFolderInfoFile -eq 'TRUE'){
               Add-AmigaFolder -AmigaFolderPath ($PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall) -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
           }
           #### Copy Files
           if ($PackagetoFind.NewFileName.Length -ne 0){
               $DestinationPathtoUse=$DestinationPathtoUse+$PackagetoFind.NewFileName
               Write-host ('Copying files to drive. Source path is: '+$SourcePathtoUse+' Destination path is: '+$DestinationPathtoUse+' (New Name is '+$PackagetoFind.NewFileName+')')
           }
           else{
               Write-host ('Copying files to drive. Source path is: '+$SourcePathtoUse+' Destination path is: '+$DestinationPathtoUse)        
           }
           Copy-Item -Path $SourcePathtoUse  -Destination $DestinationPathtoUse -Recurse -force  
           #### End Copy Files
           if (($PackagetoFind.ModifyInfoFileTooltype -eq 'Replace') -or ($PackagetoFind.ModifyInfoFileTooltype -eq 'Modify')) {
               Write-Host 'Tooltypes for relevant .info files for:'$PackagetoFind.PackageName
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
                       throw 
                } 
                   $OldToolTypes= Get-Content($TempFolder+$filename+'.txt')
                   Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $Tooltypes  | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
               }
               if (-not (Write-AmigaTooltypes -IconPath ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall_VolumeName+'\'+$PackagetoFind.LocationtoInstall+$filename) -ToolTypesPath ($TempFolder+$filename+'amendedtoimport.txt') -TempFoldertouse $TempFoldertouse -HSTAmigaPathtouse $HSTAmigaPath)){
                   throw
            }                             
           }
           else {
           }    
       }
    $PackageCheck=$PackagetoFind.PackageName  
}

Write-Host 'Completed install of packages'
Wr

Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\Startup-Sequence') -DatatoExport $StartupSequence -AddLineFeeds 'TRUE'
Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\User-Startup') -DatatoExport $UserStartup -AddLineFeeds 'TRUE'

### Wireless Prefs

Write-host 'Creating Wireless Prefs file'

if (-not (Test-Path ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\'))){
    $null = New-Item -path ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys') -ItemType Directory -Force 

}

$WirelessPrefs = "network={",
                 "   ssid=""$SSID""",
                 "   psk=""$WifiPassword""",
                 "}"
                 
Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\wireless.prefs') -DatatoExport $WirelessPrefs -AddLineFeeds 'TRUE'                

### End Wireless Prefs

### Fix WBStartup

If ($KickstartVersiontouse -eq 3.2){
    Write-Host 'Fixing Menutools'
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\WBStartup\MenuTools') -DestinationPath ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup') -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        throw
    }
    
    $WBStartup = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\Menutools') 
    $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Wait' -Injectionpoint 'after' -Startpoint 'ADDRESS WORKBENCH' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_1')) -ArexxFlag 'AREXX'
    $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Offline and Online Menus' -Injectionpoint 'before' -Startpoint 'EXIT' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_2')) -ArexxFlag 'AREXX'
    
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\Menutools') -DatatoExport $WBStartup -AddLineFeeds 'TRUE'
}

## Clean up AmigaImageFiles

if (Test-Path ($AmigaDrivetoCopy+$VolumeName_System+'\Disk.info')){
    Remove-Item ($AmigaDrivetoCopy+$VolumeName_System+'\Disk.info')
}

#### Set up FAT32

Write-Host 'Setting up FAT32 files'

Write-Host 'Copying Emu68Pistorm and Emu68Pistorm32lite files' 

$null = copy-Item ($TempFolder+"Emu68Pistorm\*") -Destination ($FAT32Partition)
$null = copy-Item ($TempFolder+"Emu68Pistorm32lite\*") -Destination ($FAT32Partition)
$null= Remove-Item ($FAT32Partition+'config.txt')
$null = copy-Item ($LocationofAmigaFiles+'FAT32\ps32lite-stealth-firmware.gz') -Destination ($FAT32Partition)

if (-not (Test-Path ($FAT32Partition+'Kickstarts\'))){
    $null = New-Item -path ($FAT32Partition+'Kickstarts\') -ItemType Directory -Force
}

if (-not (Test-Path ($FAT32Partition+'Install\'))){
    $null = New-Item -path ($FAT32Partition+'Install\') -ItemType Directory -Force
}

Write-Host 'Copying Cmdline.txt' 

Copy-Item ($LocationofAmigaFiles+'FAT32\cmdline.txt') -Destination ($FAT32Partition)

$ConfigTxt = Get-Content -Path ($LocationofAmigaFiles+'FAT32\config.txt')

Write-Host 'Preparing Config.txt'

$RevisedConfigTxt=$null

$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.CSV') -Delimiter (';')
foreach ($AvailableScreenMode in $AvailableScreenModes){
    if ($AvailableScreenMode.Name -eq $ScreenMode){
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


Export-TextFileforAmiga -DatatoExport $RevisedConfigTxt -ExportFile ($FAT32Partition+'config.txt') -AddLineFeeds 'TRUE' 

Write-host 'Copying Kickstart file to FAT32 partition'
$null = copy-Item -LiteralPath $KickstartPath -Destination ($FAT32Partition+$KickstartNameFAT32)

### Transfer files to Work

if ($TransferLocation) {
    # Determine Size of transfer
    $SizeofFilestoTransfer=(Get-ChildItem $TransferLocation -force -Recurse | Where-Object { $_.PSIsContainer -eq $false }  | Measure-Object -property Length -sum).sum /1Mb
    Write-Host ('Transferring files from '+$TransferLocation+' to My Files directory on Work drive')
    Write-Host ('Total size of files to be transferred is:'+$SizeofFilestoTransfer)
    Write-Host ('Available space on Work drive is: '+$SizeofPartition_Other)
    if ($SizeofFilestoTransfer -lt (([double]($SizeofPartition_Other.trim('mb')))+10)){
        $SourcePathtoUse = $TransferLocation+('*')
        if (Test-Path ($AmigaDrivetoCopy+$VolumeName_Other+'\My Files.info')){
            Remove-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\My Files.info')
        }
        $null = Copy-Item ($TempFolder+'NewFolder.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\My Files.info')
        if (-not(Start-HSTImager -Command 'fs copy' -SourcePath $SourcePathtoUse -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_Other+'\My Files') -HSTImagePathtouse $HSTImagePath -TempFoldertouse $TempFolder)){
            throw
        }
    }
    else{
        Write-host "Size of files to be transferred is too large for the Work partition! Not transferring!"
    }
}

if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_System+'\*') -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
} 
if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_Other+'\*') -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_Other) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    throw
}  

Set-Location $LocationofImage
& $HDF2emu68Path $LocationofImage$NameofImage $SizeofFAT32 ($FAT32Partition)
$null= Rename-Item ($LocationofImager+'emu68_converted.img') -NewName ('Emu68Kickstart'+$KickstartVersiontoUse+'.img')
Set-location $WorkingFolder

$EndDateandTime = (Get-Date -Format HH:mm:ss)
$ElapsedTime = (New-TimeSpan -Start $StartDateandTime -End $EndDateandTime).TotalSeconds

Write-Host "Started at: $StartDateandTime Finished at: $EndDateandTime. Total time to run (in seconds) was: $ElapsedTime" 
