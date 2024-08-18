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
        $FiletoExtract
    )
    Write-Host "Extracting from"$InputFile
    & $7zipPath x ('-o'+$OutputDirectory) $InputFile $FiletoExtract -y >($TempFolder+'Test.txt')
}

function Expand-LZXArchive {
    param (
        $LZXFile,
        $DestinationPath
    )
    Write-host 'Extracting file'$LZXFile
    if (-not(Test-Path $DestinationPath)){
       $null= New-Item $DestinationPath -ItemType Directory
    }
    Set-Location $DestinationPath
    & $LZXPath $LZXFile >($TempFolder+'Test.txt')
    Set-Location $WorkingFolder
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
        Write-Host "All servers attempted. Download failed"
        return $false    
    }
    else{
        try {
            Invoke-WebRequest $URL -OutFile ($LocationforDL+$NameofDL) # Powershell 5 compatibility -AllowInsecureRedirect
            Write-Host "Download completed"
            return $true       
        }
        catch {
            Write-Host ("Error downloading "+$NameofDL+"!")
            return $false
        }        
    }
}

    function Start-HSTImager {
        param (
            $Command,
            $CommandString,
            $SourcePath,
            $DestinationPath,
            $FileSystem,
            $ImageSize,
            $DeviceName,
            $SizeofPartition,
            $BootableFlag,
            $MaxTransfer,
            $Mask,
            $Buffers,
            $PartitionNumber,
            $VolumeName,
            $ADFName,
            $ADFInputFiles,
            $DrivetoWrite,
            $ADFLocationtoInstall,
            $Extract_Flag,
            $HDFFullPath 
    
        )
        $Logoutput=($TempFolder+'Test.txt')
        if ($Command -eq 'rdb init'){
            #& "$HSTImagePath" rdb init "$DestinationPath" >"$Logoutput"
            & $HSTImagePath rdb init $DestinationPath >$Logoutput            
        }
        if ($Command -eq 'rdb filesystem add'){
           # & "$HSTImagePath" rdb filesystem add "$SourcePath" "$DestinationPath" "$FileSystem" >"$Logoutput"
            & $HSTImagePath rdb filesystem add $SourcePath $DestinationPath $FileSystem >$Logoutput            
        }
        if ($Command -eq 'rdb part add'){
            if ($BootableFlag -eq '-b'){
              #  & "$HSTImagePath" rdb part add "$SourcePath" "$DeviceName" "$FileSystem" "$SizeofPartition" "$BootableFlag" >"$Logoutput"
                & $HSTImagePath rdb part add $SourcePath $DeviceName $FileSystem $SizeofPartition $BootableFlag -ma $Mask -bu $Buffers -mt $MaxTransfer >$Logoutput                
            }
            else{
              #  & "$HSTImagePath" rdb part add "$SourcePath" "$DeviceName" "$FileSystem" "$SizeofPartition" >"$Logoutput"
                & $HSTImagePath rdb part add $SourcePath $DeviceName $FileSystem $SizeofPartition >$Logoutput                
            }
        }
        if ($Command -eq 'rdb part format'){
          #  & "$HSTImagePath" rdb part format "$SourcePath" "$PartitionNumber" "$VolumeName" >"$Logoutput"
            & $HSTImagePath rdb part format $SourcePath $PartitionNumber $VolumeName >$Logoutput            
        }   
        elseif ($Command -eq 'Blank'){
           # & "$HSTImagePath" blank "$DestinationPath" "$ImageSize" >"$Logoutput"
            & $HSTImagePath blank $DestinationPath $ImageSize >$Logoutput            
        }
        elseif ($Command -eq 'fs extract') {
            ## Added for Powershell 5 compatibility - begin
            if ($ADFInputFiles -eq ""){
                $SourcePath=$ADFName
            }
            else{
                $SourcePath=($ADFName+'\'+$ADFInputFiles)
            }
            if ($ADFLocationtoInstall -eq ""){
                $DestinationPath=$DrivetoWrite
            }
            else{
                $DestinationPath=($DrivetoWrite+'\'+$ADFLocationtoInstall)
            }
            Write-Host "Source path is: $SourcePath Destination path is: $DestinationPath"
            ## Added for Powershell 5 compatibility - end
            if ($Extract_Flag -eq 'rdb'){
                #& "$HSTImagePath" fs extract "$ADFName\$ADFInputFiles" "$HDFFullPath\rdb\$DrivetoWrite\$ADFLocationtoInstall" >"$Logoutput"                           
                & $HSTImagePath fs extract $SourcePath $HDFFullPath\rdb\$DestinationPath >$Logoutput                                
            }
            elseif ($Extract_Flag -eq 'AmigaDrive'){
                if (-not (Test-Path ($AmigaDrivetoCopy+$DrivetoWrite+'\'+$ADFLocationtoInstall))){
                    $null = New-Item ($AmigaDrivetoCopy+$DrivetoWrite+'\'+$ADFLocationtoInstall) -ItemType Directory
                }
                #& "$HSTImagePath" fs extract "$ADFName\$ADFInputFiles" "$AmigaDrivetoCopy$DrivetoWrite\$ADFLocationtoInstall" >"$Logoutput"
                & $HSTImagePath fs extract $SourcePath $AmigaDrivetoCopy$DestinationPath >$Logoutput      
            }
            else{
                if (-not (Test-Path ($ADFLocationtoInstall))){
                    $null = New-Item ($ADFLocationtoInstall) -ItemType Directory
                }                
                #& "$HSTImagePath" fs extract "$ADFName\$ADFInputFiles" "$ADFLocationtoInstall" >"$Logoutput"
                & $HSTImagePath fs extract $SourcePath $ADFLocationtoInstall >$Logoutput      
            }           
        }
        $CheckforError = Get-Content ($Logoutput)
        $ErrorCount=0
        foreach ($ErrorLine in $CheckforError){
            if ($ErrorLine -match " ERR]"){
                $ErrorCount += 1
                Write-Host "Error in HST-Imager:"$ErrorLine            
            }
        }
        if ($ErrorCount -ge 1){
            $null=Remove-Item ($Logoutput) -Force
            exit    
        }    
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
    $ListofAminetFiles=Invoke-WebRequest $URL -UseBasicParsing ## -AllowInsecureRedirect Powershell 5 compatibility
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
}


function Write-AmigaFilestoFS {
    param (
        $DrivetoRead,
        $FilestoCopy,
        $DrivetoWrite,
        $HDFFullPath,
        $TransferFlag
    )        
    $Logoutput= ($TempFolder+'Test.txt')
    Write-Host ("Writing file(s) to HDF image for: "+$DrivetoRead+":"+$FilestoCopy+" to drive "+$DrivetoWrite+":") 
    if($TransferFlag -eq 'Transfer'){
 #       & ($HSTImagePath) fs copy ($FilestoCopy) ($HDFFullPath+'\rdb\'+$DrivetoWrite+'\My Files\') $Logoutput
        & "$HSTImagePath" fs copy "$FilestoCopy" "$HDFFullPath\rdb\$DrivetoWrite\My Files\" >"$Logoutput"
    }
    else {
#        & ($HSTImagePath) fs copy ($AmigaDrivetoCopy+$DrivetoRead+'\'+$FilestoCopy) ($HDFFullPath+'\rdb\'+$DrivetoWrite+'\') $Logoutput
#        & "$HSTImagePath" fs copy "$AmigaDrivetoCopy$DrivetoRead\$FilestoCopy" "$HDFFullPath\rdb\$DrivetoWrite\" >"$Logoutput"
        & $HSTImagePath fs copy $AmigaDrivetoCopy$DrivetoRead\$FilestoCopy $HDFFullPath\rdb\$DrivetoWrite\ >$Logoutput
    }
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-Host "Error in HST-Imager:"$ErrorLine            
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        exit    
    }    
}
function Write-AmigaTooltypes {
    param (
        $DrivetoWrite,
        $InfoFiletoWritePath,
        $InfoTextFiletoReadPath

    )
    $Logoutput=($TempFolder+'Test.txt')
    Write-Host ("Importing Tooltypes for info file(s): "+$DrivetoWrite +":"+$InfoFiletoWritePath+" from "+$DrivetoRead+":"+$InfoTextFiletoReadPath) 
 #   & ($HSTAmigaPath) icon tooltypes import ($AmigaDrivetoCopy+$DrivetoWrite+'\'+$InfoFiletoWritePath) $InfoTextFiletoReadPath $Logoutput
#    & "$HSTAmigaPath" icon tooltypes import "$AmigaDrivetoCopy$DrivetoWrite\$InfoFiletoWritePath" "$InfoTextFiletoReadPath" >"$Logoutput"
     & $HSTAmigaPath icon tooltypes import $AmigaDrivetoCopy$DrivetoWrite\$InfoFiletoWritePath $InfoTextFiletoReadPath >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-Host "Error in HST-Imager:"$ErrorLine            
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        exit    
    }        
}

function Read-AmigaTooltypes {
    param (
        $DrivetoRead,
        $InfoFiletoReadPath,
        $InfoTextFiletoWritePath

    )
    $Logoutput=($TempFolder+'Test.txt')
    Write-Host ("Extracting Tooltypes for info file(s): "+$DrivetoRead +":"+$InfoFiletoReadPath+" to "+$InfoTextFiletoWritePath) 
#    & "$HSTAmigaPath" "icon tooltypes export" "($AmigaDrivetoCopy+$DrivetoRead+'\'+$InfoFiletoReadPath)" "$InfoTextFiletoWritePath" "$Logoutput"
#    & "$HSTAmigaPath" icon tooltypes export "$AmigaDrivetoCopy$DrivetoRead\$InfoFiletoReadPath" "$InfoTextFiletoWritePath" >"$Logoutput"
    & $HSTAmigaPath icon tooltypes export $AmigaDrivetoCopy$DrivetoRead\$InfoFiletoReadPath $InfoTextFiletoWritePath >$Logoutput
    $CheckforError = Get-Content ($Logoutput)
    $ErrorCount=0
    foreach ($ErrorLine in $CheckforError){
        if ($ErrorLine -match " ERR]"){
            $ErrorCount += 1
            Write-Host "Error in HST-Imager:"$ErrorLine            
        }
    }
    if ($ErrorCount -ge 1){
        $null=Remove-Item ($Logoutput) -Force
        exit    
    }    
}

function Expand-AmigaZFiles {
    param (
        $LocationofZFiles
    )
    $ListofFilestoDecompress=Get-ChildItem -Path $LocationofZFiles -Recurse -Filter '*.Z'
    Write-Host ("Decompressing .Z files in location: "+$LocationofZFiles)
    foreach ($FiletoDecompress in $ListofFilestoDecompress){
        $InputFile=$FiletoDecompress.FullName
        set-location $FiletoDecompress.DirectoryName
        & $7zipPath e $InputFile -bso0 -bsp0 -y
    }      
    Set-Location $WorkingFolder
    Write-Host ("Deleting .Z files in location: "+$LocationofZFiles)
    Get-ChildItem -Path $LocationofZFiles -Recurse -Filter '*.Z' | remove-Item -Recurse -Force
}

function Add-AmigaFolder {
    param (
        $AmigaFolderPath
    )
    $ParentFolder=(Split-Path ($AmigaDrivetoCopy+$AmigaFolderPath) -Parent)+'\'
    $Startpoint=(Split-Path -Path ($AmigaDrivetoCopy+$AmigaFolderPath)).length+1
    $Endpoint=($AmigaDrivetoCopy+$AmigaFolderPath).length-1
    $Length=$Endpoint-$Startpoint
    $FileName=($AmigaDrivetoCopy+$AmigaFolderPath).Substring($Startpoint,$Length)
    #        $FileName=Split-Path ($AmigaDrivetoCopy+$AmigaFolderPath) -LeafBase Powershell 5 compatibility
   
    if (-not (Test-Path ($AmigaDrivetoCopy+$AmigaFolderPath))){
        Write-Host ('Creating Folder "'+$AmigaFolderPath+'"')
        $null = New-Item -path ($AmigaDrivetoCopy+$AmigaFolderPath) -ItemType Directory -Force 
    }
    else{
        Write-Host ('Folder "'+$AmigaFolderPath+'" already exists')
    
    }
    if (-not(Test-Path ($ParentFolder+$FileName+'.info'))){
        write-host ('Creating .info file '+$FileName+'.info')
        Copy-Item ($TempFolder+'NewFolder.info') $ParentFolder
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
        return    
    }
    else{
        Write-Host "Retrieving Github information"
        $GithubDetails = (Invoke-WebRequest $GithubRelease | ConvertFrom-Json)
        if ($Sort_Flag -eq 'Sort'){
            $GithubDetails_2 = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name } | Sort-Object -Property updated_at -Descending
        }
        else{
            $GithubDetails_2 = $GithubDetails | Where-Object { $_.tag_name -eq $Tag_Name } | Select-Object -ExpandProperty assets | Where-Object { $_.name -match $Name }
        }
        $GithubDownloadURL =$GithubDetails_2[0].browser_download_url 
        Write-Host "Downloading Files"
        Invoke-WebRequest $GithubDownloadURL -OutFile $LocationforDownload
        Write-Host "Extracting Files"
        $null = Expand-Archive -LiteralPath $LocationforDownload -DestinationPath $LocationforProgram -force
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
    if ($AddLineFeeds -eq 'TRUE'){
        Write-Host 'Adding line feeds to file'
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
#        $Data=Get-Content -path $ImportFile -Encoding iso-8859-1 ## Powershell 5 compatibility
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
        return $DownloadLink
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
                #echo $HashTableforOldandNewToolTypes[$OriginalToolType]     
            }
            else{
                $Tooltypes_Revised.Add($OriginalToolType)
                 #echo $OriginalToolType
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
        $ListofKickstartFilestoCheck = Get-ChildItem $PathtoKickstartFiles -Recurse | Where-Object { $_.PSIsContainer -eq $false } 
    
        $FoundKickstarts = [System.Collections.Generic.List[PSCustomObject]]::New()
        $HashTableforKickstartFilestoCheck = @{} # Clear Hash
    
        foreach ($KickstartDetailLine in $ListofKickstartFilestoCheck){
            $KickstartHash=Get-FileHash $KickstartDetailLine.FullName -Algorithm MD5
            $HashTableforKickstartFilestoCheck.Add(($KickstartHash.Hash),$KickstartDetailLine.FullName)
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
        
        <#
        $PathtoADFFiles='D:\Emulators\Amiga Files\Shared\adf'
        $KickstartVersion=3.1
        $PathtoADFHashes='c:\Users\Matt\Downloads\Emu68Imager\InputFiles\ADFHashes.csv'
        $PathtoListofInstallFiles='c:\Users\Matt\Downloads\Emu68Imager\InputFiles\ListofInstallFiles.csv'
        #>
        Write-Host "Calculating hashes of ADFs in location $PathtoADFFiles"
        $ListofADFFilestoCheck = Get-ChildItem $PathtoADFFiles -Recurse | Where-Object { $_.PSIsContainer -eq $false } | Get-FileHash  -Algorithm MD5
        Write-Host "Hashes calculated!"
        $ADFHashestoFind = Import-Csv $PathtoADFHashes -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Sort-Object -Property 'Sequence'
        $RequiredADFs = Import-Csv $PathtoListofInstallFiles -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $KickstartVersion} | Sort-Object -Property 'Sequence'
        #$UniqueRequiredADFs = ($RequiredADFs.FriendlyName) | Get-Unique
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
                write-host ('ADF file: '+$RequiredADF+' is missing from directory and/or hash is invalid Please check file!')
                $ErrorCount +=1
            }
        } 
    
        if ($ErrorCount -gt 0){
            exit
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

### End Functions