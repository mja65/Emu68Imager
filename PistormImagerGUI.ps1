####################################################################### Check Runtime Environment ##################################################################################################

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
 
 if  ($InteractiveMode -eq 1){
     $Scriptpath = (Split-Path -Parent $MyInvocation.MyCommand.Definition)+'\'
 } 

 if ($InteractiveMode -eq 0){
     $Scriptpath = 'C:\Users\Matt\OneDrive\Documents\Emu68Imager\'    
 }
 
 Import-Module ($Scriptpath+'Functions-GUI.psm1')

####################################################################### End Check Runtime Environment ###############################################################################################

####################################################################### Null out Global Variables ###################################################################################################


 $Global:HSTDiskName = $null
 $Global:ScreenModetoUse = $null 
 $Global:KickstartVersiontoUse = $null
 $Global:SSID = $null
 $Global:WifiPassword = $null
 $Global:SizeofFAT32 = $null 
 $Global:SizeofImage = $null 
 $Global:SizeofPartition_System = $null
 $Global:SizeofPartition_Other = $null
 $Global:WorkingPath = $null
 $Global:ROMPath = $null
 $Global:ADFPath = $null

 ####################################################################### End Null out Global Variables ###############################################################################################

 ####################################################################### Set Script Path dependent  Variables ########################################################################################

 $SourceProgramPath=($Scriptpath+'Programs\')
 $InputFolder=($Scriptpath+'InputFiles\')
 $LocationofAmigaFiles=($Scriptpath+'AmigaFiles\')

 ####################################################################### End Script Path dependent  Variables ########################################################################################

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
        Title="MainWindow" Height="450" Width="900" ResizeMode="NoResize" UseLayoutRounding="True">
    <Grid>
        <Grid Background="#FFE5E5E5" Margin="-1,0,1,0">
            <Button x:Name="Start_Button" Content="Button" HorizontalAlignment="Left" Margin="749,365,0,0" VerticalAlignment="Top" Width="127"/>
            <ComboBox x:Name="ScreenMode_Dropdown" HorizontalAlignment="Left" Margin="576,79,0,0" VerticalAlignment="Top" Width="300"/>
            <ComboBox x:Name="KickstartVersion_DropDown" HorizontalAlignment="Left" Margin="16,259,0,0" VerticalAlignment="Top" Width="200"/>
            <Button x:Name="Rompath_Button" Content="Button" HorizontalAlignment="Left" Margin="10,290,0,0" VerticalAlignment="Top" Width="160" Height="30"/>
            <Button x:Name="ADFpath_Button" Content="Button" HorizontalAlignment="Left" Margin="10,325,0,0" VerticalAlignment="Top" Width="160" Height="30"/>
            <Label x:Name="ScreenMode_Label" Content="Label" HorizontalAlignment="Left" Margin="554,38,0,0" VerticalAlignment="Top" Width="300" HorizontalContentAlignment="Center"/>
            <Label x:Name="KickstartVersion_Label" Content="Label" HorizontalAlignment="Left" Margin="16,228,0,0" VerticalAlignment="Top" Width="200" HorizontalContentAlignment="Center"/>
            <Button x:Name="MigratedFiles_Button" Content="Button" HorizontalAlignment="Left" Margin="10,360,0,0" VerticalAlignment="Top" Width="160" Height="30"/>
            <Label x:Name="RomPath_Label" Content="PLACEHOLDER" HorizontalAlignment="Left" Margin="180,290,0,0" VerticalAlignment="Top" Width="188"/>
            <Label x:Name="MigratedPath_Label" Content="PLACEHOLDER" HorizontalAlignment="Left" Margin="180,360,0,0" VerticalAlignment="Top" Width="188"/>
            <Label x:Name="ADFPath_Label" Content="PLACEHOLDER" HorizontalAlignment="Left" Margin="180,325,0,0" VerticalAlignment="Top" Width="188"/>
            <Label x:Name="SSID_Label" Content="Label" HorizontalAlignment="Left" Margin="554,155,0,0" VerticalAlignment="Top" Width="152" />
            <Label x:Name="Password_Label" Content="Label" HorizontalAlignment="Left" Margin="554,189,0,0" VerticalAlignment="Top" Width="152"/>
            <TextBox x:Name="SSID_Textbox" HorizontalAlignment="Left" Margin="721,155,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="120"/>
            <TextBox x:Name="Password_Textbox" HorizontalAlignment="Left" Margin="721,189,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="120"/>
            <ComboBox x:Name="MediaSelect_DropDown" HorizontalAlignment="Left" Margin="10,40,0,0" VerticalAlignment="Top" Width="341"/>
            <Label x:Name="MediaSelect_Label" Content="Label" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="315" HorizontalContentAlignment="Center"/>
            <Button x:Name="MediaSelect_Refresh" Content="Button" HorizontalAlignment="Left" Margin="376,38,0,0" VerticalAlignment="Top"/>
            <TextBox x:Name="ImageSize_Value" Text="" HorizontalAlignment="Left" Margin="140,79,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120"/>
            <Label x:Name="ImageSize_Label" Content="Label" HorizontalAlignment="Left" Margin="265,75,0,0" VerticalAlignment="Top" Width="200"/>
            <Label x:Name="WorkbenchSize_Label" Content="Label" HorizontalAlignment="Left" Margin="10,127,0,0" VerticalAlignment="Top" Width="121" Height="26" HorizontalContentAlignment="Center"/>
            <TextBox x:Name="WorkbenchSize_Value" Text="" HorizontalAlignment="Left" Margin="9,174,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120"/>
            <TextBox x:Name="WorkSize_Value" Text="" HorizontalAlignment="Left" Margin="286,176,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="130"/>
            <Label x:Name="WorkSize_Label" Content="Label" HorizontalAlignment="Left" Margin="282,127,0,0" VerticalAlignment="Top" Width="130" HorizontalContentAlignment="Center"/>
            <TextBox x:Name="FAT32Size_Value" Text="" HorizontalAlignment="Left" Margin="140,202,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="120"/>
            <Label x:Name="FAT32Size_Label" Content="Label" HorizontalAlignment="Left" Margin="266,197,0,0" VerticalAlignment="Top" Width="184"/>
            <Slider x:Name="ImageSize_Slider" HorizontalAlignment="Left" Margin="16,73,0,0" VerticalAlignment="Top" Width="120" Maximum="100" TickPlacement="TopLeft" AutoToolTipPlacement="BottomRight" LargeChange="0.5" SmallChange="0.1" IsSnapToTickEnabled="True" TickFrequency="0.1" />
            <Slider x:Name="WorkbenchSize_Slider" HorizontalAlignment="Left" Margin="133,169,0,0" VerticalAlignment="Top" Width="120" Maximum="{Binding Value, ElementName=ImageSize_Slider, UpdateSourceTrigger=PropertyChanged}" TickPlacement="TopLeft" AutoToolTipPlacement="BottomRight" LargeChange="0.5" SmallChange="0.1" IsSnapToTickEnabled="True" TickFrequency="0.1"/>
            <Slider x:Name="WorkSize_Slider" HorizontalAlignment="Left" Margin="504,285,0,0" VerticalAlignment="Top" Width="120" Maximum="{Binding Value, ElementName=ImageSize_Slider, UpdateSourceTrigger=PropertyChanged}" TickPlacement="TopLeft" AutoToolTipPlacement="BottomRight" LargeChange="0.5" SmallChange="0.1" Visibility="Hidden" IsSnapToTickEnabled="True" TickFrequency="0.1"/>
            <Slider x:Name="FAT32Size_Slider" HorizontalAlignment="Left" Margin="16,202,0,0" VerticalAlignment="Top" Width="120" Maximum="{Binding Value, ElementName=ImageSize_Slider, UpdateSourceTrigger=PropertyChanged}" TickPlacement="TopLeft" AutoToolTipPlacement="BottomRight" LargeChange="0.5" SmallChange="0.1" IsSnapToTickEnabled="True" TickFrequency="0.1"/>
            <Label x:Name="WorkbenchSize_Label2ndLine" Content="Label" HorizontalAlignment="Left" Margin="9,143,0,0" VerticalAlignment="Top" Width="121" Height="26" HorizontalContentAlignment="Center"/>
            <Label x:Name="Worksize_Label2ndLine" Content="Label" HorizontalAlignment="Left" Margin="286,143,0,0" VerticalAlignment="Top" Width="121" Height="26" HorizontalContentAlignment="Center"/>

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

$WPF_UI_SSID_Textbox.Text=''
$WPF_UI_Password_Textbox.Text=''
$WPF_UI_RomPath_Label.Content='No ROM path selected'
$WPF_UI_ADFPath_Label.Content='No ADF path selected'
$WPF_UI_MigratedPath_Label.Content='No transfer path selected'
$WPF_UI_ImageSize_Slider.Maximum = 0
$WPF_UI_FAT32Size_Slider.Maximum = 0
$WPF_UI_WorkSize_Slider.Maximum = 0
$WPF_UI_WorkbenchSize_Slider.Maximum = 0

$WPF_UI_MediaSelect_Label.Content = 'Select Media to Use'

$RemovableMedia = Get-RemovableMedia
foreach ($Disk in $RemovableMedia){
    $WPF_UI_MediaSelect_Dropdown.AddChild($Disk.FriendlyName)
}

$WPF_UI_MediaSelect_Dropdown.Add_SelectionChanged({
    If (-not($RemovableMedia)){
        $RemovableMedia = Get-RemovableMedia
    }
    foreach ($Disk in $RemovableMedia){
        if ($Disk.FriendlyName -eq $WPF_UI_MediaSelect_DropDown.SelectedItem){
            $WPF_UI_FAT32Size_Slider.Minimum = 0.035 # Limit of Tool
            $WPF_UI_WorkSize_Slider.Minimum = 0.1
            $WPF_UI_WorkbenchSize_Slider.Minimum = 0.1
            $WPF_UI_ImageSize_Slider.Minimum = ($WPF_UI_WorkbenchSize_Slider.Minimum)+($WPF_UI_WorkSize_Slider.Minimum)+($WPF_UI_FAT32Size_Slider.Minimum)
            $WPF_UI_ImageSize_Slider.Maximum = [math]::truncate(($Disk.Size/1GB)*1000)/1000
            $WPF_UI_FAT32Size_Slider.Maximum = $WPF_UI_ImageSize_Slider.Value
            $WPF_UI_WorkSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkbenchSize_Slider.Value
            $WPF_UI_WorkbenchSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkSize_Slider.Value
            $WPF_UI_ImageSize_Slider.Value = $WPF_UI_ImageSize_Slider.Maximum 
#            $WPF_UI_WorkbenchSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkSize_Slider.Value
            $Global:HSTDiskName = $Disk.HSTDiskName
        }
    }
})


$WPF_UI_MediaSelect_Refresh.Content = 'Refresh Available Media'
$WPF_UI_MediaSelect_Refresh.Add_Click({
    $RemovableMedia = Get-RemovableMedia
    $WPF_UI_MediaSelect_Dropdown.Items.Clear()
    foreach ($Disk in $RemovableMedia){
        $WPF_UI_MediaSelect_Dropdown.AddChild($Disk.FriendlyName)
    }
})

$WPF_UI_ImageSize_Slider.Add_ValueChanged({
#    $WPF_UI_ImageSize_Slider.Value = [math]::Round($WPF_UI_ImageSize_Slider.Value,2)
    $WPF_UI_ImageSize_Value.Text = $WPF_UI_ImageSize_Slider.Value   
    $WPF_UI_FAT32Size_Slider.Maximum = $WPF_UI_ImageSize_Slider.Value
    $WPF_UI_FAT32Size_Slider.Minimum = 0.035 # Limit of Tool
    $WPF_UI_WorkSize_Slider.Minimum = 0.1
    $WPF_UI_WorkbenchSize_Slider.Minimum = 0.1
    $WPF_UI_WorkSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkbenchSize_Slider.Value
    $WPF_UI_WorkbenchSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)
#    $WPF_UI_WorkbenchSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkSize_Slider.Value
    $WPF_UI_WorkSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-($WPF_UI_WorkbenchSize_Slider.Value)
    $WPF_UI_WorkSize_Value.Text = $WPF_UI_WorkSize_Slider.Value
    $Global:SizeofFAT32 = $WPF_UI_FAT32Size_Slider.Value
    $Global:SizeofImage = $WPF_UI_ImageSize_Slider.Value
    $Global:SizeofPartition_System = $WPF_UI_WorkBenchSize_Slider.Value
    $Global:SizeofPartition_Other = $WPF_UI_WorkSize_Slider.Value
})

$WPF_UI_FAT32Size_Slider.Add_ValueChanged({
    $WPF_UI_FAT32Size_Value.Text = $WPF_UI_FAT32Size_Slider.Value
    $WPF_UI_FAT32Size_Slider.Maximum = $WPF_UI_ImageSize_Slider.Value
    $WPF_UI_FAT32Size_Slider.Minimum = 0.035 # Limit of Tool
    $WPF_UI_WorkSize_Slider.Minimum = 0.1
    $WPF_UI_WorkbenchSize_Slider.Minimum = 0.1
    $WPF_UI_WorkSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkbenchSize_Slider.Value
    $WPF_UI_WorkbenchSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)
#    $WPF_UI_WorkbenchSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkSize_Slider.Value
    $WPF_UI_WorkSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-($WPF_UI_WorkbenchSize_Slider.Value)
    $WPF_UI_WorkSize_Value.Text = $WPF_UI_WorkSize_Slider.Value
    $Global:SizeofFAT32 = $WPF_UI_FAT32Size_Slider.Value*1024                              #Convert to Megabytes
    $Global:SizeofImage = $WPF_UI_ImageSize_Slider.Value*1024*1024                         #Convert to Kilobytes
    $Global:SizeofPartition_System = $WPF_UI_WorkBenchSize_Slider.Value*1024*1024          #Convert to Kilobytes
    $Global:SizeofPartition_Other = $WPF_UI_WorkSize_Slider.Value*1024*1024                #Convert to Kilobytes
})

$WPF_UI_WorkbenchSize_Slider.Add_ValueChanged({
    $WPF_UI_WorkbenchSize_Value.Text = $WPF_UI_WorkbenchSize_Slider.Value
    $WPF_UI_FAT32Size_Slider.Maximum = $WPF_UI_ImageSize_Slider.Value
    $WPF_UI_FAT32Size_Slider.Minimum = 0.035 # Limit of Tool
    $WPF_UI_WorkSize_Slider.Minimum = 0.1
    $WPF_UI_WorkbenchSize_Slider.Minimum = 0.1
    $WPF_UI_WorkSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkbenchSize_Slider.Value
    $WPF_UI_WorkbenchSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)
#    $WPF_UI_WorkbenchSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkSize_Slider.Value
    $WPF_UI_WorkSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-($WPF_UI_WorkbenchSize_Slider.Value)
    $WPF_UI_WorkSize_Value.Text = $WPF_UI_WorkSize_Slider.Value
    $Global:SizeofFAT32 = $WPF_UI_FAT32Size_Slider.Value*1024                           #Convert to Megabytes
    $Global:SizeofImage = $WPF_UI_ImageSize_Slider.Value*1024*1024                      #Convert to Kilobytes
    $Global:SizeofPartition_System = $WPF_UI_WorkBenchSize_Slider.Value*1024*1024       #Convert to Kilobytes  
    $Global:SizeofPartition_Other = $WPF_UI_WorkSize_Slider.Value*1024*1024             #Convert to Kilobytes
})

