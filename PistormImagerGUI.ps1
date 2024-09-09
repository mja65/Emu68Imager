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
    $Scriptpath = (Split-Path -Parent $MyInvocation.MyCommand.Definition)+'\'
} 

if ($RunMode -eq 0){
    $Scriptpath = 'C:\Users\Matt\OneDrive\Documents\Emu68Imager\'    
}

######################################################################## Functions #################################################################################################################
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
    $Script:SizeofFat32_Pixels_Maximum = $Script:PartitionBarPixelperKB * $Script:SizeofFat32_Maximum
    
    if (($Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_Other) -le $Script:WorkbenchMaximum) {
        $Script:SizeofPartition_System_Maximum = ($Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_Other)
    }
    else {
        $Script:SizeofPartition_System_Maximum = $Script:WorkbenchMaximum
    }
    $Script:SizeofPartition_System_Pixels_Maximum = $Script:PartitionBarPixelperKB * $Script:SizeofPartition_System_Maximum
    
    $Script:SizeofPartition_Other_Maximum = $Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_System
    $Script:SizeofPartition_Other_Pixels_Maximum = $Script:PartitionBarPixelperKB * $Script:SizeofPartition_Other_Maximum

    $Script:SizeofFreeSpace_Maximum = $Script:SizeofDisk-$Script:SizeofFAT32-$Script:SizeofPartition_System-$Script:SizeofPartition_Other
    $Script:SizeofFreeSpace_Pixels_Maximum = ($Script:SizeofDisk * $Script:PartitionBarPixelperKB) - (($Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other)* $Script:PartitionBarPixelperKB) 
 
    $Script:SizeofUnallocated_Pixels_Maximum = $Script:PartitionBarWidth - (($Script:SizeofFreeSpace + $Script:SizeofPartition_Other_Pixels + $Script:SizeofPartition_System_Pixels + $Script:SizeofFat32_Pixels) * $Script:PartitionBarPixelperKB)
    $Script:SizeofUnallocated_Maximum =  $Script:SizeofDisk - $Script:SizeofFreeSpace - $Script:SizeofPartition_Other - $Script:SizeofPartition_System - $Script:SizeofFAT32
}

function Get-FormattedPathforGUI {
    param (
        $PathtoTruncate
    )
    $LengthofString = 26 #Maximum supported by label less three for the ...
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
function Get-TransferredFilesAvailableSpace {
    param (
        $PFSLimit,
        $WorkSize #In GB
    )
    
    $WorkSizeKb = $WorkSize*1024*1024

    if ($WorkSizeKb -ge $PFSLimit){
        $AvailableSpacetoReport = $PFSLimit
    }
    else{
        $AvailableSpacetoReport = $WorkSizeKb
    }
    return $AvailableSpacetoReport
}


function Get-RoundedDiskSize {
    param (
        $Size,
        $Scale
    )
    if ($Scale -eq 'GiB'){
        $RoundedSize = ([math]::truncate(($Size/1024/1024)*100)/100)
        
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

    $SizeofPartition_Systemtouse = (([math]::truncate($SizeofPartition_System_param)).ToString()+'kb')
    $SizeofPartition_Othertouse = ([math]::truncate($SizeofPartition_Other_param))

    $PartitionNumbertoPopulate =1

    $AmigaPartitionsList += [PSCustomObject]@{
        PartitionNumber = $PartitionNumbertoPopulate 
        SizeofPartition =  $SizeofPartition_Systemtouse
        DosType = 'PFS3'
        VolumeName = $VolumeName_System_param
        DeviceName = $DeviceName_System_param  
    }
    
    $PartitionNumbertoPopulate ++
    $CapacitytoFill = $SizeofPartition_Othertouse

    $TotalNumberWorkPartitions = [math]::ceiling($CapacitytoFill/$PFSLimit)

    $WorkPartitionSize = $SizeofPartition_Othertouse/$TotalNumberWorkPartitions
 
    do {
        if ($PartitionNumbertoPopulate -eq 2){
            $VolumeNametoPopulate = $VolumeName_Other_param  
            $DeviceNametoPopulate = $DeviceName_Other_param  
        }
        else{
            $VolumeNametoPopulate = ($VolumeName_Other_param+(($PartitionNumbertoPopulate-1).ToString()))
            $DeviceNametoPopulate = ($DeviceName_Prefix_param+(($PartitionNumbertoPopulate-1).ToString()))
           
        }
        $AmigaPartitionsList += [PSCustomObject]@{
            PartitionNumber = $PartitionNumbertoPopulate 
            SizeofPartition =  ((($WorkPartitionSize).ToString())+'kb')
            DosType = 'PFS3'
            VolumeName = $VolumeNametoPopulate
            DeviceName = $DeviceNametoPopulate    
        }
        $PartitionNumbertoPopulate ++
    } until (
        $PartitionNumbertoPopulate -ge  $TotalNumberWorkPartitions
    )

    return $AmigaPartitionsList

}
function Get-RequiredSpace {
    param (
        $ImageSize
    )    
    $SpaceNeeded = (2*$ImageSize) #Image
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
}

function Write-InformationMessage {
    param (
        $Message
    )
    Write-Host " `t`t $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param (
        $Message
    )
    Write-Host "[ERROR] `t $Message" -ForegroundColor Red
}

function Write-TaskCompleteMessage {
    param (
        $Message
    )
    Write-Host "[Section: $Script:CurrentSection of $Script:TotalSections]: `t $Message" -ForegroundColor Green
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
    (Get-Volume -DriveLetter (Split-Path -Qualifier $PathtoCheck).Replace(':','')).SizeRemaining
}

function Get-UICapturedData {
    param (

    )
    Write-InformationMessage -message "HSTDiskName is: $Script:HSTDiskName" 
    Write-InformationMessage -message "ScreenModetoUse is: $Script:ScreenModetoUse"
    Write-InformationMessage -message "KickstartVersiontoUse is: $Script:KickstartVersiontoUse"
    Write-InformationMessage -message "SSID is: $Script:SSID" 
    Write-InformationMessage -message "WifiPassword is: $Script:WifiPassword" 
    Write-InformationMessage -message "SizeofFAT32 is: $Script:SizeofFAT32" 
    Write-InformationMessage -message "SizeofImage is: $Script:SizeofImage"
    Write-InformationMessage -message "SizeofPartition_System is: $Script:SizeofPartition_System"
    Write-InformationMessage -message "SizeofPartition_Other is: $Script:SizeofPartition_Other"
    Write-InformationMessage -message "WorkingPathis: $Script:WorkingPath"
    Write-InformationMessage -message "ROMPath is: $Script:ROMPath"
}

function Confirm-UIFields {
    param (
        
    )
    $ErrorMessage = $null
    if (-not($Script:HSTDiskName)){
        $ErrorMessage += 'You have not selected a disk'+"`n"
    }
    if (-not($WPF_UI_KickstartVersion_Dropdown.SelectedItem)) {
        $ErrorMessage += 'You have not populated a Kickstart version'+"`n"
    }
    if (-not($WPF_UI_ScreenMode_Dropdown.SelectedItem)) {
        $ErrorMessage += 'You have not populated a sceenmode'+"`n"
    }
    if (-not($Script:ROMPath )) {
        $ErrorMessage += 'You have not populated a Rom Path'+"`n"
    }
    if ($Script:SetDiskupOnly -ne 'TRUE'){
        if (-not($Script:ADFPath )) {
            $ErrorMessage += 'You have not populated an ADF Path'+"`n"
        }          
    }
    return $ErrorMessage
}


Function Get-FormVariables{
    if ($Script:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$Script:ReadmeDisplay=$true}
#    write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable WPF*
    }

    function Get-FolderPath {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
            [string]$Message = "Please select a directory.",
    
            [Parameter(Mandatory=$false, Position=1)]
            [string]$InitialDirectory,
    
            [Parameter(Mandatory=$false)]
            [System.Environment+SpecialFolder]$RootFolder = [System.Environment+SpecialFolder]::Desktop,
    
            [switch]$ShowNewFolderButton
        )
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description  = $Message
        $dialog.SelectedPath = $InitialDirectory
        $dialog.RootFolder   = $RootFolder
        $dialog.ShowNewFolderButton = if ($ShowNewFolderButton) { $true } else { $false }
        $selected = $null
    
        # force the dialog TopMost
        # Since the owning window will not be used after the dialog has been 
        # closed we can just create a new form on the fly within the method call
        $result = $dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
        if ($result -eq [Windows.Forms.DialogResult]::OK){
            $selected = $dialog.SelectedPath
        }
        # clear the FolderBrowserDialog from memory
        $dialog.Dispose()
        # return the selected folder
        $selected
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
            $RemovableMediaList += [PSCustomObject]@{
                DeviceID = $_.DeviceID
                Model = $_.Model
                SizeofDisk = $_.Size/1024 # KiB
                EnglishSize = ([math]::Round($_.Size/1GB,3).ToString())
                FriendlyName = 'Disk '+$DriveNumber+' '+$_.Model+' '+([math]::Round($_.Size/1GB,3).ToString()+' GiB') 
                HSTDiskName = ('\disk'+$DriveNumber)
            }
        
        }
        return $RemovableMediaList
    }
  
