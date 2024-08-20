##### Script

$UnLZXURL='http://aminet.net/util/arc/W95unlzx.lha'

$HSTImagerreleases= 'https://api.github.com/repos/henrikstengaard/hst-imager/releases'
$HSTAmigareleases= 'https://api.github.com/repos/henrikstengaard/hst-amiga/releases'
$Emu68releases= 'https://api.github.com/repos/michalsc/Emu68/releases'
$Emu68Toolsreleases= 'https://api.github.com/repos/michalsc/Emu68-tools/releases'

$Scriptpath='C:\Users\Matt\OneDrive\Documents\Emu68Imager'
$SourceProgramPath='C:\Users\Matt\OneDrive\Documents\Emu68Imager\Programs\'
$InputFolder='C:\Users\Matt\OneDrive\Documents\Emu68Imager\InputFiles\'

Write-host 'Pistorm Imager'

$WorkingFolder = Read-Host "Please enter the location of the Working Folder. Required folders will be created if the the working folder does not contain them"
if (!$WorkingFolder){
    Write-host "No input. Using C:\Users\Matt\Downloads\Emu68Imager\" 
    $WorkingFolder='C:\Users\Matt\Downloads\Emu68Imager\'
}

Set-Location $WorkingFolder

$TempFolder=$WorkingFolder+'Temp\'
if (-not (Test-Path $TempFolder)){
    $null = New-Item $TempFolder -ItemType Directory
}

$ProgramsFolder=$WorkingFolder+'Programs\'
if (-not (Test-Path $ProgramsFolder)){
    $null = New-Item $ProgramsFolder -ItemType Directory
}

$HDF2emu68Path=$WorkingFolder+'Programs\hdf2emu68.exe'
$7zipPath=$WorkingFolder+'Programs\7z.exe'

if (-not (Test-Path $HDF2emu68Path)){
    $null = Copy-Item ($SourceProgramPath+'hdf2emu68.exe') $HDF2emu68Path
}

if (-not (Test-Path $7zipPath)){
    $null = Copy-Item ($SourceProgramPath+'7z.exe') $7zipPath -Force
    $null = Copy-Item ($SourceProgramPath+'7z.dll') ($ProgramsFolder+'7z.dll') -Force
}

if (-not (Test-Path $HDF2emu68Path)){
    Write-Host 'HDF2emu68.exe not found! Error in installation!'
    exit
}

if (-not (Test-Path $7zipPath)){
    Write-Host '7zip.exe not found! Error in installation!'
    exit
}

if (-not (Test-Path ($ProgramsFolder+'7z.dll'))){
    Write-Host '7z.dll not found! Error in installation!'
    exit
}


$HSTImagePath=$ProgramsFolder+'HST-Imager\hst.imager.exe'
$HSTAmigaPath=$ProgramsFolder+'HST-Amiga\hst.amiga.exe'
$LZXPath=$ProgramsFolder+'unlzx.exe'

#$LocationofAmigaFiles=$WorkingFolder+'AmigaFiles\'
$LocationofAmigaFiles='C:\Users\Matt\OneDrive\Documents\Emu68Imager\AmigaFiles\'
#$InputFolder=$WorkingFolder+'InputFiles\'


$LocationofImage=$WorkingFolder+'OutputImage\'
$AmigaDrivetoCopy=$WorkingFolder+'AmigaImageFiles\'
$AmigaDownloads=$WorkingFolder+'AmigaDownloads\'
$FAT32Partition=$WorkingFolder+'FAT32Partition\'

## Amiga Variables

$DeviceName_System='SDH0'
$VolumeName_System='Workbench'
$DeviceName_Other='SDH1'
$VolumeName_Other='Work'
#$InstallPathMUI='SYS:Programs/MUI'
#$InstallPathPicasso96='SYS:Programs/Picasso96'
#$InstallPathAmiSSL='SYS:Programs/AmiSSL'
$GlowIcons='TRUE'