$WPF_UI_WorkSize_Slider.Add_ValueChanged({
    $WPF_UI_WorkSize_Value.Text = $WPF_UI_WorkSize_Slider.Value
    $WPF_UI_FAT32Size_Slider.Maximum = $WPF_UI_ImageSize_Slider.Value
    $WPF_UI_FAT32Size_Slider.Minimum = 0.035 # Limit of Tool
    $WPF_UI_WorkSize_Slider.Minimum = 0.1
    $WPF_UI_WorkbenchSize_Slider.Minimum = 0.1
    $WPF_UI_WorkSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkbenchSize_Slider.Value
    $WPF_UI_WorkbenchSize_Slider.Maximum = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)
#    $WPF_UI_WorkbenchSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-$WPF_UI_WorkSize_Slider.Value
    $WPF_UI_WorkSize_Slider.Value = ($WPF_UI_ImageSize_Slider.Value)-($WPF_UI_FAT32Size_Slider.Value)-($WPF_UI_WorkbenchSize_Slider.Value)
    $Global:SizeofFAT32 = $WPF_UI_FAT32Size_Slider.Value*1024                      #Convert to Megabytes
    $Global:SizeofImage = $WPF_UI_ImageSize_Slider.Value*1024*1024                 #Convert to Kilobytes
    $Global:SizeofPartition_System = $WPF_UI_WorkBenchSize_Slider.Value*1024*1024  #Convert to Kilobytes
    $Global:SizeofPartition_Other = $WPF_UI_WorkSize_Slider.Value*1024*1024        #Convert to Kilobytes
})