### Functions

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
        try {
            Invoke-WebRequest $URL -OutFile ($LocationforDL+$NameofDL) # Powershell 5 compatibility -AllowInsecureRedirect
            Write-InformationMessage -Message 'Download completed'
            return $true       
        }
        catch {
            Write-ErrorMessage -Message ('Error downloading '+$NameofDL+'!')
            return $false
        }        
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
        Write-InformationMessage -Message ('Adding partition '+$DeviceName+' '+$DosType)
        & $HSTImagePathtouse rdb part add $DestinationPath $DeviceName $DosType $SizeofPartition $Options --mask 0x7ffffffe --buffers 300 --max-transfer 0xffffff >$Logoutput
    }
    elseif ($Command -eq 'rdb part format'){
        Write-InformationMessage -Message ('Formatting partition '+$VolumeName)
        & $HSTImagePathtouse rdb part format $DestinationPath $PartitionNumber $VolumeName $Options >$Logoutput            
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

function Write-Image {
    param (
        $HSTImagePathtouse,
        $SourcePath,
        $DestinationPath
    )
    $arguments ='write "{0}" {1}' -f $SourcePath,$DestinationPath
    Write-InformationMessage -Message 'Opening new window to write image. Please wait for this to finish!'
    Start-Process -FilePath $HSTImagePathtouse -ArgumentList $arguments
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
        $Sort_Flag
    )
    if(Test-Path $LocationforProgram){
        Write-InformationMessage -Message 'File already exists!'
        return $true   
    }
    else{
        Write-InformationMessage -Message 'Retrieving Github information'
        try {
            $GithubDetails = (Invoke-WebRequest $GithubRelease | ConvertFrom-Json)            
        }
        catch {
            Write-ErrorMessage -Message ('Error downloading '+$NameofDL+'!')
            return $false
        }
        if ($Sort_Flag -eq 'Sort'){
            $GithubDetails_2 = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name } | Sort-Object -Property updated_at -Descending
        }
        else{
            $GithubDetails_2 = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }
        }
        $GithubDownloadURL =$GithubDetails_2[0].browser_download_url 
        Write-InformationMessage -Message ('Downloading Files for URL: '+$GithubDownloadURL)
        try {
            Invoke-WebRequest $GithubDownloadURL -OutFile $LocationforDownload # Powershell 5 compatibility -AllowInsecureRedirect
            Write-InformationMessage -Message 'Download completed'            
        }
        catch {
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
    $KickstartHashestoFind =Import-Csv $PathtoKickstartHashes -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Sort-Object -Property 'Sequence'   
    $ListofKickstartFilestoCheck = Get-ChildItem $PathtoKickstartFiles -force -Recurse | Where-Object { $_.PSIsContainer -eq $false } 
    
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
        else{
            $FoundKickstarts += [PSCustomObject]@{
                Kickstart_Version = $KickstartRomandHash.Kickstart_Version
                FriendlyName= $KickstartRomandHash.FriendlyName
                Sequence = $KickstartRomandHash.Sequence 
                Fat32Name = $KickstartRomandHash.Fat32Name
                KickstartPath = ""
            }        
        }
    }
    
    if ($FoundKickstarts){
        $KickstarttoUse = $FoundKickstarts | Sort-Object -Property 'Sequence' | Select-Object -first 1
        return $KickstarttoUse 
    }
    else{
        Write-ErrorMessage -Message 'No valid Kickstart file found!'
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
    
    Write-InformationMessage -Message ('Calculating hashes of ADFs in location '+$PathtoADFFiles)
    $ListofADFFilestoCheck = Get-ChildItem $PathtoADFFiles -force -Recurse | Where-Object { $_.PSIsContainer -eq $false } | Get-FileHash  -Algorithm MD5
    Write-InformationMessage -Message  ('Hashes calculated!')
    $ADFHashestoFind = Import-Csv $PathtoADFHashes -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Sort-Object -Property 'Sequence'
    $RequiredADFs = Import-Csv $PathtoListofInstallFiles -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Sort-Object -Property 'Sequence'
    $UniqueRequiredADFs = $RequiredADFs | Select-Object FriendlyName -Unique
    
    $HashTableforADFFilestoCheck = @{} # Clear Hash
    
    $MatchedADFs = [System.Collections.Generic.List[PSCustomObject]]::New()
    
    foreach ($ADFDetailLine in $ADFHashestoFind){
        $HashTableforADFFilestoCheck += @{
            $ADFDetailLine.Hash=$ADFDetailLine.ADF_Name,$ADFDetailLine.FriendlyName    
        }
    }
    
    foreach ($ADFLine in $ListofADFFilestoCheck){
        if ($HashTableforADFFilestoCheck[$ADFLine.Hash]){
            $MatchedADFs += [PSCustomObject]@{
                PathtoADF= $ADFLine.Path
                Hash = $ADFLine.Hash
                ADF_Name = $HashTableforADFFilestoCheck[$ADFLine.Hash][0]
                FriendlyName = $HashTableforADFFilestoCheck[$ADFLine.Hash][1]
            }
        }
    }
    
    $UniqueAvailableADFs = $MatchedADFs.FriendlyName | Get-Unique 
    
    $ErrorCount=0
          
    foreach ($RequiredADF in $UniqueRequiredADFs){
        $ADFFound=$false
        foreach ($AvailableADF in $UniqueAvailableADFs){
            if ($RequiredADF.FriendlyName -eq $AvailableADF){
                $ADFFound=$true
            }
        }
        if ($ADFFound -eq  $true){
            Write-InformationMessage -Message ('Found ADF file: '+$RequiredADF.FriendlyName)
        }
        if ($ADFFound -eq  $false){
            Write-ErrorMessage -Message ('ADF file: '+$RequiredADF.FriendlyName+' is missing from directory and/or hash is invalid Please check file!')
            $ErrorCount +=1
        }
    } 
    
    if ($ErrorCount -gt 0){
        return
     }
    else{
        return $MatchedADFs 
    }
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

function Test-ExistenceofFiles {
    param (
        $PathtoTest,
        $PathType
    )
    if (-not (Test-Path $PathtoTest)){
        Write-ErrorMessage -Message ('Error! '+$PathtoTest+' is not available! Please check your download of the tool!')
        return 1 
    }
    else{
        Write-InformationMessage -Message ($PathtoTest+' is available!')
        return 0
    }
}

### End Functions

######################################################################### End Functions #############################################################################################################

####################################################################### End Check Runtime Environment ###############################################################################################

####################################################################### Set Script Path dependent  Variables ########################################################################################

$SourceProgramPath = ($Scriptpath+'Programs\')
$InputFolder = ($Scriptpath+'InputFiles\')
$LocationofAmigaFiles = ($Scriptpath+'AmigaFiles\')

####################################################################### End Script Path dependent  Variables ########################################################################################

####################################################################### Null out Global Variables ###################################################################################################

#Get-Variable > variables.txt

$Script:ExitType = $null
$Script:HSTDiskName = $null
$Script:ScreenModetoUse = $null
$Script:KickstartVersiontoUse = $null
$Script:SSID = $null
$Script:WifiPassword = $null
$Script:SizeofFAT32 = $null
$Script:SizeofImage = $null
$Script:SizeofImage_HST = $null
$Script:SizeofPartition_System = $null
$Script:SizeofPartition_Other = $null
$Script:WorkingPath = $null
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
$Script:WriteImage = $null
$Script:TotalSections = $null
$Script:CurrentSection = $null
$Script:SetDiskupOnly = $null
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

####################################################################### End Null out Global Variables ###############################################################################################
 
 ####################################################################### Set Global Variables ###############################################################################################
 
 $Script:PFSLimit = 101*1024*1024 #Kilobytes

 ####################################################################### End Set Global Variables ###############################################################################################
 

####################################################################### Add GUI Types ################################################################################################################

#[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

####################################################################### End GUI Types ################################################################################################################

####################################################################### GUI XML for Main Environment ##################################################################################################

$inputXML_UserInterface = @"
<Window x:Name="MainWindow" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
           Title="Emu68 Imager" Height="600" Width="910" HorizontalAlignment="Left" VerticalAlignment="Top" ResizeMode="NoResize">
   <Grid Background="#FFE5E5E5" >
      <GroupBox x:Name="DiskSetup_GroupBox" Header="Disk Setup" VerticalAlignment="Top" Height="153" Background="Transparent" HorizontalAlignment="Center">
          <Grid Background="Transparent">
              <Grid x:Name="DiskPartition_Grid" Background="Transparent" Height="30" Width="903" MaxWidth="903" VerticalAlignment="Center">
                  <Grid.RowDefinitions>
                      <RowDefinition Height="30"/>
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
                      <ListViewItem x:Name="FAT32Size_ListViewItem" Content="FAT32" Height="30" Width="Auto" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
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
                      <ListViewItem x:Name="WorkbenchSize_ListViewItem" Content="Workbench" Height="30" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
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
                      <ListViewItem x:Name="WorkSize_ListViewItem" Content="Work" Height="30" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
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
                      <ListViewItem x:Name="FreeSpace_ListViewItem" Content="Free Space" Height="30" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
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
                        <ListViewItem x:Name="Unallocated_ListViewItem" Content="Not Used" Height="30" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </ListView>
              </Grid>

                <TextBox x:Name="Fat32Size_Label" HorizontalAlignment="Left" Margin="36,84,0,0" TextWrapping="Wrap" Text="FAT32 (GiB)" VerticalAlignment="Top" Width="82" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="WorkbenchSize_Label" HorizontalAlignment="Left" Margin="167,84,0,0" TextWrapping="Wrap" Text="Workbench (GiB)" VerticalAlignment="Top" Width="113" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="WorkSize_Label" HorizontalAlignment="Left" Margin="309,84,0,0" TextWrapping="Wrap" Text="Work (GiB)" VerticalAlignment="Top" Width="63" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="WorkSizeNote_Label" HorizontalAlignment="Left" Margin="279,85,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="16" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontSize="17" />
                <TextBox x:Name="Unallocated_Label" HorizontalAlignment="Left" Margin="771,84,0,0" TextWrapping="Wrap" Text="Not Used (GiB)" VerticalAlignment="Top" Width="105" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="ImageSize_Label" HorizontalAlignment="Left" Margin="540,84,0,0" TextWrapping="Wrap" Text="Total Image Size (GiB)" VerticalAlignment="Top" Width="144" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="FreeSpace_Label" HorizontalAlignment="Left" Margin="424,84,0,0" TextWrapping="Wrap" Text="Free Space (GiB)" VerticalAlignment="Top" Width="108" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

                <TextBox x:Name="FAT32Size_Value" Text="" HorizontalAlignment="Left" Margin="20,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                <TextBox x:Name="WorkbenchSize_Value" Text="" HorizontalAlignment="Left" Margin="162,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                <TextBox x:Name="WorkSize_Value" Text="" HorizontalAlignment="Left" Margin="278,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                <TextBox x:Name="Unallocated_Value" Text="0" HorizontalAlignment="Left" Margin="780,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" BorderBrush="Transparent"/>
                <TextBox x:Name="ImageSize_Value" Text="" HorizontalAlignment="Left" Margin="551,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
                <TextBox x:Name="FreeSpace_Value" Text="" HorizontalAlignment="Left" Margin="416,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>

                <Rectangle x:Name="Fat32_Key" HorizontalAlignment="Left" Height="10" Margin="22,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FF3B67A2" />
                <Rectangle x:Name="Workbench_Key" HorizontalAlignment="Left" Height="10" Margin="154,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FFFFA997"  />
                <Rectangle x:Name="Work_Key" HorizontalAlignment="Left" Height="10" Margin="295,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FFAA907C"  />
                <Rectangle x:Name="FreeSpace_Key" HorizontalAlignment="Left" Height="10" Margin="409,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FF7B7B7B" />
                <Rectangle x:Name="Unallocated_Key" HorizontalAlignment="Left" Height="10" Margin="756,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FFAFAFAF"  />
              
              <TextBox x:Name="MediaSelect_Label" HorizontalAlignment="Left" Margin="10,10,0,0" TextWrapping="Wrap" Text="Select Media to Use" VerticalAlignment="Top" Width="120" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
              <ComboBox x:Name="MediaSelect_DropDown"  HorizontalAlignment="Left" Margin="130,8,0,0" VerticalAlignment="Top" Width="340"/>
              <Button x:Name="MediaSelect_Refresh" Content="Refresh Available Media" HorizontalAlignment="Left" Margin="482,9,0,0" VerticalAlignment="Top" Width="130" Height="20"/>
              <Button x:Name="DefaultAllocation_Refresh" Content="Reset Partitions to Default" HorizontalAlignment="Left" Margin="725,9,0,0" VerticalAlignment="Top" Width="157" Height="20"/>
          </Grid>
      </GroupBox>
      <GroupBox x:Name="SourceFiles_GroupBox" Header="Source Files" Height="200" Background="Transparent" Margin="7,156,0,128" Width="400" VerticalAlignment="Top" HorizontalAlignment="Left">
          <Grid Background="Transparent" HorizontalAlignment="Left" VerticalAlignment="Top">
              <ComboBox x:Name="KickstartVersion_DropDown" HorizontalAlignment="Left" Margin="10,32,0,0" VerticalAlignment="Top" Width="200"/>
              <Button x:Name="ADFpath_Button" Content="Click to set ADF path" HorizontalAlignment="Left" Margin="10,94,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
              <TextBox x:Name="ADFPath_Label" HorizontalAlignment="Left" Margin="223,100,0,0" TextWrapping="Wrap" Text="No ADF path selected" VerticalAlignment="Top" Width="200" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
              <TextBox x:Name="ROMPath_Label" HorizontalAlignment="Left" Margin="223,65,0,0" TextWrapping="Wrap" Text="No Kickstart path selected" VerticalAlignment="Top" Width="200" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
              <Button x:Name="Rompath_Button" Content="Click to set Kickstart path" HorizontalAlignment="Left" Margin="10,59,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
              <Button x:Name="MigratedFiles_Button" Content="Click to set Transfer path" HorizontalAlignment="Left" Margin="10,129,0,0" VerticalAlignment="Top"  Width="200" Height="30"/>
              <TextBox x:Name="MigratedPath_Label" HorizontalAlignment="Left" Margin="223,139,0,0" TextWrapping="Wrap" Text="No transfer path selected" VerticalAlignment="Top" Width="200" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
              <TextBox x:Name="KickstartVersion_Label" HorizontalAlignment="Left" Margin="10,10,0,0" TextWrapping="Wrap" Text="Select OS Version" VerticalAlignment="Top" Width="200" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center"/>

          </Grid>
      </GroupBox>
      <GroupBox x:Name="Settings_GroupBox" Header="Settings" Height="150" Background="Transparent" Margin="0,156,7,128" Width="400" VerticalAlignment="Top" HorizontalAlignment="Right">
          <Grid>
              <ComboBox x:Name="ScreenMode_Dropdown" HorizontalAlignment="Left" Margin="10,26,0,0" VerticalAlignment="Top" Width="300"/>
              <TextBox x:Name="ScreenMode_Label" HorizontalAlignment="Left" Margin="10,3,0,0" TextWrapping="Wrap" Text="Select ScreenMode" VerticalAlignment="Top" Width="300" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center"/>
              <TextBox x:Name="SSID_Label" HorizontalAlignment="Left" Margin="12,71,0,0" TextWrapping="Wrap" Text="Enter your SSID" VerticalAlignment="Top" Width="150" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
              <TextBox x:Name="Password_Label" HorizontalAlignment="Left" Margin="6,94,0,0" TextWrapping="Wrap" Text="Enter your Wifi password"  VerticalAlignment="Top" Width="150" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Center"/>
              <TextBox x:Name="SSID_Textbox" HorizontalAlignment="Left" Margin="187,71,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120"/>
              <TextBox x:Name="Password_Textbox" HorizontalAlignment="Left" Margin="187,94,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120"/>

          </Grid>

      </GroupBox>
      <GroupBox x:Name="RunOptions_GroupBox" Header="Run Options" Margin="7,365,0,100" Background="Transparent" HorizontalAlignment="Left" Width="400" VerticalAlignment="Top" >
          <Grid Background="Transparent" >
              <CheckBox x:Name="DiskWrite_CheckBox" Content="Do not write to disk. Produce .img file only" HorizontalAlignment="Left" Margin="2,29,0,0" VerticalAlignment="Top"/>
              <CheckBox x:Name="NoFileInstall_CheckBox" Content="Only set disk up. Do not install packages" HorizontalAlignment="Left" Margin="2,6,0,0" VerticalAlignment="Top"/>
          </Grid>
      </GroupBox>
      <Button x:Name="Start_Button" Content="Run Tool" HorizontalAlignment="Center" Margin="0,489,0,0" VerticalAlignment="Top" Width="880" Height="38" Background = "Red" Foreground="Black" BorderBrush="Transparent"/>
      <GroupBox x:Name="Space_GroupBox" Header="Space Requirements" Height="150" Background="Transparent" Margin="0,311,10,0" Width="400" VerticalAlignment="Top" HorizontalAlignment="Right">
          <Grid>

    
                <TextBox x:Name="RequiredSpace_TextBox" HorizontalAlignment="Left" Margin="20,82,0,0" TextWrapping="Wrap" Text="Space to run tool is:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="RequiredSpaceValue_TextBox" HorizontalAlignment="Left" Margin="288,82,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                <TextBox x:Name="AvailableSpace_TextBox" HorizontalAlignment="Left" Margin="20,102,0,0" TextWrapping="Wrap" Text="Free space after tool is run:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontWeight="Bold"/>
                <TextBox x:Name="AvailableSpaceValue_TextBox" HorizontalAlignment="Right" Margin="0,102,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Green" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                <TextBox x:Name="RequiredSpaceTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="20,28,0,0" TextWrapping="Wrap" Text="Space for transferred files:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="RequiredSpaceValueTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="288,28,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>
                <TextBox x:Name="AvailableSpaceTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="20,49,0,0" TextWrapping="Wrap" Text="Free space is:" VerticalAlignment="Top" Width="230" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" FontWeight="Bold"/>
                <TextBox x:Name="AvailableSpaceValueTransferredFiles_TextBox" HorizontalAlignment="Right" Margin="281,49,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" HorizontalContentAlignment="Right"/>

          </Grid>

      </GroupBox>
      <TextBox x:Name="WorkSizeNoteFooter_Label" HorizontalAlignment="Left" Margin="15,466,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="608" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
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

#Width of bar

$Script:PartitionBarWidth =  857
$Script:SetDiskupOnly = 'FALSE'
$DefaultDivisorFat32 = 15
$DefaultDivisorWorkbench = 15
$Script:Fat32DefaultMaximum = 1024*1024 #1gb in Kilobytes
#$Script:WorkbenchMaximum = 1024*1024 #1gb in Kilobytes
$Script:WorkbenchDefaultMaximum = 1024*1024 #1gb in Kilobytes
$Script:WorkbenchMaximum = $Script:PFSLimit
$Script:Fat32Maximum = 4*1024*1024 # in Kilobytes
$Script:Fat32Minimum = 35840 # In KiB
$Script:WorkbenchMinimum = 100*1024 # In KiB
$Script:WorkMinimum = 10*1024 # In KiB

$Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Scriptpath)/1Kb # Available Space on Drive where script is running (Kilobytes)
$Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk
$Script:RequiredSpace_WorkingFolderDisk = 0 #In Kilobytes

$Script:Space_FilestoTransfer = 0 #In Kilobytes
$Script:WorkOverhead = 1024 #In Kilobytes
$Script:AvailableSpaceFilestoTransfer = 0 #In Kilobytes
$Script:SizeofFilestoTransfer = 0 #In Kilobytes

$Script:SpaceThreshold_WorkingFolderDisk = 500*1024 #In Kilobytes
$Script:SpaceThreshold_FilestoTransfer = 10*1024 #In Kilobytes

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
                $Script:PartitionBarPixelperKB = ($PartitionBarWidth)/$Disk.SizeofDisk
                $Script:PartitionBarKBperPixel = $Disk.SizeofDisk/($PartitionBarWidth)
                break
            }

        }
    
        $Script:SizeofDisk = $Disk.SizeofDisk
        $Script:SizeofImage = $Script:SizeofDisk

        $Script:SizeofFat32_Pixels_Minimum = $Script:PartitionBarPixelperKB * $Script:Fat32Minimum 
        $Script:SizeofPartition_System_Pixels_Minimum = $Script:PartitionBarPixelperKB * $Script:WorkbenchMinimum
        $Script:SizeofPartition_Other_Pixels_Minimum = $Script:PartitionBarPixelperKB * $Script:WorkMinimum

        $Script:SizeofFreeSpace_Pixels_Minimum = 0
        $Script:SizeofFreeSpace_Minimum = 0

        $Script:SizeofUnallocated_Pixels_Minimum = 0
        $Script:SizeofUnallocated_Minimum = 0

        if ($Script:SizeofImage /$DefaultDivisorFat32 -ge $Script:Fat32DefaultMaximum){
            $Script:SizeofFAT32 = $Script:Fat32DefaultMaximum
            $Script:SizeofFAT32_Pixels = $Script:PartitionBarPixelperKB * $Script:SizeofFAT32   
        }
        else{
            $Script:SizeofFAT32 = $Script:SizeofImage/$DefaultDivisorFat32
            $Script:SizeofFAT32_Pixels = $Script:PartitionBarPixelperKB * $Script:SizeofFAT32   
        }

        if ($Script:SizeofImage/$DefaultDivisorWorkbench -ge $Script:WorkbenchDefaultMaximum){
            $Script:SizeofPartition_System = $Script:WorkbenchDefaultMaximum 
            $Script:SizeofPartition_System_Pixels = $Script:SizeofPartition_System * $Script:PartitionBarPixelperKB 
        }
        else{
            $Script:SizeofPartition_System = $Script:SizeofImage/$DefaultDivisorWorkbench
            $Script:SizeofPartition_System_Pixels = $Script:SizeofPartition_System * $Script:PartitionBarPixelperKB 
        }

        $Script:SizeofPartition_Other = ($Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32)
        $Script:SizeofPartition_Other_Pixels = $Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB

        $Script:SizeofUnallocated = $Script:SizeofDisk-$Script:SizeofImage
        $Script:SizeofUnallocated_Pixels = $Script:SizeofUnallocated * $Script:PartitionBarPixelperKB

        $Script:SizeofFreeSpace = $Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32-$Script:SizeofPartition_Other
        $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
        
        Set-PartitionMaximums
        
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
        
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }
        
        Set-GUIPartitionValues

    }
})
   
