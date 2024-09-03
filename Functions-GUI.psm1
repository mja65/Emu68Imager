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

Function Test-Administrator{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
function Confirm-DiskSpace {
    param (
        $PathtoCheck
    )
    (Get-Volume -DriveLetter (Split-Path -Qualifier $PathtoCheck).Replace(':','')).SizeRemaining
}

function Confirm-UIFields {
    param (
        
    )
    $ErrorMessage = $null
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

    function Open-OutputWindow {
 
        $Global:SyncHash = [hashtable]::Synchronized(@{})
        $newRunspace =[runspacefactory]::CreateRunspace()
        $newRunspace.ApartmentState = "STA"
        $newRunspace.ThreadOptions = "ReuseThread"         
        $newRunspace.Open()
        $newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)   
        
        $Global:PsCmd = [PowerShell]::Create().AddScript({
    
            $OutputWindowXML = '
    
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" x:Name="Status_Window"
        mc:Ignorable="d"
        Title="MainWindow" Height="450" Width="800">
    <Grid x:Name="Grid_Main" Visibility="Visible">
        <Grid x:Name="Grid_Progress" Visibility="Visible">
            <ProgressBar x:Name="ProgressBar_Overall" HorizontalAlignment="Left" Height="40" Margin="56,159,0,0" VerticalAlignment="Top" Width="728" Value="0"  Maximum="100" Minimum="0" Visibility="Visible"/>
            <TextBlock x:Name="OutputConsole_Detail" HorizontalAlignment="Left" Margin="68,310,0,0" TextWrapping="Wrap" Text="TextBlock" VerticalAlignment="Top" Width="722" Height="117" Visibility="Visible"/>
            <TextBlock x:Name="OutputConsole_Title" HorizontalAlignment="Left" Margin="59,57,0,0" TextWrapping="Wrap" Text="TextBlock" VerticalAlignment="Top" Width="722" Height="62" Visibility="Visible"/>
            <ProgressBar x:Name="ProgressBar" HorizontalAlignment="Left" Height="40" Margin="62,249,0,0" VerticalAlignment="Top" Width="728" Value="0"  Maximum="100" Minimum="0" Visibility="Visible"/>
            <Label x:Name="ProgressBar_Overall_Title" Content="Overall Progress" HorizontalAlignment="Left" Margin="56,119,0,0" VerticalAlignment="Top" Width="728" HorizontalContentAlignment="Center" Visibility="Visible"/>
            <Label x:Name="ProgressBar_Title" Content="Progress of Task" HorizontalAlignment="Center" Margin="41,217,0,0" VerticalAlignment="Top" Width="728" HorizontalContentAlignment="Center" Visibility="Visible"/>
            <Label x:Name="ProgressBar_Overall_TextBox" Content="Label" HorizontalAlignment="Center" Margin="0,166,0,0" VerticalAlignment="Top" Visibility="Visible"/>
            <Label x:Name="ProgressBar_TextBox" Content="Label" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,256,0,0" Visibility="Visible"/>
        </Grid>
        <Grid x:Name="Grid_Error" Visibility="Visible">
            <TextBlock x:Name="OutputConsole_Error_Line" HorizontalAlignment="Left" Margin="62,172,0,0" TextWrapping="Wrap" Text="TextBlock" VerticalAlignment="Top" Width="722" Height="40" FontSize="16" FontFamily="Arial" Foreground="Red" Visibility="Visible"/>
        </Grid>
    </Grid>
</Window>
            
            '
            
            $OutputWindowXML = $OutputWindowXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
            [xml]$XAML = $OutputWindowXML
            
            $reader=(New-Object System.Xml.XmlNodeReader $XAML)
            $syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
            
            $XAML.SelectNodes("//*[@Name]") | ForEach-Object {
                try {
                    Write-Output "Adding $($_.Name)"
                    $syncHash.Add($_.Name,$syncHash.Window.FindName($_.Name))
                } catch {
                    throw
                }
            }
            $syncHash.Window.ShowDialog() | Out-Null
            $SyncHash.Error = $Error
    
        })   
        
        #Setup the runspace
        $PsCmd.Runspace = $NewRunspace
        $null = $PsCmd.BeginInvoke()  
                    #Wait 1 second for the thread to setup
        Start-Sleep -Seconds 1
    }

# 
    

    Function Update-OutputWindow {
        Param
        (
            $OutputConsole_Title_Text,
            $OutputConsole_Detail_Text,
            $ProgressbarValue_Overall,
            $ProgressbarValue,
            $ProgressbarValue_Text,
            $ProgressbarValue_Overall_Text,
            $OutputConsole_Error_Line_Text,

            $Progress_Grid_Hidden,
            $Error_Grid_Hidden,
            $ProgressBar_Overall_Title_Hidden,
            $ProgressBar_Title_Hidden,
            $OutputConsole_Title_Text_Hidden,
            $OutputConsole_Detail_Text_Hidden,          
            $ProgressbarValue_Overall_Hidden,
            $ProgressbarValue_Hidden,
            $ProgressbarValue_Text_Hidden,
            $ProgressbarValue_Overall_Text_Hidden,
            $OutputConsole_Error_Line_Text_Hidden

        )
      
        If ($Error_Grid_Hidden -eq 'TRUE'){        
            $SyncHash.Grid_Error.Dispatcher.Invoke(
                [Action]{$SyncHash.Grid_Error.Visibility='Hidden'}
                )
        }
        elseif ($Error_Grid_Hidden -eq 'FALSE'){
            $SyncHash.Grid_Error.Dispatcher.Invoke(
                [Action]{$SyncHash.Grid_Error.Visibility='Visible'}
                )
        }

        If ($Progress_Grid_Hidden -eq 'TRUE'){        
            $SyncHash.Grid_Progress.Dispatcher.Invoke(
                [Action]{$SyncHash.Grid_Progress.Visibility='Hidden'}
                )
        }
        elseif ($Progress_Grid_Hidden -eq 'FALSE'){
            $SyncHash.Grid_Progress.Dispatcher.Invoke(
                [Action]{$SyncHash.Grid_Progress.Visibility='Visible'}
                )
        }

        If ($ProgressBar_Overall_Title_Hidden -eq 'TRUE'){        
            $SyncHash.ProgressBar_Overall_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall_Title.Visibility='Hidden'}
                )
        }
        elseif ($ProgressBar_Overall_Title_Hidden -eq 'FALSE'){
            $SyncHash.ProgressBar_Overall_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall_Title.Visibility='Visible'}
                )
        }

        If ($ProgressBar_Title_Hidden -eq 'TRUE'){        
            $SyncHash.ProgressBar_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Title.Visibility='Hidden'}
                )
        }
        elseif ($ProgressBar_Title_Hidden -eq 'FALSE'){
            $SyncHash.ProgressBar_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Title.Visibility='Visible'}
                )
        }


        If ($OutputConsole_Error_Line_Text_Hidden -eq 'TRUE'){        
            $SyncHash.OutputConsole_Error_Line.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Error_Line.Visibility='Hidden'}
                )
        }
        elseif ($OutputConsole_Error_Line_Text_Hidden -eq 'FALSE'){
            $SyncHash.OutputConsole_Error_Line.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Error_Line.Visibility='Visible'}
                )
        }

        If ($ProgressbarValue_Overall_Text_Hidden -eq 'TRUE'){        
            $SyncHash.ProgressBar_Overall_TextBox.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall_TextBox.Visibility='Hidden'}
                )
        }
        elseif ($ProgressbarValue_Overall_Text_Hidden -eq 'FALSE'){
            $SyncHash.ProgressBar_Overall_TextBox.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall_TextBox.Visibility='Visible'}
                )
        }

        If ($ProgressbarValue_Text_Hidden -eq 'TRUE'){        
            $SyncHash.ProgressBar_TextBox.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_TextBox.Visibility='Hidden'}
                )
        }
        elseif ($ProgressbarValue_Text_Hidden -eq 'FALSE'){
            $SyncHash.ProgressBar_TextBox.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_TextBox.Visibility='Visible'}
                )
        }


        If ($ProgressbarValue_Hidden -eq 'TRUE'){        
            $SyncHash.ProgressBar.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar.Visibility='Hidden'}
                )
        }
        elseif ($ProgressbarValue_Hidden -eq 'FALSE'){
            $SyncHash.ProgressBar.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar.Visibility='Visible'}
                )
        }

        If ($ProgressbarValue_Overall_Hidden -eq 'TRUE'){        
            $SyncHash.ProgressBar_Overall.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall.Visibility='Hidden'}
                )
        }
        elseif ($ProgressbarValue_Overall_Hidden -eq 'FALSE'){
            $SyncHash.ProgressBar_Overall.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall.Visibility='Visible'}
                )
        }

        If ($OutputConsole_Detail_Text_Hidden -eq 'TRUE'){        
            $SyncHash.OutputConsole_Detail.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Detail.Visibility='Hidden'}
                )
        }
        elseif ($OutputConsole_Detail_Text_Hidden -eq 'FALSE'){
            $SyncHash.OutputConsole_Detail.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Detail.Visibility='Visible'}
                )
        }

        If ($OutputConsole_Title_Text_Hidden -eq 'TRUE'){        
            $SyncHash.OutputConsole_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Title.Visibility='Hidden'}
                )
        }
        elseif ($OutputConsole_Title_Text_Hidden -eq 'FALSE'){
            $SyncHash.OutputConsole_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Title.Visibility='Visible'}
                )
        }

        If($null -ne $ProgressbarValue_Overall_Text){
        
            $SyncHash.ProgressBar_Overall_TextBox.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_Overall_TextBox.Content=$ProgressbarValue_Overall_Text}
                )
        }

        If($null -ne $ProgressbarValue_Text){
        
            $SyncHash.ProgressBar_TextBox.Dispatcher.Invoke(
                [Action]{$SyncHash.ProgressBar_TextBox.Content=$ProgressbarValue_Text}
                )
        }
        
        If($null -ne $OutputConsole_Title_Text){
        
            $SyncHash.OutputConsole_Title.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Title.Text=$OutputConsole_Title_Text}
                )
        }
        If($null -ne $OutputConsole_Error_Line_Text){
        
            $SyncHash.OutputConsole_Error_Line.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Error_Line.Text=$OutputConsole_Error_Line_Text}
                )
        }

        If($null -ne $OutputConsole_Detail_Text){
        
            $SyncHash.OutputConsole_Detail.Dispatcher.Invoke(
                [Action]{$SyncHash.OutputConsole_Detail.Text=$OutputConsole_Detail_Text}
                )
        }
    
        If($null -ne $ProgressbarValue){
        
            $SyncHash.ProgressBar.Dispatcher.Invoke(
                [Action]{[INT]$SyncHash.ProgressBar.Value =$ProgressbarValue}
                )
        }
        
        If($null -ne $ProgressbarValue_Overall){
        
            $SyncHash.ProgressBar_Overall.Dispatcher.Invoke(
                [Action]{[INT]$SyncHash.ProgressBar_Overall.Value =$ProgressbarValue_Overall}
                )
        }
    }