## Import Functions

Import-Module ($Scriptpath+'\Functions.psm1')

$SizeofImage = Read-Host "Please enter the size of image (in Megabytes)"
if (!$SizeofImage){
    Write-host "No input. Using 350mb"
    $SizeofImage='350'
}
$SizeofImage = $SizeofImage+'mb'

$SizeofPartition_System = Read-Host "Please enter the size of Workbench partition (in Megabytes)"
if (!$SizeofPartition_System){
    Write-host "No input. Using 100mb"
    $SizeofPartition_System='100'
}
$SizeofPartition_System = $SizeofPartition_System+'mb'

$SizeofPartition_Other = Read-Host "Please enter the size of Work partition (in Megabytes)"
if (!$SizeofPartition_Other){
    Write-host "No input. Using 100mb"
    $SizeofPartition_Other='100'
}
$SizeofPartition_Other = $SizeofPartition_Other+'mb'

$SizeofFAT32 = Read-Host "Please enter the size of FAT32 (in Megabytes)"
if (!$SizeofFAT32) {
    Write-host "No input. Using 135mb"
    $SizeofFAT32 ='135'
}

$KickstartVersiontoUse = Read-Host "Please choose either Kickstart 3.2 or 3.1 (3.1, 3.2)"

$NameofImage=('Pistorm'+$KickstartVersiontoUse+'.HDF')

$TransferLocation= Read-Host "Please enter location of files to transfer"

$SSID = Read-Host "Please enter your Wireless SSID"
$WifiPassword= Read-Host "Please enter your wifi password" -MaskInput

$ROMPath = Read-Host "Please enter the folder location of the Amiga Kickstart Rom"
if (!$ROMPath) {
        Write-host "No input. Using D:\Emulators\Amiga Files\Shared\rom\"
    $ROMPath='D:\Emulators\Amiga Files\Shared\rom\'
}

$ADFPath = Read-Host "Please enter the folder location of the Amiga Workbench ADF files"
if (!$ADFPath) {
    Write-host "No input. Using D:\Emulators\Amiga Files\Shared\adf\"
    $ADFPath='D:\Emulators\Amiga Files\Shared\adf\'
}

$ScreenMode = Read-Host "Please enter the screenmode"
if (!$ScreenMode) {
    Write-host "No input. Using 1080p 60hz"
    $ScreenMode='1920*1080-60'
}

$StartDateandTime = (Get-Date -Format HH:mm:ss)

Write-Host "Starting execution at $StartDateandTime"

### Clean up

$NewFolders =("Temp","OutputImage","AmigaImageFiles\System","AmigaImageFiles\Work","FAT32Partition")

foreach ($NewFolder in $NewFolders) {
    if (Test-Path ($WorkingFolder+$NewFolder)){
        $null = Remove-Item ($WorkingFolder+$NewFolder) -Recurse
    }
    $null = New-Item -path ($WorkingFolder) -Name $NewFolder -ItemType Directory
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
$KickstartNameFAT32=$FoundKickstarttoUse.Fat32Name

Write-Host ('Kickstart to be used is: '+$KickstartPath)

$AvailableADFs = Compare-ADFHashes -PathtoADFFiles $ADFPath -PathtoADFHashes ($InputFolder+'ADFHashes.csv') -KickstartVersion $KickstartVersiontoUse -PathtoListofInstallFiles ($InputFolder+'ListofInstallFiles.csv') 

$ListofInstallFiles = Import-Csv ($InputFolder+'ListofInstallFiles.csv') -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersiontoUse} | Sort-Object -Property 'InstallSequence'

foreach ($InstallFileLine in $ListofInstallFiles) {
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
    exit
}