$WPF_UI_DefaultAllocation_Refresh.add_Click({
        if (($null -ne $Script:HSTDiskName)  -and ($Script:HSTDiskName -eq ('\'+(($WPF_UI_MediaSelect_DropDown.SelectedItem).Split(' ',3)[0])+(($WPF_UI_MediaSelect_DropDown.SelectedItem).Split(' ',3)[1])))){
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = '1'
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = '1'
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = '1'
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = '1'
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = '1'

        $Script:SizeofFat32_Pixels_Minimum = $Script:PartitionBarPixelperKB * $Script:Fat32Minimum 
        $Script:SizeofPartition_System_Pixels_Minimum = $Script:PartitionBarPixelperKB * $Script:WorkbenchMinimum
        $Script:SizeofPartition_Other_Pixels_Minimum = $Script:PartitionBarPixelperKB * $Script:WorkMinimum
    
        $Script:SizeofFreeSpace_Pixels_Minimum = 0
        $Script:SizeofFreeSpace_Minimum = 0
    
        $Script:SizeofUnallocated_Pixels_Minimum = 0
        $Script:SizeofUnallocated_Minimum = 0
    
        $Script:SizeofImage=$Script:SizeofDisk
        if ($Script:SizeofImage /$DefaultDivisorFat32 -ge $Fat32DefaultMaximum){
            $Script:SizeofFAT32 = $Fat32DefaultMaximum
            $Script:SizeofFAT32_Pixels = $Script:PartitionBarPixelperKB * $Script:SizeofFAT32   
        }
        else{
            $Script:SizeofFAT32 = $Script:SizeofImage/$DefaultDivisorFat32
            $Script:SizeofFAT32_Pixels = $Script:PartitionBarPixelperKB * $Script:SizeofFAT32   
        }
    
        if ($Script:SizeofImage/$DefaultDivisorWorkbench -ge $Script:WorkbenchDefaultMaximum){
            $Script:SizeofPartition_System = $Script:WorkbenchDefaultMaximum 
            $Script:SizeofPartition_System_Pixels = $Script:SizeofPartition_System * $Script:PartitionBarPixelperKB 
        }
        else{
            $Script:SizeofPartition_System = $Script:SizeofImage/$DefaultDivisorWorkbench
            $Script:SizeofPartition_System_Pixels = $Script:SizeofPartition_System * $Script:PartitionBarPixelperKB 
        }
    
        $Script:SizeofPartition_Other = ($Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32)
        $Script:SizeofPartition_Other_Pixels = $Script:SizeofPartition_Other * $Script:PartitionBarPixelperKB
    
        $Script:SizeofUnallocated = $Script:SizeofDisk-$Script:SizeofImage
        $Script:SizeofUnallocated_Pixels = $Script:SizeofUnallocated * $Script:PartitionBarPixelperKB
    
        $Script:SizeofFreeSpace = $Script:SizeofImage-$Script:SizeofPartition_System-$Script:SizeofFAT32-$Script:SizeofPartition_Other
        $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
        
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
        
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }            
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

        if ([math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }      
         
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4)

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)

        $Script:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Script:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Script:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Script:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Script:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Script:SizeofFAT32 = $Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofPartition_System  = $Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel  
        $Script:SizeofPartition_Other = $Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofFreeSpace  = $Script:SizeofFreeSpace_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofUnallocated = $Script:SizeofUnallocated_Pixels * $Script:PartitionBarKBperPixel
        
        $Script:SizeofImage = $Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other + $Script:SizeofFreeSpace      
#       Write-host ('FAT32 Size (Pixels) changed to: '+$Script:SizeofFAT32_Pixels)
        $Script:SizeofFAT32 = $Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel
        #        Write-host ('FAT32 Size (KiB) changed to: '+$Script:SizeofFAT32)
        
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
                
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }        
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

        if ([math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }      

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4)

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)

        $Script:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Script:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Script:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Script:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Script:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Script:SizeofFAT32 = $Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofPartition_System  = $Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel  
        $Script:SizeofPartition_Other = $Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofFreeSpace  = $Script:SizeofFreeSpace_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofUnallocated = $Script:SizeofUnallocated_Pixels * $Script:PartitionBarKBperPixel

        $Script:SizeofImage = $Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other + $Script:SizeofFreeSpace

#        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = Expand-FreeSpace
#        Write-host ('Workbench Size (Pixels) changed to: '+$Script:SizeofPartition_System_Pixels)
        $Script:SizeofPartition_System  = $Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel
 #       Write-host ('Workbench Size (KiB) changed to: '+$Script:SizeofPartition_System)
        
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
        
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }        
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

        if ([math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }       

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value,4)

        
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)   

        $Script:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Script:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Script:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Script:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Script:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Script:SizeofFAT32 = $Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofPartition_System  = $Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel  
        $Script:SizeofPartition_Other = $Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofFreeSpace  = $Script:SizeofFreeSpace_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofUnallocated = $Script:SizeofUnallocated_Pixels * $Script:PartitionBarKBperPixel

        $Script:SizeofImage = $Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other + $Script:SizeofFreeSpace