### Functions

function Compare-FileHash {
    param (
        $FiletoCheck,
        $HashtoCheck
    )
    Write-Host 'Checking hash for file:'$FiletoCheck
    $HashChecked = Get-FileHash $FiletoCheck -Algorithm MD5
    $HashtoReport=$HashChecked.Hash
    if ($HashChecked.Hash -eq $HashtoCheck) {
        Write-Host "Hash of file matches!"
        return $true
    } 
    else{
        Write-Host 'Hash mismatch!'
        Write-Host 'Hash expected was: '$HashtoCheck' Hash found was: '$HashtoReport
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
    Write-Host "Extracting from"$InputFile
    & $SevenzipPathtouse x ('-o'+$OutputDirectory) $InputFile $FiletoExtract -y >($TempFoldertouse+'LogOutputTemp.txt')
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("Error extracting "+$InputFile+"! Cannot continue!") -ForegroundColor Red
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
    Write-host 'Extracting file'$LZXFile
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
    Write-Host "Downloading file"$NameofDL
    if (([System.Uri]$URL).host -eq 'aminet.net'){
        $AminetMirrors =  Import-Csv ($InputFolder+'AminetMirrors.csv') -Delimiter ';'
        foreach ($Mirror in $AminetMirrors){
            Write-Host ("Trying mirror: "+$Mirror.MirrorURL+" ("+$Mirror.Type+")")
            $URLBase=$Mirror.Type+'://'+$Mirror.MirrorURL
            $URLPathandQuery=([System.Uri]$URL).pathandquery 
            $DownloadURL=($URLBase+$URLPathandQuery)
            Write-host "Trying to download from: $DownloadURL"
            try {
                Invoke-WebRequest $DownloadURL -OutFile ($LocationforDL+$NameofDL) # Powershell 5 compatibility -AllowInsecureRedirect
                Write-Host "Download completed"
                return $true   
            }
            catch {
                Write-Host ("Error downloading "+$NameofDL+"! Trying different server")
            }
        }
        Write-Host "All servers attempted. Download failed" -ForegroundColor Red
        return $false    
    }
    else{
        try {
            Invoke-WebRequest $URL -OutFile ($LocationforDL+$NameofDL) # Powershell 5 compatibility -AllowInsecureRedirect
            Write-Host "Download completed"
            return $true       
        }
        catch {
            Write-Host ("Error downloading "+$NameofDL+"!") -ForegroundColor Red
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
        Write-Host "Creating image"
        & $HSTImagePathtouse blank $DestinationPath $ImageSize >$Logoutput            
    }
    elseif ($Command -eq 'rdb init'){
        Write-Host "Initialising partition"
        & $HSTImagePathtouse rdb init $DestinationPath $Options >$Logoutput            
    }
    elseif ($Command -eq 'rdb filesystem add'){
        Write-Host "Adding Filesystem $DosType to RDB"
        & $HSTImagePathtouse rdb filesystem add $DestinationPath $FileSystemPath $DosType $Options >$Logoutput            
    }
    elseif ($Command -eq 'rdb part add'){
        Write-Host "Adding partition $DeviceName $DosType"
        & $HSTImagePathtouse rdb part add $DestinationPath $DeviceName $DosType $SizeofPartition $Options --mask 0x7ffffffe --buffers 300 --max-transfer 0xffffff >$Logoutput
    }
    elseif ($Command -eq 'rdb part format'){
        Write-Host "Formatting partition $VolumeName"
        & $HSTImagePathtouse rdb part format $DestinationPath $PartitionNumber $VolumeName $Options >$Logoutput            
    }   
    elseif ($Command -eq 'fs extract') {
        Write-Host ('Extracting data from ADF. Source path is: '+$SourcePath+' Destination path is: '+$DestinationPath)
        & $HSTImagePathtouse fs extract $SourcePath $DestinationPath $Options >$Logoutput                                
    }
    elseif ($Command -eq 'fs copy') {
        Write-Host "Writing file(s) to HDF image for: $SourcePath to $DestinationPath" 
        & $HSTImagePathtouse fs copy $SourcePath $DestinationPath $Options >$Logoutput  
    } 
    elseif ($Command -eq 'write') {
        Write-Host "Writing Image to Disk for: $SourcePath to $DestinationPath" 
        & $HSTImagePathtouse write $SourcePath $DestinationPath
    }    
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-Host "Error in HST-Imager:"$ErrorLine -ForegroundColor RED           
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

function Read-AmigaTooltypes {
    param (
        $HSTAmigaPathtouse,
        $TempFoldertouse,
        $IconPath,
        $ToolTypesPath
        
    )
    $Logoutput=($TempFoldertouse+'LogOutputTemp.txt')
    Write-Host "Extracting Tooltypes for info file(s): $IconPath  to $ToolTypesPath" 
    & $HSTAmigaPathtouse icon tooltypes export $IconPath $ToolTypesPath >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-Host "Error in HST-Amiga:"$ErrorLine -ForegroundColor Red           
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
    Write-Host "Importing Tooltypes for info file(s): $IconPath from $ToolTypesPath" 
    & $HSTAmigaPathtouse icon tooltypes import $IconPath $ToolTypesPath >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-Host "Error in HST-Amiga:"$ErrorLine -ForegroundColor Red           
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
    Write-Host ("Decompressing .Z files in location: "+$LocationofZFiles)
    foreach ($FiletoDecompress in $ListofFilestoDecompress){
        $InputFile=$FiletoDecompress.FullName
        set-location $FiletoDecompress.DirectoryName
        & $SevenzipPathtouse e $InputFile -bso0 -bsp0 -y
    }      
    Set-Location $WorkingFoldertouse
    Write-Host ("Deleting .Z files in location: "+$LocationofZFiles)
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
        Write-Host ('Creating Folder "'+$AmigaFolderPath+'"')
        $null = New-Item -path ($AmigaDrivetoCopytouse+$AmigaFolderPath) -ItemType Directory -Force 
    }
    else{
        Write-Host ('Folder "'+$AmigaFolderPath+'" already exists')
    
    }
    if (-not(Test-Path ($ParentFolder+$FileName+'.info'))){
        write-host ('Creating .info file '+$FileName+'.info')
        Copy-Item ($TempFoldertouse+'NewFolder.info') $ParentFolder
        Rename-Item ($ParentFolder+'NewFolder.info') ($ParentFolder+$FileName+'.info')
    }
    else {
        write-host ($FileName+'.info already exists')
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
        Write-Host "File already exists!"
        return $true   
    }
    else{
        Write-Host "Retrieving Github information"
        try {
            $GithubDetails = (Invoke-WebRequest $GithubRelease | ConvertFrom-Json)            
        }
        catch {
            Write-Host "Error downloading $NameofDL!"
            return $false
        }
        if ($Sort_Flag -eq 'Sort'){
            $GithubDetails_2 = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name } | Sort-Object -Property updated_at -Descending
        }
        else{
            $GithubDetails_2 = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }
        }
        $GithubDownloadURL =$GithubDetails_2[0].browser_download_url 
        Write-Host "Downloading Files for URL: $GithubDownloadURL"
        try {
            Invoke-WebRequest $GithubDownloadURL -OutFile $LocationforDownload # Powershell 5 compatibility -AllowInsecureRedirect
            Write-Host "Download completed"            
        }
        catch {
            Write-Host "Error downloading $NameofDL!"
            return $false
        }
        Write-Host "Extracting Files"
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
        Write-Host 'Removing items from script'
        Write-Host "Startpoint is: $Startpoint Endpoint is: $Endpoint"
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
        Write-Host 'Injecting new lines in script before Startpoint'
        Write-Host "Startpoint is: $Startpoint"
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
       Write-Host 'Injecting new lines in script after startpoint'
       Write-Host "Startpoint is: $Startpoint"
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
    Write-Host ('Exporting file '+$ExportFile)
    if ($AddLineFeeds -eq 'TRUE'){
        Write-Host ('Adding line feeds to file '+$ExportFile)
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
    Write-Host ('Searching for: '+$PackagetoFind)
    $ListofAminetFiles=Invoke-WebRequest $URL -UseBasicParsing # -AllowInsecureRedirect Powershell 5 compatibility
    foreach ($Line in $ListofAminetFiles.Links) {      
    if (!$Exclusion) {
        if (($line -match ('.lha'))){
            Write-Host ('Found '+$line.href)
            return ($AminetURL+$line.href)
       }     
    }
    else {
    }
        if (($line -match ('.lha')) -and (-not ($line -match $Exclusion))){
            Write-Host ('Found '+$line.href)
            return ($AminetURL+$line.href)
       }       
    }
    Write-Host 'Could not find package! Unrrecoverable error!' -ForegroundColor Red
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
        Write-Host "Retrieving link latest version of $SearchCriteria (assuming Tom hasn't screwed up the version numbering......)"
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
            #echo $ModifiedTooltype.NewValue
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
        Write-host "No valid Kickstart file found!"
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
    
    Write-Host "Calculating hashes of ADFs in location $PathtoADFFiles"
    $ListofADFFilestoCheck = Get-ChildItem $PathtoADFFiles -force -Recurse | Where-Object { $_.PSIsContainer -eq $false } | Get-FileHash  -Algorithm MD5
    Write-Host "Hashes calculated!"
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
            Write-Host ('Found ADF file: '+$RequiredADF.FriendlyName)
        }
        if ($ADFFound -eq  $false){
            write-host ('ADF file: '+$RequiredADF.FriendlyName+' is missing from directory and/or hash is invalid Please check file!') -ForegroundColor Red
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
        Write-host "Error! No version found!"
        return
    }
    else{
        $Endpoint = $StartupSequence_FirstLine.IndexOf($String_End)
        $Version=$StartupSequence_FirstLine.Substring($Startpoint,($Endpoint-$Startpoint))
        Write-Host "Version of Startup-Sequence is $Version"
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
            Write-host "Injection point identified (not version specific) is: $InjectionPointtoParse"
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
                Write-host ('Injection point identified for version '+$SSversion+' is: '+$line.Text)
                return $line.Text
            }
        }    
        return           
}

#function Get-FolderPath {
##    param (
 #       $NewFolderFlag,
 #       $Description,
 #       $ShowNewFolderButton,
 #       $RootFolder    
#
#    )
#    Add-Type -AssemblyName System.Windows.Forms

#    $BrowseFolder = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
#        Description = $Description
#        ShowNewFolderButton = $ShowNewFolderButton   
#        RootFolder = 'MyComputer'
#       InitialDirectory = 'MyDocuments'
#    }
#    $BrowseFolder.ShowDialog() | Out-Null
#    if (!$BrowseFolder.SelectedPath){
#        return
#    }
#    else {
#        return ($BrowseFolder.SelectedPath + "\")
##    }
#}

#[Enum]::GetNames([System.Environment+SpecialFolder])

function Test-ExistenceofFiles {
    param (
        $PathtoTest,
        $PathType
    )
    if (-not (Test-Path $PathtoTest)){
        Write-Host ('Error! '+$PathtoTest+' is not available! Please check your download of the tool!') -ForegroundColor Red
        return 1 
    }
    else{
        Write-Host ($PathtoTest+' is available!')
        return 0
    }
}

### End Functions