Write-Host "Downloading HST Amiga"
if (-not(Get-GithubRelease -GithubRelease $HSTAmigareleases -Tag_Name '0.3.163' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTAmiga.zip') -LocationforProgram ($ProgramsFolder+'HST-Amiga\') -Sort_Flag '')){
    Write-Host 'Error downloading HST-Amiga! Cannot continue!'
    exit
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
    Write-Host 'Error downloading Emu68Pistorm! Cannot continue!'
    exit
}

Write-Host "Downloading Emu68Pistorm32lite"
if (-not(Get-GithubRelease -GithubRelease $Emu68releases -Tag_Name "nightly" -Name 'Emu68-pistorm32lite' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm32lite.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm32lite\') -Sort_Flag 'SORT')){
    Write-Host 'Error downloading Emu68Pistorm32lite! Cannot continue!'
    exit
}

Write-Host "Downloading Emu68Tools"
if (-not(Get-GithubRelease -GithubRelease $Emu68Toolsreleases -Tag_Name "nightly" -Name 'Emu68-tools' -LocationforDownload ($AmigaDownloads+'Emu68Tools.zip') -LocationforProgram ($tempfolder+'Emu68Tools\') -Sort_Flag 'SORT')){
    Write-Host 'Error downloading Emu68Tools! Cannot continue!'
    exit
}

### End Download HST

### Begin Download UnLzx

Write-Host "Downloading UnLZX"
If (-not (Get-AmigaFileWeb -URL $UnLZXURL -NameofDL 'W95unlzx.lha' -LocationforDL $TempFolder)){
    Write-host "Error downloading UnLZX! Quitting"
    exit
}

if (-not(Expand-Zipfiles -7zipPathtouse $7zipPath -TempFoldertouse $TempFolder -InputFile ($TempFolder+'W95unlzx.lha') -OutputDirectory $ProgramsFolder -FiletoExtract 'unlzx.exe')){
    Write-Host ('Deleting package '+($TempFolder+'W95unlzx.lha'))
    $null=Remove-Item -Path ($TempFolder+'W95unlzx.lha') -Force
    exit # Error in extracting
}

### End Download UnLzx

Write-Host "Preparing Amiga Image"
Start-HSTImager -Command "blank" -DestinationPath ($LocationofImage+$NameofImage) -ImageSize $SizeofImage -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath 
Start-HSTImager -Command "rdb init" -DestinationPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath
Start-HSTImager -Command "rdb filesystem add" -SourcePath ($LocationofImage+$NameofImage) -DestinationPath ($WorkingFolder+'Programs\HST-Imager\pfs3aio') -FileSystem "PFS3" -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath
Start-HSTImager -Command "rdb part add" -SourcePath ($LocationofImage+$NameofImage) -DeviceName $DeviceName_System -FileSystem "PFS3" -SizeofPartition $SizeofPartition_System -BootableFlag "-b" -MaxTransfer "0xffffff" -Mask "0x7ffffffe" -buffers "300" -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath
Start-HSTImager -Command "rdb part add" -SourcePath ($LocationofImage+$NameofImage) -DeviceName $DeviceName_Other -FileSystem "PFS3" -SizeofPartition $SizeofPartition_Other -BootableFlag "-b" -MaxTransfer "0xffffff" -Mask "0x7ffffffe" -buffers "300" -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath
Start-HSTImager -Command "rdb part format" -SourcePath ($LocationofImage+$NameofImage) -PartitionNumber "1" -VolumeName $VolumeName_System -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath
Start-HSTImager -Command "rdb part format" -SourcePath ($LocationofImage+$NameofImage) -PartitionNumber "2" -VolumeName $VolumeName_Other -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath

#### Begin - Create NewFolder.info file
if (($KickstartVersiontoUse -eq 3.1) -or (($KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'FALSE'))) {
    Start-HSTImager -Command 'fs extract' -ADFName $StorageADF -ADFInputFiles 'Monitors.info' -ADFLocationtoInstall $TempFolder -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    Rename-Item ($TempFolder+'Monitors.info') ($TempFolder+'def_drawer.info')
}
elseif(($KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'TRUE')){
    Start-HSTImager -Command 'fs extract' -ADFName $GlowIconsADF -ADFInputFiles 'Prefs\Env-Archive\Sys\def_drawer.info' -ADFLocationtoInstall $TempFolder -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
}

Rename-Item ($TempFolder+'def_drawer.info') ($TempFolder+'NewFolder.info') -Force

#### End - Create NewFolder.info file

### Begin Basic Drive Setup
Add-AmigaFolder -AmigaFolderPath "System\Programs\" -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
Add-AmigaFolder -AmigaFolderPath "System\Storage\DataTypes\" -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy

if (-not (Test-Path ($AmigaDrivetoCopy+"Work\"))){
    $null = New-Item -path ($AmigaDrivetoCopy+"Work\") -ItemType Directory -Force 
    
}

if ($KickstartVersiontoUse -eq 3.1){
    Start-HSTImager -Command 'fs extract' -ADFName $InstallADF -ADFInputFiles 'Update\disk.info' -DrivetoWrite 'Work' -Extract_Flag 'AmigaDrive' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
}
elseif ($KickstartVersiontoUse -eq 3.2){
    Start-HSTImager -Command 'fs extract' -ADFName $GlowIconsADF -ADFInputFiles 'Prefs\Env-Archive\Sys\def_harddisk.info' -DrivetoWrite 'Work' -Extract_Flag 'AmigaDrive' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    Rename-Item ($AmigaDrivetoCopy+"Work\def_harddisk.info") ($AmigaDrivetoCopy+"Work\disk.info") 
}

### End Basic Drive Setup

### Begin Copy Install files from ADF

$TotalItems=$ListofInstallFiles.Count

$ItemCounter=1

Foreach($InstallFileLine in $ListofInstallFiles){
    Write-Host ''
    if ($InstallFileLine.AmigaFiletoInstall -eq "") {
        Write-Host ('('+$ItemCounter+'/'+$TotalItems+') Processing ADF: '+$InstallFileLine.FriendlyName+' Files: ALL FILES') 
    }
    else{
        Write-Host ('('+$ItemCounter+'/'+$TotalItems+') Processing ADF:'+$InstallFileLine.FriendlyName+' Files: '+$InstallFileLine.AmigaFiletoInstall)
    }
    if ($InstallFileLine.Uncompress -eq "TRUE"){
        Write-host 'Extracting files'
        Start-HSTImager -Command 'fs extract' -ADFName $InstallFileLine.Path -ADFInputFiles ($InstallFileLine.AmigaFiletoInstall -replace '/','\') -Extract_Flag 'AmigaDrive' -DrivetoWrite 'System' -ADFLocationtoInstall $InstallFileLine.LocationtoInstall -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
        Expand-AmigaZFiles  -7zipPathtouse $7zipPath -WorkingFoldertouse $TempFolder -LocationofZFiles ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$InstallFileLine.LocationtoInstall)
    }
    elseif (($InstallFileLine.NewFileName -ne "")  -or
            ($InstallFileLine.ModifyScript -ne 'FALSE') -or
            ($InstallFileLine.ModifyInfoFileTooltype -ne 'FALSE')){
                if ($InstallFileLine.LocationtoInstall -ne ""){
                    $LocationtoInstall=($InstallFileLine.LocationtoInstall+'\')
                }
                else{
                    $LocationtoInstall=$null
                }
                if ($InstallFileLine.NewFileName -ne ""){
                    $FullPath = $AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+$InstallFileLine.NewFileName
                }
                else{
                    $FullPath = $AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+(Split-Path $InstallFileLine.AmigaFiletoInstall -Leaf) 
                }
                $filename = Split-Path $FullPath -leaf
                Write-host 'Extracting files'
                Start-HSTImager -Command 'fs extract' -ADFName $InstallFileLine.Path -ADFInputFiles $InstallFileLine.AmigaFiletoInstall -Extract_Flag 'AmigaDrive' -DrivetoWrite 'System' -ADFLocationtoInstall $LocationtoInstall -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
                if ($InstallFileLine.NewFileName -ne ""){
                    $NameofFiletoChange=$InstallFileLine.AmigaFiletoInstall.split("/")[-1]  
                    if (Test-Path ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+$InstallFileLine.NewFileName)){
                        Remove-Item ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+$InstallFileLine.NewFileName)
                    }
                    $null = rename-Item -Path ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+$NameofFiletoChange) -NewName $InstallFileLine.NewFileName            
                }
                if ($InstallFileLine.ModifyInfoFileTooltype -eq 'Modify'){
                    Read-AmigaTooltypes -HSTAmigaPathtouse $HSTAmigaPath -TempFoldertouse $TempFolder -DrivetoRead $InstallFileLine.DrivetoInstall -InfoFiletoReadPath ($LocationtoInstall+$filename) -InfoTextFiletoWritePath ($TempFolder+$filename+'.txt') -AmigaDrivetoCopytouse $AmigaDrivetoCopy                  
                    $OldToolTypes = Get-Content($TempFolder+$filename+'.txt')
                    $TooltypestoModify = Import-Csv ($LocationofAmigaFiles+$LocationtoInstall+'\'+$filename+'.txt') -Delimiter ';'
                    Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $TooltypestoModify | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
                    Write-AmigaTooltypes -HSTAmigaPathtouse $HSTAmigaPath -DrivetoWrite $InstallFileLine.DrivetoInstall -InfoFiletoWritePath ($LocationtoInstall+$filename) -InfoTextFiletoReadPath ($TempFolder+$fileName+'amendedtoimport.txt') -TempFoldertouse $TempFoldertouse -AmigaDrivetoCopytouse $AmigaDrivetoCopy
                }        
                if ($InstallFileLine.ModifyScript -eq'Remove'){
                    Write-Host ('Modifying '+$FileName+' for: '+$InstallFileLine.ScriptNameofChange)
                    $ScripttoEdit = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+$FileName)
                    $ScripttoEdit = Edit-AmigaScripts -ScripttoEdit $ScripttoEdit -Action 'remove' -name $InstallFileLine.ScriptNameofChange -Startpoint $InstallFileLine.ScriptInjectionStartPoint -Endpoint $InstallFileLine.ScriptInjectionEndPoint                    
                    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$InstallFileLine.DrivetoInstall+'\'+$LocationtoInstall+$FileName) -DatatoExport $ScripttoEdit -AddLineFeeds 'TRUE'
                }
            }    
    else {
         Write-host 'Extracting files'
         Start-HSTImager -Command 'fs extract' -ADFName $InstallFileLine.Path -ADFInputFiles $InstallFileLine.AmigaFiletoInstall -DrivetoWrite $DeviceName_System -ADFLocationtoInstall $InstallFileLine.LocationtoInstall -Extract_Flag 'rdb' -HDFFullPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    }
    $ItemCounter+=1    
}
### End Copy Install files from ADF

#######################################################################################################################################################################################################################################

$ListofPackagestoInstall = Import-Csv ($InputFolder+'ListofPackagestoInstall.csv') -Delimiter ';' |  Where-Object {$_.KickstartVersion -match $KickstartVersiontoUse} | Where-Object {$_.InstallFlag -eq 'TRUE'} #| Sort-Object -Property 'InstallSequence','PackageName'

$ListofPackagestoInstall > C:\Users\Matt\Downloads\check.txt

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
                    $ADFtoUse=$StorageADF       
                    Start-HSTImager -Command 'fs extract' -ADFName $ADFtoUse -ADFInputFiles $PackagetoFind.FilestoInstall -ADFLocationtoInstall ($TempFolder+$PackagetoFind.FileDownloadName) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
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
                        Write-host "Unrecoverable error with download(s)!"
                        exit
                    }                    
                }
                if ($PackagetoFind.PerformHashCheck -eq 'TRUE'){
                    if (-not (Compare-FileHash -FiletoCheck ($AmigaDownloads+$PackagetoFind.FileDownloadName) -HashtoCheck $PackagetoFind.Hash)){
                        Write-Host "Error in downloaded packages! Unable to continue!"
                        Write-Host ('Deleting package '+($AmigaDownloads+$PackagetoFind.FileDownloadName))
                        $null=Remove-Item -Path ($AmigaDownloads+$PackagetoFind.FileDownloadName) -Force 
                        exit
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
                    if (-not(Expand-Zipfiles -7zipPathtouse $7zipPath -TempFoldertouse $TempFolder -InputFile ($AmigaDownloads+$PackagetoFind.FileDownloadName) -OutputDirectory ($TempFolder+$PackagetoFind.FileDownloadName))){
                        Write-Host ('Deleting package '+($AmigaDownloads+$PackagetoFind.FileDownloadName))
                        $null=Remove-Item -Path ($AmigaDownloads+$PackagetoFind.FileDownloadName) -Force
                        exit # Error in extracting
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
           $DestinationPathtoUse =($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall+'\'+$PackagetoFind.LocationtoInstall) 
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
           if (-not (Test-Path ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall+'\'+$PackagetoFind.LocationtoInstall))){
               $null = New-Item ($AmigaDrivetoCopy+$PackagetoFind.DrivetoInstall+'\'+$PackagetoFind.LocationtoInstall) -ItemType Directory
           }
           if ($PackagetoFind.CreateFolderInfoFile -eq 'TRUE'){
               Add-AmigaFolder -AmigaFolderPath ($PackagetoFind.DrivetoInstall+'\'+$PackagetoFind.LocationtoInstall) -TempFoldertouse $TempFolder
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
                   Read-AmigaTooltypes -HSTAmigaPathtouse $HSTAmigaPath -TempFoldertouse $TempFolder -DrivetoRead $PackagetoFind.DrivetoInstall -InfoFiletoReadPath ($PackagetoFind.LocationtoInstall+$filename) -InfoTextFiletoWritePath ($TempFolder+$filename+'.txt') -AmigaDrivetoCopytouse $AmigaDrivetoCopy
                   $OldToolTypes= Get-Content($TempFolder+$filename+'.txt')
                   Get-ModifiedToolTypes -OriginalToolTypes $OldToolTypes -ModifiedToolTypes $Tooltypes  | Out-File ($TempFolder+$filename+'amendedtoimport.txt')
               }
               Write-AmigaTooltypes -HSTAmigaPathtouse $HSTAmigaPath -DrivetoWrite $PackagetoFind.DrivetoInstall -InfoFiletoWritePath ($PackagetoFind.LocationtoInstall+$filename) -InfoTextFiletoReadPath ($TempFolder+$filename+'amendedtoimport.txt') -TempFoldertouse $TempFoldertouse -AmigaDrivetoCopytouse $AmigaDrivetoCopy
           }
           else {
           }    
       }
    $PackageCheck=$PackagetoFind.PackageName  
}

Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+'System\S\Startup-Sequence') -DatatoExport $StartupSequence -AddLineFeeds 'TRUE'
Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+'System\S\User-Startup') -DatatoExport $UserStartup -AddLineFeeds 'TRUE'

### Wireless Prefs

if (-not (Test-Path ($AmigaDrivetoCopy+"System\Prefs\Env-Archive\Sys\"))){
    $null = New-Item -path ($AmigaDrivetoCopy+"System\Prefs\Env-Archive\Sys") -ItemType Directory -Force 

}

$WirelessPrefs = "network={",
                 "   ssid=""$SSID""",
                 "   psk=""$WifiPassword""",
                 "}"
                 
Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+'System\Prefs\Env-Archive\Sys\wireless.prefs') -DatatoExport $WirelessPrefs -AddLineFeeds 'TRUE'                

### End Wireless Prefs

# #### End Fix HDToolBox ToolType

### Fix WBStartup

If ($KickstartVersiontouse -eq 3.2){
    Start-HSTImager -Command 'fs extract' -ADFName $StorageADF -ADFInputFiles 'WBStartup\MenuTools' -Extract_Flag 'AmigaDrive' -DrivetoWrite 'System' -ADFLocationtoInstall 'WBStartup\' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    
    $WBStartup = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+'System\WBStartup\Menutools') 
    $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Wait' -Injectionpoint 'after' -Startpoint 'ADDRESS WORKBENCH' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_1')) -ArexxFlag 'AREXX'
    $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Offline and Online Menus' -Injectionpoint 'before' -Startpoint 'EXIT' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_2')) -ArexxFlag 'AREXX'
    
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+'System\WBStartup\Menutools') -DatatoExport $WBStartup -AddLineFeeds 'TRUE'
}