#$WPF_UI_WorkSize_Value.Add_PreviewTextInput({
#    if ($WPF_UI_WorkSize_Value.Text -match "^[\d\.]+$"){
#        return
#    }
#   else{
#   $WPF_UI_WorkSize_Value = $WPF_UI_WorkSize_Value
#   }
#})

$WPF_UI_WorkSize_Value.Add_TextChanged({
    Start-Sleep -Milliseconds 20
    if ($WPF_UI_WorkSize_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_WorkSize_Slider.Value = $WPF_UI_WorkSize_Value.Text
    }
    
})

$WPF_UI_WorkbenchSize_Value.Add_TextChanged({
    Start-Sleep -Milliseconds 20
    if ($WPF_UI_WorkBenchSize_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_WorkBenchSize_Value.Background = 'White'
        $WPF_UI_WorkBenchSize_Slider.Value = $WPF_UI_WorkBenchSize_Value.Text
    }
    else{
        $WPF_UI_WorkBenchSize_Value.Background = 'Red'
    }
})

$WPF_UI_FAT32Size_Value.Add_TextChanged({
    Start-Sleep -Milliseconds 20
    if ($WPF_UI_FAT32Size_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_FAT32Size_Value.Background = 'White'
        $WPF_UI_FAT32Size_Slider.Value = $WPF_UI_FAT32Size_Value.Text
    }
    else{
        $WPF_UI_FAT32Size_Value.Background = 'Red'
    }
})

