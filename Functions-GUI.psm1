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
        $RoundedSize = ([math]::truncate(($Disk.Size/1GB)*1000)/1000)
        
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
    
    $SpaceNeeded = `
    (2*$ImageSize*1024) + ` #Image
    10 + ` #FAT32 Files
    23 + ` # AmigaImageFiles
    40 + ` # AmigaDownloads
    190 + ` # Programs Folder
    80   # TempFolder
    $SpaceNeeded = $SpaceNeeded*1024
    return $SpaceNeeded # In Kilobytes
}

function Write-StartTaskMessage {
    param (
        $SectionNumber,
        $TotalSections,
        $Message
    )
    Write-Host ''
    Write-Host "[Section: $SectionNumber of $TotalSections]: `t $Message" -ForegroundColor White
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
    Write-Host $Message -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param (
        $Message
    )
    Write-Host "[ERROR] `t $Message" -ForegroundColor Red
}

function Write-TaskCompleteMessage {
    param (
        $SectionNumber,
        $TotalSections,
        $Message
    )
    Write-Host "[Section: $SectionNumber of $TotalSections]: `t $Message" -ForegroundColor Green
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
    Write-InformationMessage -message "HSTDiskName is: $Global:HSTDiskName" 
    Write-InformationMessage -message "ScreenModetoUse is: $Global:ScreenModetoUse"
    Write-InformationMessage -message "KickstartVersiontoUse is: $Global:KickstartVersiontoUse"
    Write-InformationMessage -message "SSID is: $Global:SSID" 
    Write-InformationMessage -message "WifiPassword is: $Global:WifiPassword" 
    Write-InformationMessage -message "SizeofFAT32 is: $Global:SizeofFAT32" 
    Write-InformationMessage -message "SizeofImage is: $Global:SizeofImage"
    Write-InformationMessage -message "SizeofPartition_System is: $Global:SizeofPartition_System"
    Write-InformationMessage -message "SizeofPartition_Other is: $Global:SizeofPartition_Other"
    Write-InformationMessage -message "WorkingPathis: $Global:WorkingPath"
    Write-InformationMessage -message "ROMPath is: $Global:ROMPath"
}

function Confirm-UIFields {
    param (
        
    )
    $ErrorMessage = $null
    if (-not($Global:HSTDiskName)){
        $ErrorMessage += 'You have not selected a disk'+"`n"
    }
    if (-not($WPF_UI_KickstartVersion_Dropdown.SelectedItem)) {
        $ErrorMessage += 'You have not populated a Kickstart version'+"`n"
    }
    if (-not($WPF_UI_ScreenMode_Dropdown.SelectedItem)) {
        $ErrorMessage += 'You have not populated a sceenmode'+"`n"
    }
    if (-not($Global:ROMPath )) {
        $ErrorMessage += 'You have not populated a Rom Path'+"`n"
    }
    if (-not($Global:ADFPath )) {
        $ErrorMessage += 'You have not populated an ADF Path'+"`n"
    }  
    return $ErrorMessage
}


Function Get-FormVariables{
    if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
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
                Size = $_.Size
                EnglishSize = ([math]::Round($_.Size/1GB,3).ToString())
                FriendlyName = 'Disk '+$DriveNumber+' '+$_.Model+' '+([math]::Round($_.Size/1GB,3).ToString()) 
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