## Clean up AmigaImageFiles

if (Test-Path ($AmigaDrivetoCopy+'System\Disk.info')){
    Remove-Item ($AmigaDrivetoCopy+'System\Disk.info')
}

#### Set up FAT32

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

#$null = copy-item 'D:\Emulators\Amiga Files\Shared\rom\amiga-os-120.rom' ($FAT32Partition+'Kickstarts\') -Force
#$null = copy-item 'D:\Emulators\Amiga Files\Shared\rom\amiga-os-130.rom' ($FAT32Partition+'Kickstarts\') -Force

Copy-Item ($LocationofAmigaFiles+'FAT32\cmdline.txt') -Destination ($FAT32Partition)

$ConfigTxt = Get-Content -Path ($LocationofAmigaFiles+'FAT32\config.txt')

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

$null = copy-Item $KickstartPath -Destination ($FAT32Partition+$KickstartNameFAT32)
Write-AmigaFilestoFS -HSTAmigaPathtouse $HSTAmigaPath -DrivetoRead 'System' -FilestoCopy '*' -DrivetoWrite $DeviceName_System -HDFFullPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
Write-AmigaFilestoFS -HSTAmigaPathtouse $HSTAmigaPath -DrivetoRead 'Work' -FilestoCopy '*' -DrivetoWrite $DeviceName_Other -HDFFullPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy

### Transfer files to Work

if ($TransferLocation) {
    # Determine Size of transfer
    $SizeofFilestoTransfer=(Get-ChildItem $TransferLocation -Recurse | Where-Object { $_.PSIsContainer -eq $false }  | Measure-Object -property Length -sum).sum /1Mb
    if ($SizeofFilestoTransfer -lt ($SizeofPartition_Other+10)){   
        Write-AmigaFilestoFS -HSTAmigaPathtouse $HSTAmigaPath -FilestoCopy $TransferLocation -DrivetoWrite $DeviceName_Other -HDFFullPath ($LocationofImage+$NameofImage) -TransferFlag 'Transfer' -TempFoldertouse $TempFolder -AmigaDrivetoCopytouse $AmigaDrivetoCopy
    }
    else{
        Write-host "Size of files to be transferred is too large for the Work partition! Not transferring!"
    }
}

Set-Location $LocationofImage
& $HDF2emu68Path $LocationofImage$NameofImage $SizeofFAT32 ($FAT32Partition)
$null= Rename-Item ($LocationofImager+'emu68_converted.img') -NewName ('Emu68Kickstart'+$KickstartVersiontoUse+'.img')
Set-location $WorkingFolder

$EndDateandTime = (Get-Date -Format HH:mm:ss)
$ElapsedTime = (New-TimeSpan -Start $StartDateandTime -End $EndDateandTime).TotalSeconds

Write-Host "Started at: $StartDateandTime Finished at: $EndDateandTime. Total time to run (in seconds) was: $ElapsedTime" 