#        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = Expand-FreeSpace
 #       Write-host ('Work Size (Pixels) changed to: '+$Script:SizeofPartition_Other_Pixels)
        $Script:SizeofPartition_Other = $Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel
  #      Write-host ('Work Size (KiB) changed to: '+$Script:SizeofPartition_Other)
  
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
   
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }        
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
        
        if ([math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                     $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4) -lt 0){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = 0
        }else{
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = [math]::round($Script:PartitionBarWidth-  $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value- `
                                                                                                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value,4)
        }     

        $Script:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Script:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Script:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Script:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Script:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Script:SizeofFAT32 = $Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofPartition_System  = $Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel  
        $Script:SizeofPartition_Other = $Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofFreeSpace  = $Script:SizeofFreeSpace_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofUnallocated = $Script:SizeofUnallocated_Pixels * $Script:PartitionBarKBperPixel

        $Script:SizeofImage = $Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other + $Script:SizeofFreeSpace

   #     Write-host ('Free Space (Pixels) changed to: '+$Script:SizeofFreeSpace_Pixels)
   #     Write-host ('Free Space Size (KiB) changed to: '+$Script:SizeofFreeSpace)

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

        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }        

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

        $Script:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Script:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Script:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Script:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Script:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Script:SizeofFAT32 = $Script:SizeofFAT32_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofPartition_System  = $Script:SizeofPartition_System_Pixels * $Script:PartitionBarKBperPixel  
        $Script:SizeofPartition_Other = $Script:SizeofPartition_Other_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofFreeSpace  = $Script:SizeofFreeSpace_Pixels * $Script:PartitionBarKBperPixel
        $Script:SizeofUnallocated = $Script:SizeofUnallocated_Pixels * $Script:PartitionBarKBperPixel

        $Script:SizeofImage = $Script:SizeofFAT32 + $Script:SizeofPartition_System + $Script:SizeofPartition_Other + $Script:SizeofFreeSpace

     #   Write-host ('Unallocated Space (Pixels) changed to: '+$Script:SizeofUnallocated_Pixels)
       # Write-host ('Unallocated (KiB) changed to: '+$Script:SizeofUnallocated)

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
        
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk

        $Script:Space_FilestoTransfer = $Script:SizeofPartition_Other - $Script:WorkOverhead
        $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer    
        
        if ($Script:TransferLocation){
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 
        }        
    }
})

$WPF_UI_MediaSelect_Refresh.Add_Click({
    $Script:HSTDiskName = $null
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


$WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Add_TextChanged({
    if ($WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.text -eq ''){
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Transparent"
    }
    elseif (($Script:AvailableSpaceFilestoTransfer - $Script:SizeofFilestoTransfer ) -lt $Script:SpaceThreshold_FilestoTransfer){
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Red"
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Foreground = "Black"
    }
    elseif (($Script:AvailableSpaceFilestoTransfer - $Script:SizeofFilestoTransfer ) -lt ($Script:SpaceThreshold_FilestoTransfer*2)){
    $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Yellow"
    $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Foreground = "Black"
    }
    else{
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Green"
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Foreground = "White"
    }
    
})


$WPF_UI_AvailableSpaceValue_TextBox.Add_TextChanged({
    if ($Script:AvailableSpace_WorkingFolderDisk -le ($Script:SpaceThreshold_WorkingFolderDisk*2)){
        $WPF_UI_AvailableSpaceValue_TextBox.Background = "Yellow"
        $WPF_UI_AvailableSpaceValue_TextBox.Foreground = "Black"
    }
    elseif ($Script:AvailableSpace_WorkingFolderDisk -le $Script:SpaceThreshold_WorkingFolderDisk){
        $WPF_UI_AvailableSpaceValue_TextBox.Background = "Red"
        $WPF_UI_AvailableSpaceValue_TextBox.Foreground = "Black"
    }
    else{
        $WPF_UI_AvailableSpaceValue_TextBox.Background = "Green"
        $WPF_UI_AvailableSpaceValue_TextBox.Foreground = "White"
    }
    
})


$WPF_UI_FAT32Size_Value.add_LostFocus({
    if (-not ($WPF_UI_FAT32Size_Value.Text -match "^[\d\.]+$")){
        $WPF_UI_FAT32Size_Value.Background = 'Red'
    }   
    elseif ($WPF_UI_FAT32Size_Value.Text -eq $Script:UI_FAT32Size_Value){
        $WPF_UI_FAT32Size_Value.Background = 'White'
    }     
    elseif (((([Double]$WPF_UI_FAT32Size_Value.Text)*1024*1024) -lt $Script:FAT32Maximum) -and ((([Double]$WPF_UI_FAT32Size_Value.Text)*1024*1024) -gt $Script:FAT32Minimum)){
        $ValueDifference = ([double]$WPF_UI_FAT32Size_Value.Text*1024*1024-$Script:SizeofFAT32) 
        $FreeSpaceDifference = $Script:SizeofFreeSpace-$ValueDifference
        if ($FreeSpaceDifference -ge 0){
            $Script:SizeofFreeSpace -= $ValueDifference 
            $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
            $Script:SizeofFAT32 = [double]$WPF_UI_FAT32Size_Value.Text*1024*1024
            $Script:SizeofFAT32_Pixels = $Script:SizeofFAT32 * $Script:PartitionBarPixelperKB
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels 
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Script:SizeofFAT32_Pixels
            $WPF_UI_FAT32Size_Value.Background = 'White'
            $Script:UI_FAT32Size_Value=$WPF_UI_FAT32Size_Value.Text                
        }
        else{
            $WPF_UI_FAT32Size_Value.Background = 'Red'
        }
    }
    else{
        $WPF_UI_FAT32Size_Value.Background = 'Red'
    }
})

$WPF_UI_WorkbenchSize_Value.add_LostFocus({
    if (-not ($WPF_UI_WorkbenchSize_Value.Text -match "^[\d\.]+$")){
        $WPF_UI_WorkbenchSize_Value.Background = 'Red'
    }
    elseif ($WPF_UI_WorkbenchSize_Value.Text -eq $Script:UI_WorkbenchSize_Value){
        $WPF_UI_WorkbenchSize_Value.Background = 'White'
    } 
    elseif (((([double]$WPF_UI_WorkbenchSize_Value.Text)*1024*1024) -lt $Script:WorkbenchMaximum) -and ((([double]$WPF_UI_WorkbenchSize_Value.Text)*1024*1024) -gt $Script:WorkbenchMinimum)){
        $ValueDifference = ([double]$WPF_UI_WorkbenchSize_Value.Text*1024*1024-$Script:SizeofPartition_System) 
        $FreeSpaceDifference = $Script:SizeofFreeSpace-$ValueDifference
        if ($FreeSpaceDifference -ge 0){
            $Script:SizeofFreeSpace -= $ValueDifference 
            $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
            $Script:SizeofPartition_System= [double]$WPF_UI_WorkbenchSize_Value.Text*1024*1024
            $Script:SizeofPartition_System_Pixels = $Script:SizeofPartition_System* $Script:PartitionBarPixelperKB
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels 
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Script:SizeofPartition_System_Pixels
            $WPF_UI_WorkbenchSize_Value.Background = 'White'   
            $Script:UI_WorkbenchSize_Value= $WPF_UI_WorkbenchSize_Value.Text
        }
    }    
    else {
        $WPF_UI_WorkbenchSize_Value.Background = 'Red'
    }
})
 

$WPF_UI_WorkSize_Value.add_LostFocus({
    if (-not ($WPF_UI_WorkSize_Value.Text -match "^[\d\.]+$")){
        $WPF_UI_WorkSize_Value.Background = 'Red'
    }
    elseif ($WPF_UI_WorkSize_Value.Text -eq $Script:UI_WorkSize_Value){
        $WPF_UI_WorkSize_Value.Background = 'White'
    } 
    elseif (((([double]$WPF_UI_WorkSize_Value.Text)*1024*1024) -gt $Script:WorkMinimum)){
        $ValueDifference = ([double]$WPF_UI_WorkSize_Value.Text*1024*1024-$Script:SizeofPartition_Other) 
        $FreeSpaceDifference = $Script:SizeofFreeSpace-$ValueDifference
        if ($FreeSpaceDifference -ge 0){
            $Script:SizeofFreeSpace -= $ValueDifference 
            $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
            $Script:SizeofPartition_Other= [double]$WPF_UI_WorkSize_Value.Text*1024*1024
            $Script:SizeofPartition_Other_Pixels = $Script:SizeofPartition_Other* $Script:PartitionBarPixelperKB
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels 
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Script:SizeofPartition_Other_Pixels
            $WPF_UI_WorkSize_Value.Background = 'White'
            $Script:UI_WorkSize_Value= $WPF_UI_WorkSize_Value.Text    
        }
    }    
    else {
        $WPF_UI_WorkSize_Value.Background = 'Red'
    }
})

$WPF_UI_FreeSpace_Value.add_LostFocus({
        if (-not ($WPF_UI_FreeSpace_Value.Text -match "^[\d\.]+$")){
            $WPF_UI_FreeSpace_Value.Background = 'Red'
        }
        elseif ($WPF_UI_FreeSpace_Value.Text -eq $Script:UI_FreeSpace_Value){
            $WPF_UI_FreeSpace_Value.Background = 'White'
        } 
        else{
            $ValueDifference = ([double]$WPF_UI_FreeSpace_Value.Text*1024*1024-$Script:SizeofFreeSpace)
       #     Write-Host "Difference in value for FreeSpace is: $ValueDifference"
            if ($ValueDifference -lt 0){ 
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofUnallocated_Pixels = $Script:SizeofUnallocated * $Script:PartitionBarPixelperKB
                $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels  
                $Script:UI_FreeSpace_Value= $WPF_UI_FreeSpace_Value.Text
            }
            elseif($ValueDifference -gt 0 -and ($Script:SizeofUnallocated - $ValueDifference) -gt 0){
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofUnallocated_Pixels = $Script:SizeofUnallocated * $Script:PartitionBarPixelperKB
                $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels  
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels  
                $Script:UI_FreeSpace_Value= $WPF_UI_FreeSpace_Value.Text
            }
            else{
                Write-Host $WPF_UI_FreeSpace_Value.Text 
                Write-Host $UI_FreeSpace_Value
                Write-host 'Not enough free space for change!'
                write-host $ValueDifference
                $WPF_UI_FreeSpace_Value.Background = 'Red'
            }
        }
})    

$WPF_UI_ImageSize_Value.add_LostFocus({
        if (-not ($WPF_UI_ImageSize_Value.Text -match "^[\d\.]+$")){
             $WPF_UI_ImageSize_Value.Background = 'Red'
        }
        elseif ($WPF_UI_ImageSize_Value.Text -eq $Script:UI_ImageSize_Value){
            $WPF_UI_ImageSize_Value.Background = 'White'
        }
        else{
            $ValueDifference = ([double]$WPF_UI_ImageSize_Value.Text*1024*1024-$Script:SizeofImage)
            if (($ValueDifference -lt 0) -and ($ValueDifference+$Script:SizeofFreeSpace -gt 0)) {  # We are reducing image and need free space
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
                $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels  
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels  
                $UI_ImageSize_Value = $WPF_UI_ImageSize_Value.Text           
            }
            elseif (($ValueDifference -gt 0) -and ($Script:SizeofUnallocated -$ValueDifference -gt 0)) {  # We are reducing image and need free space    
                $Script:SizeofFreeSpace += $ValueDifference
                $Script:SizeofUnallocated -= $ValueDifference
                $Script:SizeofUnallocated_Pixels = $Script:SizeofUnallocated * $Script:PartitionBarPixelperKB
                $Script:SizeofFreeSpace_Pixels = $Script:SizeofFreeSpace * $Script:PartitionBarPixelperKB
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Script:SizeofUnallocated_Pixels  
                $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Script:SizeofFreeSpace_Pixels
                $UI_ImageSize_Value = $WPF_UI_ImageSize_Value.Text                    
            }
        }       
})

$WPF_UI_Start_Button.Add_Click({
    $Script:SSID = $WPF_UI_SSID_Textbox.Text
    $Script:WifiPassword = $WPF_UI_Password_Textbox.Text
    if ($WPF_UI_DiskWrite_CheckBox.IsChecked){
        $Script:WriteImage ='FALSE'
    }
    else{
        $Script:WriteImage ='TRUE'
    }
    if ($Script:TransferLocation){
        if ($Script:AvailableSpaceFilestoTransfer -lt $Script:SpaceThreshold_FilestoTransfer){
            $Msg = @'
You do not have sufficient space on your Work partition to transfer the files!
            
Select a location with less space, increase the space on Work, or remove the transfer of files
'@
        [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',0,48)
    
        }
    }

    if ($Script:AvailableSpace_WorkingFolderDisk -le $Script:SpaceThreshold_WorkingFolderDisk){
        $Msg = @'
You do not have sufficient space on your drive to run the tool!

Either select a location with sufficient space or press cancel to quit the tool
'@
        $ValueofAction = [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',1,48)
        if ($ValueofAction -eq 'OK'){
            $SufficientSpace_Flag =$null
            do {
                $Script:WorkingPath = Get-FolderPath -Message 'Select location for Working Path' -RootFolder 'MyComputer'-ShowNewFolderButton
                $Script:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Script:WorkingPath)/1kb
                $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
                if ($Script:AvailableSpace_WorkingFolderDisk -le $Script:SpaceThreshold_WorkingFolderDisk){
                    $Msg = @'
You still do not have sufficient space on your drive to run the tool!
                  
Either select a location with sufficient space or press cancel to quit the tool
'@    
                    $ValueofAction = [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',1,48)
                    if ($ValueofAction -eq 'Cancel'){
                        $Form_UserInterface.Close() | out-null
                        $Script:ExitType =2 
                    }    
                }
                else{
                    $SufficientSpace_Flag = $true    
                }
            } until (
                $SufficientSpace_Flag -eq $true
            )        
        }
        elseif ($ValueofAction -eq 'Cancel'){
            $Form_UserInterface.Close() | out-null
            $Script:ExitType =2
        }      
    } 
    else {
        $Script:WorkingPath = ($Scriptpath+'Working Folder\') 
    }
    $ErrorCheck = Confirm-UIFields
    if ($ErrorCheck){
        [System.Windows.MessageBox]::Show($ErrorCheck, 'Error! Go back and correct')
    }
    else {
        $Form_UserInterface.Close() | out-null
        $Script:ExitType = 1
    }
})

$WPF_UI_RomPath_Button.Add_Click({
    $Script:ROMPath = Get-FolderPath -Message 'Select path to Roms' -RootFolder 'MyComputer'
    if ($Script:ROMPath){
        if(Confirm-UIFields){
            $WPF_UI_Start_Button.Background = 'Red'
            $WPF_UI_Start_Button.Foreground = 'Black'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
            $WPF_UI_Start_Button.Foreground = 'White'
        }
        $WPF_UI_RomPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:ROMPath)
        $WPF_UI_RomPath_Button.Background = 'Green'
        $WPF_UI_RomPath_Button.Foreground = 'White'
    }
    else{
        $WPF_UI_RomPath_Label.Text ='No ROM path selected'
        $WPF_UI_RomPath_Button.Background = '#FFDDDDDD'
    }
})

$WPF_UI_ADFPath_Button.Add_Click({
    $Script:ADFPath = Get-FolderPath -Message 'Select path to ADFs' -RootFolder 'MyComputer'
    if ($Script:ADFPath){
        if(Confirm-UIFields){
            $WPF_UI_Start_Button.Background = 'Red'
            $WPF_UI_Start_Button.Foreground = 'Black'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
            $WPF_UI_Start_Button.Foreground = 'White'
        }
        $WPF_UI_ADFPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:ADFPath)
        $WPF_UI_ADFPath_Button.Background = 'Green'
        $WPF_UI_ADFPath_Button.Foreground = 'White'
    } 
    else{
        $WPF_UI_ADFPath_Label.Text = 'No ADF path selected'
        $WPF_UI_ADFPath_Button.Background = '#FFDDDDDD'
        $WPF_UI_ADFPath_Button.Foreground = 'Black'
    }
})

$WPF_UI_MigratedFiles_Button.Add_Click({
    If (-not ($Script:TransferLocation)) {
        $Script:TransferLocation = Get-FolderPath -Message 'Select transfer folder' -RootFolder 'MyComputer'
        if ($Script:TransferLocation){            
           
            $Msg = @'
Calculating space requirements. This may take some time if you have selected a large folder for transfer!
'@
        [System.Windows.MessageBox]::Show($Msg, 'Calculating Space',0,0)            
            $Script:SizeofFilestoTransfer = Get-TransferredFilesSpaceRequired -FoldertoCheck $Script:TransferLocation
            $Script:AvailableSpaceFilestoTransfer =  $Script:Space_FilestoTransfer - $Script:SizeofFilestoTransfer      
            
            $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:SizeofFilestoTransfer
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpaceFilestoTransfer 

            $WPF_UI_MigratedPath_Label.Text = Get-FormattedPathforGUI -PathtoTruncate ($Script:TransferLocation)
            $WPF_UI_MigratedFiles_Button.Content = 'Click to remove Transfer Folder'
            $WPF_UI_MigratedFiles_Button.Background = 'Green'
            $WPF_UI_MigratedFiles_Button.Foreground = 'White' 

        }
        else{
            $Script:SizeofFilestoTransfer = 0
            $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = ''
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = ''
            $WPF_UI_MigratedFiles_Button.Background = '#FFDDDDDD'
            $WPF_UI_MigratedFiles_Button.Foreground = 'Black'
        }
    }
    else{
        $Script:SizeofFilestoTransfer= 0
        $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = ''
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = ''
        $Script:TransferLocation = $null
        $WPF_UI_MigratedFiles_Button.Content = 'Click to set Transfer Folder'
        $WPF_UI_MigratedFiles_Button.Background = '#FFDDDDDD'
        $WPF_UI_MigratedFiles_Button.Foreground = 'Black'
        $WPF_UI_MigratedPath_Label.Text='No transfer path selected'
    }
})

$AvailableKickstarts = Import-Csv ($InputFolder+'ListofInstallFiles.csv') -delimiter ';' | Where-Object 'Kickstart_Version' -ne ""| Select-Object 'Kickstart_Version' -unique

foreach ($Kickstart in $AvailableKickstarts) {
    $WPF_UI_KickstartVersion_Dropdown.AddChild($Kickstart.Kickstart_Version)
}

$WPF_UI_KickstartVersion_Dropdown.Add_SelectionChanged({
    $Script:KickstartVersiontoUse = $WPF_UI_KickstartVersion_Dropdown.SelectedItem
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
        $WPF_UI_Start_Button.Foreground = 'Black'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
        $WPF_UI_Start_Button.Foreground = 'White'
    }
})

$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.csv') -delimiter ';'

foreach ($ScreenMode in $AvailableScreenModes) {
    $WPF_UI_ScreenMode_Dropdown.AddChild($ScreenMode.FriendlyName)
}

$WPF_UI_ScreenMode_Dropdown.Add_SelectionChanged({
    foreach ($ScreenMode in $AvailableScreenModes) {
        if ($ScreenMode.FriendlyName -eq $WPF_UI_ScreenMode_Dropdown.SelectedItem){
            $Script:ScreenModetoUse = $ScreenMode.Name           
        }
    }
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
        $WPF_UI_Start_Button.Foreground = 'Black'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
        $WPF_UI_Start_Button.Foreground = 'White'
    }
})

$WPF_UI_NoFileInstall_CheckBox.Add_Checked({
    $Script:SetDiskupOnly = 'TRUE'
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
        $WPF_UI_Start_Button.Foreground = 'Black'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
        $WPF_UI_Start_Button.Foreground = 'White'
    }
    If ($Script:HSTDiskName){
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk
    } 
})

$WPF_UI_NoFileInstall_CheckBox.Add_UnChecked({
    $Script:SetDiskupOnly = 'FALSE'
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
        $WPF_UI_Start_Button.Foreground = 'Black'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
        $WPF_UI_Start_Button.Foreground = 'White'
    }
    If ($Script:HSTDiskName){
        $Script:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $Script:SizeofImage
        $Script:AvailableSpace_WorkingFolderDisk = $Script:Space_WorkingFolderDisk - $Script:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Script:AvailableSpace_WorkingFolderDisk
    }
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
        Title="Not Run as Administrator" Height="450" Width="800" HorizontalAlignment="Center" HorizontalContentAlignment="Center" UseLayoutRounding="True" ScrollViewer.VerticalScrollBarVisibility="Disabled" ResizeMode="NoResize">
    <Grid>
        <Button x:Name="Button_Acknowledge" Content="Acknowledge" HorizontalAlignment="Left" Margin="259,360,0,0" VerticalAlignment="Top" Width="320"/>
        <TextBox x:Name="TextBox_Message" HorizontalAlignment="Left" Margin="259,167,0,0" TextWrapping="Wrap" Text="You must run the tool in Administrator Mode!" VerticalAlignment="Top" Width="307" IsReadOnly="True"/>        
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
    $IsAdministrator = $false
})

####################################################################### End GUI XML for Test Administrator ##################################################################################################

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


####################################################################### GUI XML for Disclaimer ##################################################################################################

$InputXML_DisclaimerWindow = @"
<Window x:Name="Disclaimer" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp14"
        mc:Ignorable="d"
        Title="Disclaimer" Height="450" Width="800" HorizontalAlignment="Center" HorizontalContentAlignment="Center" UseLayoutRounding="True" ScrollViewer.VerticalScrollBarVisibility="Disabled" ResizeMode="NoResize" WindowStyle="ToolWindow">
    <Grid Margin="0,-10,0,10">
        <Button x:Name="Button_Acknowledge" Content="Acknowledge" HorizontalAlignment="Left" Margin="259,382,0,0" VerticalAlignment="Top" Width="320"/>
        <TextBox x:Name="TextBox_Message" HorizontalAlignment="Left" Margin="259,167,0,0" TextWrapping="Wrap" Text="This might harm your computer if you are a stronzo and don't know what you are doing" VerticalAlignment="Top" Width="307" IsReadOnly="True"/>
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


$Form_Disclaimer.ShowDialog() | out-null

if (-not ($Script:IsDisclaimerAccepted -eq $true)){
    Write-ErrorMessage 'Exiting - Disclaimer Not Accepted'
    exit    
}

####################################################################### End GUI XML for Disclaimer ##################################################################################################

####################################################################### Show Main Gui     ##################################################################################################################

$Form_UserInterface.ShowDialog() | out-null

######################################################################## Command line portion of Script ################################################################################################

if ($Script:ExitType -eq 2){
    Write-ErrorMessage -Message 'Exiting - User has insufficient space'
    exit
}
elseif (-not ($Script:ExitType-eq 1)){
    Write-ErrorMessage -Message 'Exiting - UI Window was closed'
    exit
}


Write-InformationMessage -Message "Running Script to perform selected functions. Options selected are:"
Write-InformationMessage -Message "DiskName to Write: $Script:HSTDiskName"  
Write-InformationMessage -Message "ScreenMode to Use: $Script:ScreenModetoUse"
Write-InformationMessage -Message "Kickstart to Use: $Script:KickstartVersiontoUse" 
Write-InformationMessage -Message "SSID to configure: $Script:SSID" 
Write-InformationMessage -Message "Password to set: $Script:WifiPassword" 
Write-InformationMessage -Message "Fat32 Size (MiB): $Script:SizeofFAT32"
Write-InformationMessage -Message "Image Size (KiB): $Script:SizeofImage"
Write-InformationMessage -Message "Image Size HST (KiB): $Script:SizeofImage_HST"
Write-InformationMessage -Message "Workbench Size: $Script:SizeofPartition_System"
Write-InformationMessage -Message "Work Size: $Script:SizeofPartition_Other"
Write-InformationMessage -Message "Working Path: $Script:WorkingPath"
Write-InformationMessage -Message "Rom Path: $Script:ROMPath"
Write-InformationMessage -Message "ADF Path: $Script:ADFPath" 
Write-InformationMessage -Message "Transfer Location: $Script:TransferLocation"
Write-InformationMessage -Message "Write Image to Disk: $Script:WriteImage"
Write-InformationMessage -Message "Set disk up only: $Script:SetDiskupOnly"

#[System.Windows.Window].GetEvents() | select Name, *Method, EventHandlerType

#[System.Windows.Controls.GridSplitter].GetEvents() | Select-Object Name, *Method, EventHandlerType
#[System.Windows.Controls.ListView].GetEvents() | Select-Object Name, *Method, EventHandlerType
<#
##### Script

$UnLZXURL='http://aminet.net/util/arc/W95unlzx.lha'
$HSTImagerreleases= 'https://api.github.com/repos/henrikstengaard/hst-imager/releases'
$HSTAmigareleases= 'https://api.github.com/repos/henrikstengaard/hst-amiga/releases'
$Emu68releases= 'https://api.github.com/repos/michalsc/Emu68/releases'
$Emu68Toolsreleases= 'https://api.github.com/repos/michalsc/Emu68-tools/releases'

#Generate CSV MD5 Hashes - Begin (To be disabled or removed for production version)
$CSVHashes = Get-FileHash ($InputFolder+'*.CSV') -Algorithm MD5

'Name;Hash' | Out-File -FilePath ($InputFolder+'CSVHASH')
Foreach ($CSVHash in $CSVHashes){
    ((Split-Path $CSVHash.Path -Leaf)+';'+$CSVHash.Hash) | Out-File -FilePath ($InputFolder+'CSVHASH') -Append
}

#Generate CSV MD5 Hashes - End

$Script:TotalSections = 20

$Script:CurrentSection = 1

if (-not ($Script:TransferLocation)){
    $TotalSections --
}
if (-not ($Script:WriteImage)){
    $TotalSections --
}

if ($Script:SetDiskupOnly = 'TRUE'){
    $TotalSections = 6 ## Need to update
}

# Check Integrity of CSVs

$StartDateandTime = (Get-Date -Format HH:mm:ss)

$Script:SizeofImage_HST = $Script:SizeofImage-($Script:SizeofFAT32*1024)

Write-InformationMessage -Message "Starting execution at $StartDateandTime"

Write-StartTaskMessage -Message 'Performing integrity checks over input files'

$CSVHashestoCheck = Import-Csv -Path ($InputFolder+'CSVHASH') -Delimiter ';'
foreach ($CSVHashtoCheck in $CSVHashestoCheck){
    Write-InformationMessage -Message ('Checking integrity of: '+$CSVHashtoCheck.Name)
    foreach ($CSVHash in $CSVHashes){
        if (($CSVHashtoCheck.Name+$CSVHashtoCheck.Hash) -eq ((split-path $CSVHash.Path -leaf)+($CSVHash.Hash))){
            $HashMatch=$true
        }
    }
    if ($HashMatch -eq $false) {
        Write-ErrorMessage -Message 'One or more of input files is missing and/or has been altered!' 
        exit
    }
    else{
        Write-InformationMessage -Message 'File OK!'
    }
}

Write-TaskCompleteMessage -Message 'Performing integrity checks over input files - Complete!'

Write-StartTaskMessage -Message 'Checking existance of folders, programs, and files'

if (((split-path  $Script:WorkingPath  -Parent)+'\') -eq $Scriptpath) {
    Write-InformationMessage -Message ('Creating Working Folder under '+$Scriptpath+' (if it does not exist)')
    if (-not (Test-Path ($Scriptpath+'Working Folder\'))){
        $null = New-Item ($Scriptpath+'Working Folder\') -ItemType Directory
    }
}

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
    Write-ErrorMessage -Message 'One or more Programs is missing and/or has been altered! Cannot Continue!'
    exit
}
else {
    $null = $ErrorCount
    Write-TaskCompleteMessage -Message 'Checking existance of folders, programs, and files - Complete!'
}

$HDF2emu68Path=($SourceProgramPath+'hdf2emu68.exe')
$7zipPath=($SourceProgramPath+'7z.exe')

Set-Location  $Script:WorkingPath

$ProgramsFolder= $Script:WorkingPath+'Programs\'
if (-not (Test-Path $ProgramsFolder)){
    $null = New-Item $ProgramsFolder -ItemType Directory
}

$TempFolder= $Script:WorkingPath+'Temp\'
if (-not (Test-Path $TempFolder)){
    $null = New-Item $TempFolder -ItemType Directory
}

$HSTImagePath=$ProgramsFolder+'HST-Imager\hst.imager.exe'
$HSTAmigaPath=$ProgramsFolder+'HST-Amiga\hst.amiga.exe'
$LZXPath=$ProgramsFolder+'unlzx.exe'

$LocationofImage= $Script:WorkingPath+'OutputImage\'
$AmigaDrivetoCopy= $Script:WorkingPath+'AmigaImageFiles\'
$AmigaDownloads= $Script:WorkingPath+'AmigaDownloads\'
$FAT32Partition= $Script:WorkingPath+'FAT32Partition\'

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

$NameofImage=('Pistorm'+$Script:KickstartVersiontoUse+'.HDF')

### Clean up

Write-StartTaskMessage -Message 'Performing Cleanup'

$NewFolders = ((split-path $TempFolder -leaf),(split-path $LocationofImage -leaf),((Split-Path $AmigaDrivetoCopy -Leaf)+'\'+$VolumeName_System),((Split-Path $AmigaDrivetoCopy -Leaf)+'\'+$VolumeName_Other),(split-path $FAT32Partition -leaf))

try {
    foreach ($NewFolder in $NewFolders) {
        if (Test-Path ( $Script:WorkingPath+$NewFolder)){
            $null = Remove-Item ( $Script:WorkingPath+$NewFolder) -Recurse -ErrorAction Stop
        }
        $null = New-Item -path ( $Script:WorkingPath) -Name $NewFolder -ItemType Directory
    }    
}
catch {
    Write-ErrorMessage -Message "Cannot delete temporary files!"
    exit    
}

if (-not(Test-Path ( $Script:WorkingPath+'AmigaDownloads'))){
    $null = New-Item -path ( $Script:WorkingPath) -Name 'AmigaDownloads' -ItemType Directory    
}

if (-not(Test-Path ( $Script:WorkingPath+'Programs'))){
    $null = New-Item -path ( $Script:WorkingPath) -Name 'Programs' -ItemType Directory      
}

Write-TaskCompleteMessage -Message 'Performing Cleanup - Complete!'

### End Clean up

### Determine Kickstart Rom Path

#Update-OutputWindow -OutputConsole_Title_Text 'Determining Kickstarts to Use' -ProgressbarValue_Overall 7 -ProgressbarValue_Overall_Text '7%'

Write-StartTaskMessage -Message 'Determining Kickstarts to Use'

$FoundKickstarttoUse = Compare-KickstartHashes -PathtoKickstartHashes ($InputFolder+'RomHashes.csv') -PathtoKickstartFiles $Script:ROMPath -KickstartVersion $Script:KickstartVersiontoUse

$KickstartPath = $FoundKickstarttoUse.KickstartPath

if (-not($KickstartPath)){
    Write-ErrorMessage -Message "Error! No Kickstart file found!"
    exit
} 

$KickstartNameFAT32=$FoundKickstarttoUse.Fat32Name

Write-InformationMessage -Message ('Kickstart to be used is: '+$KickstartPath)

Write-TaskCompleteMessage -Message 'Determining Kickstarts to Use - Complete!'

if ($Script:SetDiskupOnly -eq 'FALSE'){

    Write-StartTaskMessage -Message 'Determining ADFs to Use'
    
    $AvailableADFs = Compare-ADFHashes -PathtoADFFiles $Script:ADFPath -PathtoADFHashes ($InputFolder+'ADFHashes.csv') -KickstartVersion $Script:KickstartVersiontoUse -PathtoListofInstallFiles ($InputFolder+'ListofInstallFiles.csv') 
    
    if (-not ($AvailableADFs)){
        Write-ErrorMessage -Message "One or more ADF files is missing!"
        exit
    } 
    
    $ListofInstallFiles = Import-Csv ($InputFolder+'ListofInstallFiles.csv') -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $Script:KickstartVersiontoUse} | Sort-Object -Property 'InstallSequence'
    
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
    
    Write-InformationMessage -Message 'ADF install images to be used are:'
    $ListofInstallFiles |  Select-Object Path,FriendlyName -Unique | ForEach-Object {
        Write-InformationMessage -Message ($_.FriendlyName+' ('+$_.Path+')')
    } 
    
    Write-TaskCompleteMessage -Message 'Determining ADFs to Use - Complete!'

}


### Download HST-Imager and HST-Amiga

Write-StartTaskMessage -Message 'Downloading HST Packages'

Write-StartSubTaskMessage -Message 'Downloading HST Imager'

if (-not(Get-GithubRelease -GithubRelease $HSTImagerreleases -Tag_Name '1.1.350' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTImager.zip') -LocationforProgram ($ProgramsFolder+'HST-Imager\') -Sort_Flag '')){
    Write-ErrorMessage -Message 'Error downloading HST-Imager! Cannot continue!'
    exit
}

if ($Script:SetDiskupOnly -eq 'FALSE'){
    Write-StartSubTaskMessage -Message 'Downloading HST Amiga'
    
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

if (-not(Get-GithubRelease -GithubRelease $Emu68releases -Tag_Name "nightly" -Name 'Emu68-pistorm-' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm\') -Sort_Flag 'SORT')){
    Write-ErrorMessage -Message'Error downloading Emu68Pistorm! Cannot continue!'
    exit
}

Write-StartSubTaskMessage -Message 'Downloading Emu68Pistorm32lite' -SubtaskNumber '2' -TotalSubtasks '3'

if (-not(Get-GithubRelease -GithubRelease $Emu68releases -Tag_Name "nightly" -Name 'Emu68-pistorm32lite' -LocationforDownload ($AmigaDownloads+'Emu68Pistorm32lite.zip') -LocationforProgram ($tempfolder+'Emu68Pistorm32lite\') -Sort_Flag 'SORT')){
    Write-ErrorMessage -Message 'Error downloading Emu68Pistorm32lite! Cannot continue!'
    exit
}

Write-StartSubTaskMessage -Message 'Downloading Emu68Tools' -SubtaskNumber '3' -TotalSubtasks '3'

if (-not(Get-GithubRelease -GithubRelease $Emu68Toolsreleases -Tag_Name "nightly" -Name 'Emu68-tools' -LocationforDownload ($AmigaDownloads+'Emu68Tools.zip') -LocationforProgram ($tempfolder+'Emu68Tools\') -Sort_Flag 'SORT')){
    Write-ErrorMessage -Message 'Error downloading Emu68Tools! Cannot continue!'
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

if (-not (Start-HSTImager -Command "Blank" -DestinationPath ($LocationofImage+$NameofImage) -ImageSize $SizeofImagetouse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 
if (-not (Start-HSTImager -Command "rdb init" -DestinationPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 
if (-not (Start-HSTImager -Command "rdb filesystem add" -DestinationPath ($LocationofImage+$NameofImage) -FileSystemPath ($Script:WorkingPath+'Programs\HST-Imager\pfs3aio') -DosType 'PFS3' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 


## Setting up Amiga Partitions List

$AmigaPartitionsList = Get-AmigaPartitionList   -SizeofPartition_System_param $Script:SizeofPartition_System `
                                                -SizeofPartition_Other_param $Script:SizeofPartition_Other `
                                                -VolumeName_System_param $VolumeName_System `
                                                -DeviceName_System_param $DeviceName_System `
                                                -PFSLimit $Script:PFSLimit  `
                                                -VolumeName_Other_param $VolumeName_Other `
                                                -DeviceName_Other_param $DeviceName_Other `
                                                -DeviceName_Prefix_param $DeviceName_Prefix
                                                
foreach ($AmigaPartition in $AmigaPartitionsList) {
    Write-InformationMessage -Message ('Preparing Partition Device: '+$AmigaPartition.DeviceName+' VolumeName '+$AmigaPartition.VolumeName)
    if ($AmigaPartition.VolumeName -eq $VolumeName_System){
        if (-not (Start-HSTImager -Command "rdb part add" -DestinationPath ($LocationofImage+$NameofImage) -DeviceName $AmigaPartition.DeviceName -DosType $AmigaPartition.DosType -SizeofPartition $AmigaPartition.SizeofPartition -Options '--bootable' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        } 
    }
    else{
        if (-not (Start-HSTImager -Command "rdb part add" -DestinationPath ($LocationofImage+$NameofImage) -DeviceName $AmigaPartition.DeviceName -DosType $AmigaPartition.DosType -SizeofPartition $AmigaPartition.SizeofPartition -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        } 
    }
    if (-not (Start-HSTImager -Command "rdb part format" -DestinationPath ($LocationofImage+$NameofImage) -PartitionNumber $AmigaPartition.PartitionNumber -VolumeName $AmigaPartition.VolumeName -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    } 
}

if ($Script:SetDiskupOnly -eq 'FALSE'){
    #### Begin - Create NewFolder.info file
    if (($Script:KickstartVersiontoUse -eq 3.1) -or (($Script:KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'FALSE'))) {
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\Monitors.info') -DestinationPath ($TempFolder.TrimEnd('\'))  -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        }
        if (Test-Path ($TempFolder+'def_drawer.info')){
            $null = Remove-Item ($TempFolder+'def_drawer.info')
        }
        $null = Rename-Item ($TempFolder+'Monitors.info') ($TempFolder+'def_drawer.info')
    }
    elseif(($Script:KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'TRUE')){
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
    
    elseif ($Script:KickstartVersiontoUse -eq 3.2){
        $SourcePath = ($GlowIconsADF+'\Prefs\Env-Archive\Sys\def_harddisk.info') 
    }
    
    foreach ($AmigaPartition in $AmigaPartitionsList | Where-Object {$_.VolumeName -ne $VolumeName_System} ){
        If ($AmigaPartition.PartitionNumber -ge 3){
            $DestinationPathtoUse = ($LocationofImage+$NameofImage+'\rdb\'+$AmigaPartition.DeviceName+'\')
        }
        else{
            $DestinationPathtoUse = ($AmigaDrivetoCopy+$VolumeName_Other) 
        }
        Write-InformationMessage -Message ('Copying Icons to Work Partition. Source is: '+$SourcePath+' Destination is: '+$DestinationPathtoUse)
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath $SourcePath -DestinationPath $DestinationPathtoUse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
                    exit
        }
        if (($AmigaPartition.PartitionNumber -le 3) -and ($Script:KickstartVersiontoUse -eq 3.2)) {
            Rename-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\def_harddisk.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info') 
        }
    }

}

Write-TaskCompleteMessage -Message 'Preparing Amiga Image - Complete!'

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
               $DestinationPathtoUse = ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System)
            }
            else{
               $DestinationPathtoUse = ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System+'\'+($InstallFileLine.LocationtoInstall -replace '/','\'))
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
    
    $ListofPackagestoInstall = Import-Csv ($InputFolder+'ListofPackagestoInstall.csv') -Delimiter ';' |  Where-Object {$_.KickstartVersion -match $Script:KickstartVersiontoUse} | Where-Object {$_.InstallFlag -eq 'TRUE'} #| Sort-Object -Property 'InstallSequence','PackageName'
    
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
    
    If ($Script:KickstartVersiontoUse -eq 3.2){
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



#### Set up FAT32

Write-StartTaskMessage -Message 'Setting up FAT32 files'

Write-InformationMessage -Message 'Copying Emu68Pistorm and Emu68Pistorm32lite files' 

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

Write-InformationMessage -Message 'Copying Cmdline.txt' 

Copy-Item ($LocationofAmigaFiles+'FAT32\cmdline_'+$Script:KickstartVersiontoUse+'.txt') -Destination ($FAT32Partition+'cmdline.txt') #Temporary workaround until Michal fixes buptest for 3.1


$ConfigTxt = Get-Content -Path ($LocationofAmigaFiles+'FAT32\config.txt')

Write-InformationMessage -Message 'Preparing Config.txt'

$RevisedConfigTxt=$null

$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.CSV') -Delimiter (';')
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
Export-TextFileforAmiga -DatatoExport $RevisedConfigTxt -ExportFile ($FAT32Partition+'config.txt') -AddLineFeeds 'TRUE' 

Write-InformationMessage -Message 'Copying Kickstart file to FAT32 partition'
$null = copy-Item -LiteralPath $KickstartPath -Destination ($FAT32Partition+$KickstartNameFAT32)

Write-TaskCompleteMessage -Message 'Setting up FAT32 Files - Complete!'

### Transfer files to Work partition

if ($Script:TransferLocation) {
    Write-StartTaskMessage -Message 'Transferring Migrated Files to Work Partition'
    Write-InformationMessage -Message ('Transferring files from '+$TransferLocation+' to "'+$MigratedFilesFolder+'" directory on Work drive')
    $SourcePathtoUse = $TransferLocation+('*')
    if (Test-Path ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')){
        Remove-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')
    }
    $null = Copy-Item ($TempFolder+'NewFolder.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')
    if (-not(Start-HSTImager -Command 'fs copy' -SourcePath $SourcePathtoUse -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_Other+'\'+$MigratedFilesFolder) -HSTImagePathtouse $HSTImagePath -TempFoldertouse $TempFolder)){
        exit
    }
    Write-TaskCompleteMessage -Message 'Transferring Migrated Files to Work Partition - Complete!'
}

if ($Script:SetDiskupOnly -eq 'FALSE'){

    Write-StartTaskMessage -Message 'Transferring Amiga Files to Image'
    
    if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_System) -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    } 
    if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_Other) -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_Other) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    }  
    
    Write-TaskCompleteMessage -Message 'Transferring Amiga Files to Image - Complete!'

}


Write-StartTaskMessage -Message 'Creating Image'

Set-Location $LocationofImage

#Update-OutputWindow -OutputConsole_Title_Text 'Creating Image' -ProgressbarValue_Overall 83 -ProgressbarValue_Overall_Text '83%'

& $HDF2emu68Path $LocationofImage$NameofImage $SizeofFAT32 ($FAT32Partition).Trim('\')

$null= Rename-Item ($LocationofImager+'emu68_converted.img') -NewName ('Emu68Kickstart'+$Script:KickstartVersiontoUse+'.img')

Write-TaskCompleteMessage -Message 'Creating Image - Complete!'

Write-StartTaskMessage -Message 'Writing Image to Disk'

Set-location  $Script:WorkingPath

Write-Image -HSTImagePathtouse $HSTImagePath -SourcePath ($LocationofImage+'Emu68Kickstart'+$Script:KickstartVersiontoUse+'.img') -DestinationPath $Script:HSTDiskName

Write-TaskCompleteMessage -Message 'Writing Image to Disk - Complete!'

$EndDateandTime = (Get-Date -Format HH:mm:ss)
$ElapsedTime = (New-TimeSpan -Start $StartDateandTime -End $EndDateandTime).TotalSeconds

Write-Host "Started at: $StartDateandTime Finished at: $EndDateandTime. Total time to run (in seconds) was: $ElapsedTime" 

#>