$WPF_UI_ImageSize_Value.Add_TextChanged({
    Start-Sleep -Milliseconds 20
    if ($WPF_UI_ImageSize_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_ImageSize_Value.Background = 'White'
        $WPF_UI_ImageSize_Slider.Value = $WPF_UI_ImageSize_Value.Text
    }
    else{
        $WPF_UI_ImageSize_Value.Background = 'Red'
    }
})

$WPF_UI_Start_Button.Content = 'Run Tool'
$WPF_UI_Start_Button.Background = 'Red'

$WPF_UI_Start_Button.Width = '100'
$WPF_UI_Start_Button.Height = '20'
$WPF_UI_Start_Button.Add_Click({
    $Global:SSID = $WPF_UI_SSID_Textbox.Text
    $Global:WifiPassword = $WPF_UI_Password_Textbox.Text   
    [System.Windows.MessageBox]::Show('Checking for space on drive!','Space Check',0,32)
    $AvailableSpace = (Confirm-DiskSpace -PathtoCheck $Scriptpath)/1Mb
    $RequiredSpace = (($Global:SizeofImage*1024)/1Mb) + `
                25 + ` #Workbench
                80      #Other Files

    If ($AvailableSpace -le $RequiredSpace){
        $Msg = @'
You do not have sufficient space on your drive to run the tool!

Either select a location with sufficient space or press cancel to quit the tool
'@
        $ValueofAction = [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',1,48)
        if ($ValueofAction -eq 'OK'){
            $SufficientSpace_Flag =$null
            do {
                $Global:WorkingPath = Get-FolderPath -Message 'Select location for Working Path' -RootFolder 'MyComputer'-ShowNewFolderButton
                $AvailableSpace_revised = (Confirm-DiskSpace -PathtoCheck $Global:WorkingPath)/1Mb
                if ($AvailableSpace_revised -le $RequiredSpace){
                    $Msg = @'
You still do not have sufficient space on your drive to run the tool!
                  
Either select a location with sufficient space or press cancel to quit the tool
'@    
                    $ValueofAction = [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',1,48)
                    if ($ValueofAction -eq 'Cancel'){
                        $Form_UserInterface.Close() | out-null
                        $Global:RunMethod =2 
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
            $Global:RunMethod =2
        }      
    } 
    else {
        $Global:WorkingPath = ($Scriptpath+'Working Folder\') 
    }
    $ErrorCheck = Confirm-UIFields
    if ($ErrorCheck){
        [System.Windows.MessageBox]::Show($ErrorCheck, 'Error! Go back and correct')
    }
    else {
        $Form_UserInterface.Close() | out-null
        $Global:RunMethod = 1
    }
})

$WPF_UI_RomPath_Button.Content = 'Click to Set Rom Path'
$WPF_UI_RomPath_Button.Height = 30
$WPF_UI_RomPath_Button.Width = 160 
$WPF_UI_RomPath_Button.Add_Click({
    $Global:ROMPath = Get-FolderPath -Message 'Select path to Roms' -RootFolder 'MyComputer'
    if ($Global:ROMPath){
        if(Confirm-UIFields){
            $WPF_UI_Start_Button.Background = 'Red'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
        }
        $WPF_UI_RomPath_Label.Content = ($Global:ROMPath)
        $WPF_UI_RomPath_Button.Background = 'Green'
    }
    else{
        $WPF_UI_RomPath_Button.Background = '#FFDDDDDD'
    }
})

$WPF_UI_ADFPath_Button.Content = 'Click to Set ADF Path'
$WPF_UI_ADFPath_Button.Height = 30
$WPF_UI_ADFPath_Button.Width = 160 
$WPF_UI_ADFPath_Button.Add_Click({
    $Global:ADFPath = Get-FolderPath -Message 'Select path to ADFs' -RootFolder 'MyComputer'
    if ($Global:ADFPath){
        if(Confirm-UIFields){
            $WPF_UI_Start_Button.Background = 'Red'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
        }
        $WPF_UI_ADFPath_Label.Content=($Global:ADFPath)
        $WPF_UI_ADFPath_Button.Background = 'Green'
    } 
    else{
        $WPF_UI_ADFPath_Button.Background = '#FFDDDDDD'
    }
})

$WPF_UI_MigratedFiles_Button.Content = 'Click to Set Transfer Folder'
$WPF_UI_MigratedFiles_Button.Height = 30
$WPF_UI_MigratedFiles_Button.Width = 160
$WPF_UI_MigratedFiles_Button.Add_Click({
    $Global:TransferLocation = Get-FolderPath -Message 'Select transfer folder' -RootFolder 'MyComputer'
    if ($Global:TransferLocation){
        $WPF_UI_MigratedPath_Label.Content = ($Global:TransferLocation)
        $WPF_UI_MigratedFiles_Button.Background = 'Green'
    }
    else{
        $WPF_UI_MigratedFiles_Button.Background = '#FFDDDDDD'
    }
})

$WPF_UI_KickstartVersion_Label.Content = 'Select KickstartVersion'
$AvailableKickstarts = Import-Csv ($InputFolder+'ListofInstallFiles.csv') -delimiter ';' | Where-Object 'Kickstart_Version' -ne ""| Select-Object 'Kickstart_Version' -unique

foreach ($Kickstart in $AvailableKickstarts) {
    $WPF_UI_KickstartVersion_Dropdown.AddChild($Kickstart.Kickstart_Version)
}

$WPF_UI_KickstartVersion_Dropdown.Add_SelectionChanged({
    $Global:KickstartVersiontoUse = $WPF_UI_KickstartVersion_Dropdown.SelectedItem
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
    }
})

$WPF_UI_ScreenMode_Label.Content = 'Select ScreenMode'
$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.csv') -delimiter ';'

foreach ($ScreenMode in $AvailableScreenModes) {
    $WPF_UI_ScreenMode_Dropdown.AddChild($ScreenMode.FriendlyName)
}

$WPF_UI_ScreenMode_Dropdown.Add_SelectionChanged({
    foreach ($ScreenMode in $AvailableScreenModes) {
        if ($ScreenMode.FriendlyName -eq $WPF_UI_ScreenMode_Dropdown.SelectedItem){
            $Global:ScreenModetoUse = $ScreenMode.Name           
        }
    }
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
    }
})



$WPF_UI_ImageSize_Label.Content = 'Total Image Size (GiB)'  
$WPF_UI_WorkbenchSize_Label.Content = 'Size of Workbench'  
$WPF_UI_WorkbenchSize_Label2ndline.Content = 'Partition (GiB)'  
$WPF_UI_WorkSize_Label.Content = 'Size of Work'
$WPF_UI_WorkSize_Label2ndline.Content = 'Partition (GiB)'
$WPF_UI_FAT32Size_Label.Content = 'Size of FAT32 Partition (GiB)' 

$WPF_UI_Password_Label.Content = 'Enter your Wifi password'
$WPF_UI_SSID_Label.Content = 'Enter your SSID' 

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
    $Global:IsDisclaimerAccepted = $True
    Write-Host 'Disclaimer'
})


$Form_Disclaimer.ShowDialog() | out-null

if (-not ($Global:IsDisclaimerAccepted -eq $true)){
    Write-ErrorMessage 'Exiting - Disclaimer Not Accepted'
    exit    
}

####################################################################### End GUI XML for Disclaimer ##################################################################################################

####################################################################### Show Main Gui     ##################################################################################################################


$Form_UserInterface.ShowDialog() | out-null

if ($Global:RunMethod -eq 2){
    Write-ErrorMessage -Message 'Exiting - User has insufficient space'
    exit
}
elseif (-not ($Global:RunMethod -eq 1)){
    Write-ErrorMessage -Message 'Exiting - UI Window was closed'
    exit
}

If ($InteractiveMode -eq 0){
    Get-UICapturedData
}


#[System.Windows.Window].GetEvents() | select Name, *Method, EventHandlerType

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

$TotalSections=20

# Check Integrity of CSVs

$StartDateandTime = (Get-Date -Format HH:mm:ss)

Write-InformationMessage -Message "Starting execution at $StartDateandTime"

Write-StartTaskMessage -Message 'Performing integrity checks over input files' -SectionNumber '1' -TotalSections $TotalSections

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

Write-TaskCompleteMessage -Message 'Performing integrity checks over input files - Complete!' -SectionNumber '1' -TotalSections $TotalSections

Write-StartTaskMessage -Message 'Checking existance of folders, programs, and files' -SectionNumber '2' -TotalSections $TotalSections

if (((split-path  $Global:WorkingPath  -Parent)+'\') -eq $Scriptpath) {
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
    Write-TaskCompleteMessage -Message 'Checking existance of folders, programs, and files - Complete!' -SectionNumber '2' -TotalSections $TotalSections
}

$HDF2emu68Path=($SourceProgramPath+'hdf2emu68.exe')
$7zipPath=($SourceProgramPath+'7z.exe')

Set-Location  $Global:WorkingPath

$ProgramsFolder= $Global:WorkingPath+'Programs\'
if (-not (Test-Path $ProgramsFolder)){
    $null = New-Item $ProgramsFolder -ItemType Directory
}

$TempFolder= $Global:WorkingPath+'Temp\'
if (-not (Test-Path $TempFolder)){
    $null = New-Item $TempFolder -ItemType Directory
}

$HSTImagePath=$ProgramsFolder+'HST-Imager\hst.imager.exe'
$HSTAmigaPath=$ProgramsFolder+'HST-Amiga\hst.amiga.exe'
$LZXPath=$ProgramsFolder+'unlzx.exe'

$LocationofImage= $Global:WorkingPath+'OutputImage\'
$AmigaDrivetoCopy= $Global:WorkingPath+'AmigaImageFiles\'
$AmigaDownloads= $Global:WorkingPath+'AmigaDownloads\'
$FAT32Partition= $Global:WorkingPath+'FAT32Partition\'

## Amiga Variables

$DeviceName_Prefix = 'SDH'
$DeviceName_System = ($DeviceName_Prefix+'0')
$VolumeName_System ='Workbench'
$DeviceName_Other = ($DeviceName_Prefix+'1')
$VolumeName_Other = 'Work'
$MigratedFilesFolder='My Files'
$PFSLimit = 101*1024*1024 #Kilobytes
#$InstallPathMUI='SYS:Programs/MUI'
#$InstallPathPicasso96='SYS:Programs/Picasso96'
#$InstallPathAmiSSL='SYS:Programs/AmiSSL'
$GlowIcons='TRUE'

$NameofImage=('Pistorm'+$KickstartVersiontoUse+'.HDF')

### Clean up

Write-StartTaskMessage -Message 'Performing Cleanup' -SectionNumber '3' -TotalSections $TotalSections

$NewFolders = ((split-path $TempFolder -leaf),(split-path $LocationofImage -leaf),((Split-Path $AmigaDrivetoCopy -Leaf)+'\'+$VolumeName_System),((Split-Path $AmigaDrivetoCopy -Leaf)+'\'+$VolumeName_Other),(split-path $FAT32Partition -leaf))

try {
    foreach ($NewFolder in $NewFolders) {
        if (Test-Path ( $Global:WorkingPath+$NewFolder)){
            $null = Remove-Item ( $Global:WorkingPath+$NewFolder) -Recurse -ErrorAction Stop
        }
        $null = New-Item -path ( $Global:WorkingPath) -Name $NewFolder -ItemType Directory
    }    
}
catch {
    Write-ErrorMessage -Message "Cannot delete temporary files!"
    exit    
}

if (-not(Test-Path ( $Global:WorkingPath+'AmigaDownloads'))){
    $null = New-Item -path ( $Global:WorkingPath) -Name 'AmigaDownloads' -ItemType Directory    
}

if (-not(Test-Path ( $Global:WorkingPath+'Programs'))){
    $null = New-Item -path ( $Global:WorkingPath) -Name 'Programs' -ItemType Directory      
}

Write-TaskCompleteMessage -Message 'Performing Cleanup - Complete!' -SectionNumber '3' -TotalSections $TotalSections

### End Clean up

### Determine Kickstart Rom Path

#Update-OutputWindow -OutputConsole_Title_Text 'Determining Kickstarts to Use' -ProgressbarValue_Overall 7 -ProgressbarValue_Overall_Text '7%'

Write-StartTaskMessage -Message 'Determining Kickstarts to Use' -SectionNumber '4' -TotalSections $TotalSections

$FoundKickstarttoUse = Compare-KickstartHashes -PathtoKickstartHashes ($InputFolder+'RomHashes.csv') -PathtoKickstartFiles $Global:ROMPath -KickstartVersion $KickstartVersiontoUse

$KickstartPath = $FoundKickstarttoUse.KickstartPath

if (-not($KickstartPath)){
    Write-ErrorMessage -Message "Error! No Kickstart file found!"
    exit
} 

$KickstartNameFAT32=$FoundKickstarttoUse.Fat32Name

Write-InformationMessage -Message ('Kickstart to be used is: '+$KickstartPath)

Write-TaskCompleteMessage -Message 'Determining Kickstarts to Use - Complete!' -SectionNumber '4' -TotalSections $TotalSections

Write-StartTaskMessage -Message 'Determining ADFs to Use' -SectionNumber '5' -TotalSections $TotalSections

$AvailableADFs = Compare-ADFHashes -PathtoADFFiles $Global:ADFPath -PathtoADFHashes ($InputFolder+'ADFHashes.csv') -KickstartVersion $KickstartVersiontoUse -PathtoListofInstallFiles ($InputFolder+'ListofInstallFiles.csv') 

if (-not ($AvailableADFs)){
    Write-ErrorMessage -Message "One or more ADF files is missing!"
    exit
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

Write-InformationMessage -Message 'ADF install images to be used are:'
$ListofInstallFiles |  Select-Object Path,FriendlyName -Unique | ForEach-Object {
    Write-InformationMessage -Message ($_.FriendlyName+' ('+$_.Path+')')
} 

Write-TaskCompleteMessage -Message 'Determining ADFs to Use - Complete!' -SectionNumber '5' -TotalSections $TotalSections

### Download HST-Imager and HST-Amiga

Write-StartTaskMessage -Message 'Downloading HST Packages' -SectionNumber '6' -TotalSections $TotalSections

Write-StartSubTaskMessage -Message 'Downloading HST Imager' -SubtaskNumber '1' -TotalSubtasks '2'

if (-not(Get-GithubRelease -GithubRelease $HSTImagerreleases -Tag_Name '1.1.350' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTImager.zip') -LocationforProgram ($ProgramsFolder+'HST-Imager\') -Sort_Flag '')){
    Write-ErrorMessage -Message 'Error downloading HST-Imager! Cannot continue!'
    exit
}

Write-StartSubTaskMessage -Message 'Downloading HST Amiga' -SubtaskNumber '2' -TotalSubtasks '2'

if (-not(Get-GithubRelease -GithubRelease $HSTAmigareleases -Tag_Name '0.3.163' -Name '_console_windows_x64.zip' -LocationforDownload ($TempFolder+'HSTAmiga.zip') -LocationforProgram ($ProgramsFolder+'HST-Amiga\') -Sort_Flag '')){
    Write-ErrorMessage -Message 'Error downloading HST-Amiga! Cannot continue!'
    exit
}

Write-TaskCompleteMessage -Message 'Downloading HST Packages - Complete!' -SectionNumber '6' -TotalSections $TotalSections

#### Download Emu68 Files

Write-StartTaskMessage -Message 'Downloading Emu68 Packages' -SectionNumber '7' -TotalSections $TotalSections

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

Write-Host "Downloading Emu68Pistorm"
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

Write-TaskCompleteMessage -Message 'Downloading Emu68 Packages - Complete' -SectionNumber '7' -TotalSections $TotalSections

### End Download Emu68

### Begin Download UnLzx

Write-StartTaskMessage -Message 'Downloading UnLZX' -SectionNumber '8' -TotalSections $TotalSections

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

Write-TaskCompleteMessage -Message 'Downloading LZX - Complete!' -SectionNumber '8' -TotalSections $TotalSections

### End Download UnLzx

## Setting up Amiga Partitions List

$SizeofImagetouse = (([math]::truncate($Global:SizeofImage)).ToString()+'kb')
$SizeofPartition_Systemtouse = (([math]::truncate($Global:SizeofPartition_System)).ToString()+'kb')
$SizeofPartition_Othertouse = ([math]::truncate($Global:SizeofPartition_Other))
$SizeofFAT32touse = ([math]::truncate($Global:SizeofFAT32)).ToString()

$AmigaPartitionsList = [System.Collections.Generic.List[PSCustomObject]]::New()

$PartitionNumbertoPopulate =1

$AmigaPartitionsList += [PSCustomObject]@{
    PartitionNumber = $PartitionNumbertoPopulate 
    SizeofPartition =  $SizeofPartition_Systemtouse
    DosType = 'PFS3'
    VolumeName = $VolumeName_System
    DeviceName = $DeviceName_System  
}

$PartitionNumbertoPopulate ++
$CapacitytoFill = $SizeofPartition_Othertouse

$TotalNumberWorkPartitions = [math]::ceiling($CapacitytoFill/$PFSLimit)

$WorkPartitionSize = $SizeofPartition_Othertouse/$TotalNumberWorkPartitions

do {
    if ($PartitionNumbertoPopulate -eq 2){
        $VolumeNametoPopulate = $VolumeName_Other
        $DeviceNametoPopulate = $DeviceName_Other
    }
    else{
        $VolumeNametoPopulate = ($VolumeName_Other+(($PartitionNumbertoPopulate-1).ToString()))
        $DeviceNametoPopulate = ($DeviceName_Prefix+(($PartitionNumbertoPopulate-1).ToString()))
       
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

Write-StartTaskMessage -Message 'Preparing Amiga Image' -SectionNumber '9' -TotalSections $TotalSections

if (-not (Start-HSTImager -Command "Blank" -DestinationPath ($LocationofImage+$NameofImage) -ImageSize $SizeofImagetouse -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 
if (-not (Start-HSTImager -Command "rdb init" -DestinationPath ($LocationofImage+$NameofImage) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 
if (-not (Start-HSTImager -Command "rdb filesystem add" -DestinationPath ($LocationofImage+$NameofImage) -FileSystemPath ($Global:WorkingPath+'Programs\HST-Imager\pfs3aio') -DosType 'PFS3' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 

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

#### Begin - Create NewFolder.info file
if (($KickstartVersiontoUse -eq 3.1) -or (($KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'FALSE'))) {
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\Monitors.info') -DestinationPath ($TempFolder.TrimEnd('\'))  -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    }
    if (Test-Path ($TempFolder+'def_drawer.info')){
        $null = Remove-Item ($TempFolder+'def_drawer.info')
    }
    $null = Rename-Item ($TempFolder+'Monitors.info') ($TempFolder+'def_drawer.info')
}
elseif(($KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'TRUE')){
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

if ($KickstartVersiontouse -eq 3.1){

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

if ($KickstartVersiontoUse -eq 3.1){
    $SourcePath = ($InstallADF+'\Update\disk.info') 
}

elseif ($KickstartVersiontoUse -eq 3.2){
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
    if (($AmigaPartition.PartitionNumber -le 3) -and ($KickstartVersiontoUse -eq 3.2)) {
        Rename-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\def_harddisk.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info') 
    }
}

Write-TaskCompleteMessage -Message 'Preparing Amiga Image - Complete!' -SectionNumber '9' -TotalSections $TotalSections

### End Basic Drive Setup

### Begin Copy Install files from ADF

Write-StartTaskMessage -Message 'Processing and Installing ADFs' -SectionNumber '10' -TotalSections $TotalSections

$TotalItems=$ListofInstallFiles.Count

$ItemCounter=1

Foreach($InstallFileLine in $ListofInstallFiles){
    Write-StartSubTaskMessage -SubtaskNumber $ItemCounter -TotalSubtasks $TotalItems -Message ('Processing ADF:'+$InstallFileLine.FriendlyName+' Files: '+$InstallFileLine.AmigaFiletoInstall)
    $SourcePathtoUse = ($InstallFileLine.Path+'\'+($InstallFileLine.AmigaFiletoInstall -replace '/','\'))
    if ($InstallFileLine.Uncompress -eq "TRUE"){
        WWrite-InformationMessage -Message 'Extracting files from ADFs containing .Z files'
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

Write-TaskCompleteMessage -Message 'Processing and Installing ADFs - Complete!' -SectionNumber '10' -TotalSections $TotalSections

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

Write-StartTaskMessage -Message 'Downloading Packages' -SectionNumber '11' -TotalSections $TotalSections


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
                    Expand-LZXArchive -LZXPathtouse $LZXPath -WorkingFoldertouse  $Global:WorkingPath -LZXFile ($AmigaDownloads+$PackagetoFind.FileDownloadName) -TempFoldertouse $TempFolder -DestinationPath ($TempFolder+$PackagetoFind.FileDownloadName) 
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

Write-TaskCompleteMessage -Message 'Downloading Packages - Complete!' -SectionNumber '11' -TotalSections $TotalSections

$PackageCheck=$null
$UserStartup=$null
$StartupSequence = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\Startup-Sequence') 
$StartupSequenceversion = Get-StartupSequenceVersion -StartupSequencetoCheck $StartupSequence

Write-StartTaskMessage -Message 'Installing Packages' -SectionNumber '12' -TotalSections $TotalSections

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

Write-TaskCompleteMessage -Message 'Installing Packages -Complete!' -SectionNumber '12' -TotalSections $TotalSections

Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\Startup-Sequence') -DatatoExport $StartupSequence -AddLineFeeds 'TRUE'
Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\S\User-Startup') -DatatoExport $UserStartup -AddLineFeeds 'TRUE'

### Wireless Prefs

#Update-OutputWindow -OutputConsole_Title_Text 'Creating Wireless Prefs file' -ProgressbarValue_Overall 50 -ProgressbarValue_Overall_Text '50%'

Write-StartTaskMessage -Message 'Creating Wireless Prefs file' -SectionNumber '13' -TotalSections $TotalSections

if (-not (Test-Path ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\'))){
    $null = New-Item -path ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys') -ItemType Directory -Force 

}

$WirelessPrefs = "network={",
                 "   ssid=""$SSID""",
                 "   psk=""$WifiPassword""",
                 "}"
                 
Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\wireless.prefs') -DatatoExport $WirelessPrefs -AddLineFeeds 'TRUE'                

Write-TaskCompleteMessage -Message 'Creating Wireless Prefs File - Complete!' -SectionNumber '13' -TotalSections $TotalSections

### End Wireless Prefs

### Fix WBStartup

Write-StartTaskMessage -Message 'Fix WBStartup' -SectionNumber '14' -TotalSections $TotalSections

If ($KickstartVersiontouse -eq 3.2){
    Write-Host 'Fixing Menutools'
    if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\WBStartup\MenuTools') -DestinationPath ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup') -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
        exit
    }
    
    $WBStartup = Import-TextFileforAmiga -SystemType 'Amiga' -ImportFile ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\Menutools') 
    $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Wait' -Injectionpoint 'after' -Startpoint 'ADDRESS WORKBENCH' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_1')) -ArexxFlag 'AREXX'
    $WBStartup = Edit-AmigaScripts -ScripttoEdit $WBStartup -Action 'inject' -Name 'Add Offline and Online Menus' -Injectionpoint 'before' -Startpoint 'EXIT' -LinestoAdd (Import-TextFileforAmiga -SystemType 'PC' -ImportFile ($LocationofAmigaFiles+'WBStartup\Menutools_2')) -ArexxFlag 'AREXX'
    
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\WBStartup\Menutools') -DatatoExport $WBStartup -AddLineFeeds 'TRUE'
}

Write-TaskCompleteMessage -Message 'Fix WB Startup - Complete!' -SectionNumber '14' -TotalSections $TotalSections

## Clean up AmigaImageFiles

Write-StartTaskMessage -Message 'Clean up AmigaImageFiles' -SectionNumber '15' -TotalSections $TotalSections

if (Test-Path ($AmigaDrivetoCopy+$VolumeName_System+'\Disk.info')){
    Remove-Item ($AmigaDrivetoCopy+$VolumeName_System+'\Disk.info')
}

Write-TaskCompleteMessage -Message 'Clean up AmigaImageFiles - Complete!' -SectionNumber '15' -TotalSections $TotalSections

#### Set up FAT32

Write-StartTaskMessage -Message 'Setting up FAT32 files' -SectionNumber '16' -TotalSections $TotalSections

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

Copy-Item ($LocationofAmigaFiles+'FAT32\cmdline_'+$KickstartVersiontoUse+'.txt') -Destination ($FAT32Partition+'cmdline.txt') #Temporary workaround until Michal fixes buptest for 3.1


$ConfigTxt = Get-Content -Path ($LocationofAmigaFiles+'FAT32\config.txt')

Write-InformationMessage -Message 'Preparing Config.txt'

$RevisedConfigTxt=$null

$AvailableScreenModes = Import-Csv ($InputFolder+'ScreenModes.CSV') -Delimiter (';')
foreach ($AvailableScreenMode in $AvailableScreenModes){
    if ($AvailableScreenMode.Name -eq  $Global:ScreenModetoUse){
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

Write-TaskCompleteMessage -Message 'Setting up FAT32 Files - Complete!' -SectionNumber '16' -TotalSections $TotalSections


Write-StartTaskMessage -Message 'Transferring Migrated Files to Work Partition' -SectionNumber '17' -TotalSections $TotalSections

### Transfer files to Work partition

if ($TransferLocation) {
    # Determine Size of transfer
    $SizeofFilestoTransfer=(Get-ChildItem $TransferLocation -force -Recurse | Where-Object { $_.PSIsContainer -eq $false }  | Measure-Object -property Length -sum).sum /1Mb
    Write-Host ('Transferring files from '+$TransferLocation+' to "'+$MigratedFilesFolder+'" directory on Work drive')
    Write-Host ('Total size of files to be transferred is: '+(([Math]::Round($SizeofFilestoTransfer, 2)).tostring())+'mb')
    Write-Host ('Available space on Work drive is: '+$SizeofPartition_Other)
    if ($SizeofFilestoTransfer -lt (([double]($SizeofPartition_Other.trim('mb')))+10)){
        $SourcePathtoUse = $TransferLocation+('*')
        if (Test-Path ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')){
            Remove-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')
        }
        $null = Copy-Item ($TempFolder+'NewFolder.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\'+$MigratedFilesFolder+'.info')
        if (-not(Start-HSTImager -Command 'fs copy' -SourcePath $SourcePathtoUse -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_Other+'\'+$MigratedFilesFolder) -HSTImagePathtouse $HSTImagePath -TempFoldertouse $TempFolder)){
            exit
        }
    }
    else{
        Write-host "Size of files to be transferred is too large for the Work partition! Not transferring!"
    }
}

Write-TaskCompleteMessage -Message 'Transferring Migrated Files to Work Partition - Complete!' -SectionNumber '17' -TotalSections $TotalSections

Write-StartTaskMessage -Message 'Transferring Amiga Files to Image' -SectionNumber '18' -TotalSections $TotalSections

if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_System) -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_System) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 
if (-not(Start-HSTImager -Command 'fs copy' -SourcePath ($AmigaDrivetoCopy+$VolumeName_Other) -DestinationPath ($LocationofImage+$NameofImage+'\rdb\'+$DeviceName_Other) -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
}  

Write-TaskCompleteMessage -Message 'Transferring Amiga Files to Image - Complete!' -SectionNumber '18' -TotalSections $TotalSections

Write-StartTaskMessage -Message 'Creating Image' -SectionNumber '19' -TotalSections $TotalSections

Set-Location $LocationofImage

#Update-OutputWindow -OutputConsole_Title_Text 'Creating Image' -ProgressbarValue_Overall 83 -ProgressbarValue_Overall_Text '83%'

& $HDF2emu68Path $LocationofImage$NameofImage $SizeofFAT32 ($FAT32Partition).Trim('\')

$null= Rename-Item ($LocationofImager+'emu68_converted.img') -NewName ('Emu68Kickstart'+$KickstartVersiontoUse+'.img')

Write-TaskCompleteMessage -Message 'Creating Image - Complete!' -SectionNumber '19' -TotalSections $TotalSections

Write-StartTaskMessage -Message 'Writing Image to Disk' -SectionNumber '20' -TotalSections $TotalSections

Set-location  $Global:WorkingPath

Write-Image -HSTImagePathtouse $HSTImagePath -SourcePath ($LocationofImage+'Emu68Kickstart'+$KickstartVersiontoUse+'.img') -DestinationPath $HSTDiskName

Write-TaskCompleteMessage -Message 'Writing Image to Disk - Complete!' -SectionNumber '20' -TotalSections $TotalSections

$EndDateandTime = (Get-Date -Format HH:mm:ss)
$ElapsedTime = (New-TimeSpan -Start $StartDateandTime -End $EndDateandTime).TotalSeconds

Write-Host "Started at: $StartDateandTime Finished at: $EndDateandTime. Total time to run (in seconds) was: $ElapsedTime" 
