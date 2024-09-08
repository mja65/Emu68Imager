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

Import-Module ($Scriptpath+'Functions-GUI.psm1')

####################################################################### End Check Runtime Environment ###############################################################################################

####################################################################### Set Script Path dependent  Variables ########################################################################################

$SourceProgramPath=($Scriptpath+'Programs\')
$InputFolder=($Scriptpath+'InputFiles\')
$LocationofAmigaFiles=($Scriptpath+'AmigaFiles\')

####################################################################### End Script Path dependent  Variables ########################################################################################

####################################################################### Null out Global Variables ###################################################################################################

$Global:ExitType = $null
$Global:HSTDiskName = $null
$Global:ScreenModetoUse = $null 
$Global:KickstartVersiontoUse = $null
$Global:SSID = $null
$Global:WifiPassword = $null
$Global:SizeofFAT32 = $null 
$Global:SizeofImage = $null
$Global:SizeofImage_HST = $null
$Global:SizeofPartition_System = $null
$Global:SizeofPartition_Other = $null
$Global:WorkingPath = $null
$Global:ROMPath = $null
$Global:ADFPath = $null
$Global:TransferLocation = $null
$Global:Space_WorkingFolderDisk = $null
$Global:AvailableSpace_WorkingFolderDisk = $null
$Global:RequiredSpace_WorkingFolderDisk = $null
$Global:AvailableSpaceFilestoTransfer = $null
$Global:SizeofFilestoTransfer = $null
$Global:SpaceThreshold_WorkingFolderDisk  = $null
$Global:SpaceThreshold_FilestoTransfer = $null
$Global:Space_FilestoTransfer = $null
$Global:PFSLimit =$null
$Global:WriteImage = $null
$Global:TotalSections = $null
$Global:CurrentSection = $null
$Global:SetDiskupOnly = $null
$Global:PartitionBarPixelperKB = $null

####################################################################### End Null out Global Variables ###############################################################################################
 
 ####################################################################### Set Global Variables ###############################################################################################
 
 $Global:PFSLimit = 101*1024*1024 #Kilobytes

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
                        <ListViewItem x:Name="Unallocated_ListViewItem" Content="Unallocated Space" Height="30" HorizontalContentAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </ListView>
              </Grid>

               <TextBox x:Name="Fat32Size_Label" HorizontalAlignment="Left" Margin="36,84,0,0" TextWrapping="Wrap" Text="FAT32 (GiB)" VerticalAlignment="Top" Width="82" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
               <TextBox x:Name="WorkbenchSize_Label" HorizontalAlignment="Left" Margin="167,84,0,0" TextWrapping="Wrap" Text="Workbench (GiB)" VerticalAlignment="Top" Width="113" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
               <TextBox x:Name="WorkSize_Label" HorizontalAlignment="Left" Margin="309,84,0,0" TextWrapping="Wrap" Text="Work (GiB)" VerticalAlignment="Top" Width="63" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
               <TextBox x:Name="Unallocated_Label" HorizontalAlignment="Left" Margin="771,84,0,0" TextWrapping="Wrap" Text="Unallocated (GiB)" VerticalAlignment="Top" Width="105" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
               <TextBox x:Name="ImageSize_Label" HorizontalAlignment="Left" Margin="571,84,0,0" TextWrapping="Wrap" Text="Total Image Size (GiB)" VerticalAlignment="Top" Width="144" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
               <TextBox x:Name="FreeSpace_Label" HorizontalAlignment="Left" Margin="427,84,0,0" TextWrapping="Wrap" Text="Free Space (GiB)" VerticalAlignment="Top" Width="108" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

               <TextBox x:Name="FAT32Size_Value" Text="" HorizontalAlignment="Left" Margin="20,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
               <TextBox x:Name="WorkbenchSize_Value" Text="" HorizontalAlignment="Left" Margin="162,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
               <TextBox x:Name="WorkSize_Value" Text="" HorizontalAlignment="Left" Margin="278,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
               <TextBox x:Name="Unallocated_Value" Text="0" HorizontalAlignment="Left" Margin="780,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False" BorderBrush="Transparent"/>
               <TextBox x:Name="ImageSize_Value" Text="" HorizontalAlignment="Left" Margin="582,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>
               <TextBox x:Name="FreeSpace_Value" Text="" HorizontalAlignment="Left" Margin="419,106,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" IsEnabled="False"/>

               <Rectangle x:Name="Fat32_Key" HorizontalAlignment="Left" Height="10" Margin="22,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FF3B67A2" />
               <Rectangle x:Name="Workbench_Key" HorizontalAlignment="Left" Height="10" Margin="154,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FFFFA997"  />
               <Rectangle x:Name="Work_Key" HorizontalAlignment="Left" Height="10" Margin="295,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FFAA907C"  />
               <Rectangle x:Name="FreeSpace_Key" HorizontalAlignment="Left" Height="10" Margin="414,90,0,0" VerticalAlignment="Top" Width="10" Fill="#FF7B7B7B" />
               <Rectangle x:Name="Unallocated_Key" HorizontalAlignment="Left" Height="10" Margin="756,88,0,0" VerticalAlignment="Top" Width="10" Fill="#FFAFAFAF"  />              
 
              <TextBox x:Name="MediaSelect_Label" HorizontalAlignment="Left" Margin="10,10,0,0" TextWrapping="Wrap" Text="Select Media to Use" VerticalAlignment="Top" Width="120" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
              <ComboBox x:Name="MediaSelect_DropDown"  HorizontalAlignment="Left" Margin="130,8,0,0" VerticalAlignment="Top" Width="340"/>
              <Button x:Name="MediaSelect_Refresh" Content="Refresh Available Media" HorizontalAlignment="Left" Margin="482,9,0,0" VerticalAlignment="Top" Width="130" Height="20"/>
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
              <TextBox x:Name="MigratedPath_Label" HorizontalAlignment="Left" Margin="215,139,0,0" TextWrapping="Wrap" Text="No transfer path selected" VerticalAlignment="Top" Width="200" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
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
      <Button x:Name="Start_Button" Content="Run Tool" HorizontalAlignment="Center" Margin="0,489,0,0" VerticalAlignment="Top" Width="880" Height="38"/>
      <GroupBox x:Name="Space_GroupBox" Header="Space Requirements" Height="150" Background="Transparent" Margin="0,311,10,0" Width="400" VerticalAlignment="Top" HorizontalAlignment="Right">
          <Grid>
                <TextBox x:Name="RequiredSpace_TextBox" HorizontalAlignment="Left" Margin="40,9,0,0" TextWrapping="Wrap" Text="Space to run tool is:" VerticalAlignment="Top" Width="112" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="AvailableSpace_TextBox" HorizontalAlignment="Left" Margin="40,67,0,0" TextWrapping="Wrap" Text="Available space is:" VerticalAlignment="Top" Width="101" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="RequiredSpaceTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="40,49,0,0" TextWrapping="Wrap" Text="Space for transferred files:" VerticalAlignment="Top" Width="147" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="AvailableSpaceTransferredFiles_TextBox" HorizontalAlignment="Left" Margin="40,28,0,0" TextWrapping="Wrap" Text="Available space is:" VerticalAlignment="Top" Width="101" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="RequiredSpaceValue_TextBox" HorizontalAlignment="Right" Margin="281,49,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="AvailableSpaceValue_TextBox" HorizontalAlignment="Right" Margin="266,70,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Green" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="RequiredSpaceValueTransferredFiles_TextBox" HorizontalAlignment="Right" Margin="280,7,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>
                <TextBox x:Name="AvailableSpaceValueTransferredFiles_TextBox" HorizontalAlignment="Right" Margin="281,27,0,0" TextWrapping="Wrap" Text="XXX GiB" VerticalAlignment="Top" Width="100" BorderBrush="Transparent" Background="Transparent" IsReadOnly="True" IsUndoEnabled="False" IsTabStop="False" IsHitTestVisible="False" Focusable="False"/>

          </Grid>

      </GroupBox>
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

$Global:PartitionBarWidth =  857

# $Global:PartitionBarWidth = $WPF_UI_FAT32Size_ListViewItem.ActualWidth + `
#                      $WPF_UI_WorkbenchSize_ListViewItem.ActualWidth + ` 
#                      $WPF_UI_WorkSize_ListViewItem.ActualWidth + `
#                      $WPF_UI_ImageSize_ListViewItem.ActualWidth + `
#                      $WPF_UI_Disk_Listview.ActualWidth
$Global:SetDiskupOnly = 'FALSE'
$DefaultDivisorFat32 = 15
$DefaultDivisorWorkbench = 15
$Global:Fat32DefaultMaximum = 1024*1024 #1gb in Kilobytes
$Global:WorkbenchMaximum = 1024*1024 #1gb in Kilobytes
$Global:Fat32Maximum = 4*1024*1024 # in Kilobytes
$Global:Fat32Minimum = 35840 # In KiB
$Global:WorkbenchMinimum = 100*1024 # In KiB
$Global:WorkMinimum = 10*1024 # In KiB

$Global:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Scriptpath)/1Kb # Available Space on Drive where script is running (Kilobytes)
$Global:AvailableSpace_WorkingFolderDisk = $Global:Space_WorkingFolderDisk
$Global:RequiredSpace_WorkingFolderDisk = 0 #In Kilobytes

$Global:Space_FilestoTransfer = 0 #In Kilobytes
$Global:AvailableSpaceFilestoTransfer = 0 #In Kilobytes
$Global:SizeofFilestoTransfer = 0 #In Kilobytes

$Global:SpaceThreshold_WorkingFolderDisk = 500*1024 #In Kilobytes
$Global:SpaceThreshold_FilestoTransfer = 10*1024 #In Kilobytes

$WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Global:AvailableSpace_WorkingFolderDisk 
$WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Global:RequiredSpace_WorkingFolderDisk

$WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = '' 
$WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = ''

$RemovableMedia = Get-RemovableMedia
foreach ($Disk in $RemovableMedia){
    $WPF_UI_MediaSelect_Dropdown.AddChild($Disk.FriendlyName)
}

$WPF_UI_MediaSelect_Dropdown.Add_SelectionChanged({
    If (-not($RemovableMedia)){
        $RemovableMedia = Get-RemovableMedia
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

        foreach ($Disk in $RemovableMedia){        
            if ($Disk.FriendlyName -eq $WPF_UI_MediaSelect_DropDown.SelectedItem){
                $Global:HSTDiskName = $Disk.HSTDiskName
                $Global:PartitionBarPixelperKB = ($PartitionBarWidth)/$Disk.SizeofDisk
                $Global:PartitionBarKBperPixel = $Disk.SizeofDisk/($PartitionBarWidth)
                break
            }

        }
    
        $Global:SizeofDisk = $Disk.SizeofDisk
        $Global:SizeofImage = $Global:SizeofDisk
        $Global:SizeofImage_Pixels = ($Global:PartitionBarPixelperKB * $Global:SizeofImage) -$Global:SizeofFAT32_Pixels

        $Global:SizeofFat32_Pixels_Minimum = $Global:PartitionBarPixelperKB * $Fat32Minimum 
        $Global:SizeofPartition_System_Pixels_Minimum = $Global:PartitionBarPixelperKB * $WorkbenchMinimum
        $Global:SizeofPartition_Other_Pixels_Minimum = $Global:PartitionBarPixelperKB * $WorkMinimum
        $Global:SizeofImage_Pixels_Minimum = $Global:SizeofFat32_Pixels_Minimum + $Global:SizeofPartition_System_Pixels_Minimum + $Global:SizeofPartition_Other_Pixels_Minimum

        $Global:SizeofImage_Minimum = $WorkbenchMinimum + $WorkMinimum + $Fat32Minimum 

        $Global:SizeofFreeSpace_Pixels_Minimum = 0
        $Global:SizeofFreeSpace_Minimum = 0

        $Global:SizeofUnallocated_Pixels_Minimum = 0
        $Global:SizeofUnallocated_Minimum = 0

        if ($Global:SizeofImage /$DefaultDivisorFat32 -ge $Fat32DefaultMaximum){
            $Global:SizeofFAT32 = $Fat32DefaultMaximum
            $Global:SizeofFAT32_Pixels = $Global:PartitionBarPixelperKB * $Global:SizeofFAT32   
        }
        else{
            $Global:SizeofFAT32 = $Global:SizeofImage/$DefaultDivisorFat32
            $Global:SizeofFAT32_Pixels = $Global:PartitionBarPixelperKB * $Global:SizeofFAT32   
        }

        if ($Global:SizeofImage/$DefaultDivisorWorkbench -ge $WorkbenchMaximum){
            $Global:SizeofPartition_System = $WorkbenchMaximum
            $Global:SizeofPartition_System_Pixels = $Global:SizeofPartition_System * $Global:PartitionBarPixelperKB 
        }
        else{
            $Global:SizeofPartition_System = $Global:SizeofImage/$DefaultDivisorWorkbench
            $Global:SizeofPartition_System_Pixels = $Global:SizeofPartition_System * $Global:PartitionBarPixelperKB 
        }

        $Global:SizeofPartition_Other = ($Global:SizeofImage-$Global:SizeofPartition_System-$Global:SizeofFAT32)
        $Global:SizeofPartition_Other_Pixels = $Global:SizeofPartition_Other * $Global:PartitionBarPixelperKB

        $Global:SizeofUnallocated = $Global:SizeofDisk-$Global:SizeofImage
        $Global:SizeofUnallocated_Pixels = $Global:SizeofUnallocated * $Global:PartitionBarPixelperKB

        $Global:SizeofFreeSpace = $Global:SizeofImage-$Global:SizeofPartition_System-$Global:SizeofFAT32-$Global:SizeofPartition_Other
        $Global:SizeofFreeSpace_Pixels = $Global:SizeofFreeSpace * $Global:PartitionBarPixelperKB
        
        Set-PartitionMaximums
        
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Global:SizeofFAT32_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Global:SizeofPartition_System_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Global:SizeofPartition_Other_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Global:SizeofFreeSpace_Pixels
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Global:SizeofUnallocated_Pixels
        
        $WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_System -Scale 'GiB'
        $WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_Other -Scale 'GiB'
        $WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofImage -Scale 'GiB'
        $WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFAT32 -Scale 'GiB'
        $WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFreeSpace -Scale 'GiB'
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofUnallocated -Scale 'GiB'
        }
})
   
$WPF_UI_Fat32Size_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'FAT32'   
    if ($Global:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value -ge $Global:SizeofFat32_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Global:SizeofFat32_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value -le $Global:SizeofFat32_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width = $Global:SizeofFat32_Pixels_Minimum
        }
        $Global:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Global:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Global:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Global:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Global:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Global:SizeofFAT32 = $Global:SizeofFAT32_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofPartition_System  = $Global:SizeofPartition_System_Pixels * $Global:PartitionBarKBperPixel  
        $Global:SizeofPartition_Other  = $Global:SizeofPartition_Other_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofFreeSpace  = $Global:SizeofFreeSpace_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofUnallocated = $Global:SizeofUnallocated_Pixels * $Global:PartitionBarKBperPixel
        
        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = Expand-FreeSpace 
        Write-host ('FAT32 Size (Pixels) changed to: '+$Global:SizeofFAT32_Pixels)
        $Global:SizeofFAT32 = $Global:SizeofFAT32_Pixels * $Global:PartitionBarKBperPixel
        Write-host ('FAT32 Size (KiB) changed to: '+$Global:SizeofFAT32)
        $WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_System -Scale 'GiB'
        $WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_Other -Scale 'GiB'
        $WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofImage -Scale 'GiB'
        $WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFAT32 -Scale 'GiB'
        $WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFreeSpace -Scale 'GiB'
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofUnallocated -Scale 'GiB'
    }
})   

$WPF_UI_WorkbenchSize_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Workbench'
    if ($Global:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value -ge $Global:SizeofPartition_System_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Global:SizeofPartition_System_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value -le $Global:SizeofPartition_System_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width = $Global:SizeofPartition_System_Pixels_Minimum
        }
        $Global:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Global:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Global:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Global:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Global:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Global:SizeofFAT32 = $Global:SizeofFAT32_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofPartition_System  = $Global:SizeofPartition_System_Pixels * $Global:PartitionBarKBperPixel  
        $Global:SizeofPartition_Other  = $Global:SizeofPartition_Other_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofFreeSpace  = $Global:SizeofFreeSpace_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofUnallocated = $Global:SizeofUnallocated_Pixels * $Global:PartitionBarKBperPixel

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = Expand-FreeSpace
        Write-host ('Workbench Size (Pixels) changed to: '+$Global:SizeofPartition_System_Pixels)
        $Global:SizeofPartition_System  = $Global:SizeofPartition_System_Pixels * $Global:PartitionBarKBperPixel
        Write-host ('Workbench Size (KiB) changed to: '+$Global:SizeofPartition_System)
        $WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_System -Scale 'GiB'
        $WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_Other -Scale 'GiB'
        $WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofImage -Scale 'GiB'
        $WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFAT32 -Scale 'GiB'
        $WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFreeSpace -Scale 'GiB'
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofUnallocated -Scale 'GiB'
    }   
})


$WPF_UI_WorkSize_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Work'
    if ($Global:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value -ge $Global:SizeofPartition_Other_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Global:SizeofPartition_Other_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value -le $Global:SizeofPartition_Other_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width = $Global:SizeofPartition_Other_Pixels_Minimum
        }
        $Global:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Global:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Global:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Global:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Global:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Global:SizeofFAT32 = $Global:SizeofFAT32_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofPartition_System  = $Global:SizeofPartition_System_Pixels * $Global:PartitionBarKBperPixel  
        $Global:SizeofPartition_Other  = $Global:SizeofPartition_Other_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofFreeSpace  = $Global:SizeofFreeSpace_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofUnallocated = $Global:SizeofUnallocated_Pixels * $Global:PartitionBarKBperPixel

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = Expand-FreeSpace
        Write-host ('Work Size (Pixels) changed to: '+$Global:SizeofPartition_Other_Pixels)
        $Global:SizeofPartition_Other  = $Global:SizeofPartition_Other_Pixels * $Global:PartitionBarKBperPixel
        Write-host ('Work Size (KiB) changed to: '+$Global:SizeofPartition_Other)
        $WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_System -Scale 'GiB'
        $WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_Other -Scale 'GiB'
        $WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofImage -Scale 'GiB'
        $WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFAT32 -Scale 'GiB'
        $WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFreeSpace -Scale 'GiB'
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofUnallocated -Scale 'GiB'
    }   
})

$WPF_UI_FreeSpace_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Free'
    if ($Global:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value -ge $Global:SizeofFreeSpace_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Global:SizeofFreeSpace_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value -le $Global:SizeofFreeSpace_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width = $Global:SizeofFreeSpace_Pixels_Minimum
        }
        $Global:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Global:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Global:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Global:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Global:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Global:SizeofFAT32 = $Global:SizeofFAT32_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofPartition_System  = $Global:SizeofPartition_System_Pixels * $Global:PartitionBarKBperPixel  
        $Global:SizeofPartition_Other  = $Global:SizeofPartition_Other_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofFreeSpace  = $Global:SizeofFreeSpace_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofUnallocated = $Global:SizeofUnallocated_Pixels * $Global:PartitionBarKBperPixel

        $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = Expand-UnallocatedSpace
        Write-host ('Free Space (Pixels) changed to: '+$Global:SizeofFreeSpace_Pixels)
        $Global:SizeofFreeSpace  = $Global:SizeofFreeSpace_Pixels * $Global:PartitionBarKBperPixel
        Write-host ('Free Space Size (KiB) changed to: '+$Global:SizeofFreeSpace)

        $WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_System -Scale 'GiB'
        $WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_Other -Scale 'GiB'
        $WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofImage -Scale 'GiB'
        $WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFAT32 -Scale 'GiB'
        $WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFreeSpace -Scale 'GiB'
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofUnallocated -Scale 'GiB'

    }    
})

$WPF_UI_Unallocated_Listview.add_SizeChanged({
    Set-PartitionMaximums -Type 'Unallocated'
    if ($Global:HSTDiskName){
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value -ge $Global:SizeofUnallocated_Pixels_Maximum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Global:SizeofUnallocated_Pixels_Maximum
        }
        if ($WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value -le $Global:SizeofUnallocated_Pixels_Minimum){
            $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width = $Global:SizeofUnallocated_Pixels_Minimum
        }

        $Global:SizeofFAT32_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[0].Width.Value
        $Global:SizeofPartition_System_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[2].Width.Value
        $Global:SizeofPartition_Other_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[4].Width.Value
        $Global:SizeofFreeSpace_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[6].Width.Value
        $Global:SizeofUnallocated_Pixels = $WPF_UI_DiskPartition_Grid.ColumnDefinitions[8].Width.Value

        $Global:SizeofFAT32 = $Global:SizeofFAT32_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofPartition_System  = $Global:SizeofPartition_System_Pixels * $Global:PartitionBarKBperPixel  
        $Global:SizeofPartition_Other  = $Global:SizeofPartition_Other_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofFreeSpace  = $Global:SizeofFreeSpace_Pixels * $Global:PartitionBarKBperPixel
        $Global:SizeofUnallocated = $Global:SizeofUnallocated_Pixels * $Global:PartitionBarKBperPixel

        Write-host ('Unallocated Space (Pixels) changed to: '+$Global:SizeofUnallocated_Pixels)
        $Global:SizeofUnallocated = $Global:SizeofUnallocated_Pixels * $Global:PartitionBarKBperPixel
        Write-host ('Unallocated (KiB) changed to: '+$Global:SizeofUnallocated)
        $WPF_UI_WorkbenchSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_System -Scale 'GiB'
        $WPF_UI_WorkSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofPartition_Other -Scale 'GiB'
        $WPF_UI_ImageSize_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofImage -Scale 'GiB'
        $WPF_UI_FAT32Size_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFAT32 -Scale 'GiB'
        $WPF_UI_FreeSpace_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofFreeSpace -Scale 'GiB'
        $WPF_UI_Unallocated_Value.Text = Get-RoundedDiskSize -Size $Global:SizeofUnallocated -Scale 'GiB'
    }
})

$WPF_UI_MediaSelect_Refresh.Add_Click({
    $Global:HSTDiskName =$null
    
    $WPF_UI_FAT32_Splitter.IsEnabled = ""
    $WPF_UI_Workbench_Splitter.IsEnabled = ""
    $WPF_UI_Work_Splitter.IsEnabled = ""
    $WPF_UI_Image_Splitter.IsEnabled = ""
    $WPF_UI_WorkbenchSize_Value.IsEnabled = ""
    $WPF_UI_WorkSize_Value.IsEnabled = ""
    $WPF_UI_ImageSize_Value.IsEnabled = ""
    $WPF_UI_FAT32Size_Value.IsEnabled = ""
    $RemovableMedia = Get-RemovableMedia
    $WPF_UI_MediaSelect_Dropdown.Items.Clear()
    foreach ($Disk in $RemovableMedia){
        $WPF_UI_MediaSelect_Dropdown.AddChild($Disk.FriendlyName)
    }
})

$WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Add_TextChanged({
    $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Global:AvailableSpaceFilestoTransfer
})


$WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Add_TextChanged({
    if ($WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.text -eq ''){
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Transparent"
    }
    elseif (($Global:AvailableSpaceFilestoTransfer - $Global:SizeofFilestoTransfer ) -lt $Global:SpaceThreshold_FilestoTransfer){
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Red"
    }
    elseif (($Global:AvailableSpaceFilestoTransfer - $Global:SizeofFilestoTransfer ) -lt ($Global:SpaceThreshold_FilestoTransfer*2)){
    $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Yellow"
    }
    else{
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Background = "Green"
    }
    
})


$WPF_UI_AvailableSpaceValue_TextBox.Add_TextChanged({
    if ($Global:AvailableSpace_WorkingFolderDisk -le ($Global:SpaceThreshold_WorkingFolderDisk*2)){
        $WPF_UI_AvailableSpaceValue_TextBox.Background = "Yellow"
    }
    elseif ($Global:AvailableSpace_WorkingFolderDisk -le $Global:SpaceThreshold_WorkingFolderDisk){
        $WPF_UI_AvailableSpaceValue_TextBox.Background = "Red"
    }
    else{
        $WPF_UI_AvailableSpaceValue_TextBox.Background = "Green"
    }
    
})

$WPF_UI_WorkSize_Value.add_LostFocus({
    if ($WPF_UI_WorkSize_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_WorkSize_Slider.Value = $WPF_UI_WorkSize_Value.Text
        $WPF_UI_WorkSize_Value.Background = 'White'
    }
    else
    {
        $WPF_UI_WorkSize_Value.Background = 'Red'
    }
})

$WPF_UI_WorkbenchSize_Value.add_LostFocus({   
    if ($WPF_UI_WorkBenchSize_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_WorkBenchSize_Value.Background = 'White'
        $WPF_UI_WorkBenchSize_Slider.Value = $WPF_UI_WorkBenchSize_Value.Text
    }
    else{
        $WPF_UI_WorkBenchSize_Value.Background = 'Red'
    }
})

$WPF_UI_FAT32Size_Value.add_LostFocus({
    if ($WPF_UI_FAT32Size_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_FAT32Size_Slider.Value = $WPF_UI_FAT32Size_Value.Text
        $WPF_UI_FAT32Size_Value.Background = 'White'
    }
    else{
        $WPF_UI_FAT32Size_Value.Background = 'Red'
    }
})

$WPF_UI_ImageSize_Value.add_LostFocus({
    if ($WPF_UI_ImageSize_Value.Text -match "^[\d\.]+$"){
        $WPF_UI_ImageSize_Value.Background = 'White'
        $WPF_UI_ImageSize_Slider.Value = $WPF_UI_ImageSize_Value.Text
    }
    else{
        $WPF_UI_ImageSize_Value.Background = 'Red'
    }
})

$WPF_UI_Start_Button.Background = 'Red'

$WPF_UI_Start_Button.Add_Click({
    $Global:SSID = $WPF_UI_SSID_Textbox.Text
    $Global:WifiPassword = $WPF_UI_Password_Textbox.Text
    if ($WPF_UI_DiskWrite_CheckBox.IsChecked){
        $Global:WriteImage ='FALSE'
    }
    else{
        $Global:WriteImage ='TRUE'
    }
    
    if ($Global:AvailableSpaceFilestoTransfer -lt $Global:SpaceThreshold_FilestoTransfer){
        $Msg = @'
You do not have sufficient space on your Work partition to transfer the files!
        
Select a location with less space, increase the space on Work, or remove the transfer of files
'@
    [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',0,48)

    }

    if ($Global:AvailableSpace_WorkingFolderDisk -le $Global:SpaceThreshold_WorkingFolderDisk){
        $Msg = @'
You do not have sufficient space on your drive to run the tool!

Either select a location with sufficient space or press cancel to quit the tool
'@
        $ValueofAction = [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',1,48)
        if ($ValueofAction -eq 'OK'){
            $SufficientSpace_Flag =$null
            do {
                $Global:WorkingPath = Get-FolderPath -Message 'Select location for Working Path' -RootFolder 'MyComputer'-ShowNewFolderButton
                $Global:Space_WorkingFolderDisk = (Confirm-DiskSpace -PathtoCheck $Global:WorkingPath)/1kb
                $Global:AvailableSpace_WorkingFolderDisk = $Global:Space_WorkingFolderDisk - $Global:RequiredSpace_WorkingFolderDisk 
                if ($Global:AvailableSpace_WorkingFolderDisk -le $Global:SpaceThreshold_WorkingFolderDisk){
                    $Msg = @'
You still do not have sufficient space on your drive to run the tool!
                  
Either select a location with sufficient space or press cancel to quit the tool
'@    
                    $ValueofAction = [System.Windows.MessageBox]::Show($Msg, 'Error - Insufficient Space!',1,48)
                    if ($ValueofAction -eq 'Cancel'){
                        $Form_UserInterface.Close() | out-null
                        $Global:ExitType =2 
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
            $Global:ExitType =2
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
        $Global:ExitType = 1
    }
})

$WPF_UI_RomPath_Button.Add_Click({
    $Global:ROMPath = Get-FolderPath -Message 'Select path to Roms' -RootFolder 'MyComputer'
    if ($Global:ROMPath){
        if(Confirm-UIFields){
            $WPF_UI_Start_Button.Background = 'Red'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
        }
        $WPF_UI_RomPath_Label.Content = Get-FormattedPathforGUI -PathtoTruncate ($Global:ROMPath)
        $WPF_UI_RomPath_Button.Background = 'Green'
    }
    else{
        $WPF_UI_RomPath_Label.Content='No ROM path selected'
        $WPF_UI_RomPath_Button.Background = '#FFDDDDDD'
    }
})

$WPF_UI_ADFPath_Button.Add_Click({
    $Global:ADFPath = Get-FolderPath -Message 'Select path to ADFs' -RootFolder 'MyComputer'
    if ($Global:ADFPath){
        if(Confirm-UIFields){
            $WPF_UI_Start_Button.Background = 'Red'
        }
        else{
            $WPF_UI_Start_Button.Background = 'Green'
        }
        $WPF_UI_ADFPath_Label.Content = Get-FormattedPathforGUI -PathtoTruncate ($Global:ADFPath)
        $WPF_UI_ADFPath_Button.Background = 'Green'
    } 
    else{
        $WPF_UI_ADFPath_Label.Content='No ADF path selected'
        $WPF_UI_ADFPath_Button.Background = '#FFDDDDDD'
    }
})

$WPF_UI_MigratedFiles_Button.Add_Click({
    If (-not ($Global:TransferLocation)) {
        $Global:TransferLocation = Get-FolderPath -Message 'Select transfer folder' -RootFolder 'MyComputer'
        if ($Global:TransferLocation){            
           
            $Global:SizeofFilestoTransfer = Get-TransferredFilesSpaceRequired -FoldertoCheck $Global:TransferLocation
            $Global:AvailableSpaceFilestoTransfer =  $Global:Space_FilestoTransfer - $Global:SizeofFilestoTransfer      
            
            $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Global:SizeofFilestoTransfer
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = Get-FormattedSize -Size $Global:AvailableSpaceFilestoTransfer 

            $WPF_UI_MigratedPath_Label.Content = Get-FormattedPathforGUI -PathtoTruncate ($Global:TransferLocation)
            $WPF_UI_MigratedFiles_Button.Content = 'Click to remove Transfer Folder'
            $WPF_UI_MigratedFiles_Button.Background = 'Green'
        }
        else{
            $Global:SizeofFilestoTransfer = 0
            $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = ''
            $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = ''
            $WPF_UI_MigratedFiles_Button.Background = '#FFDDDDDD'
        }
    }
    else{
        $Global:SizeofFilestoTransfer= 0
        $WPF_UI_RequiredSpaceValueTransferredFiles_TextBox.Text = ''
        $WPF_UI_AvailableSpaceValueTransferredFiles_TextBox.Text = ''
        $Global:TransferLocation = $null
        $WPF_UI_MigratedFiles_Button.Content = 'Click to set Transfer Folder'
        $WPF_UI_MigratedFiles_Button.Background = '#FFDDDDDD'
        $WPF_UI_MigratedPath_Label.Content='No transfer path selected'
    }
})

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

$WPF_UI_NoFileInstall_CheckBox.Add_Checked({
    $Global:SetDiskupOnly = 'TRUE'
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
    }
    If ($Global:HSTDiskName){
        $Global:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $WPF_UI_ImageSize_Slider.Value
        $Global:AvailableSpace_WorkingFolderDisk = $Global:Space_WorkingFolderDisk - $Global:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Global:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Global:AvailableSpace_WorkingFolderDisk
    } 
})

$WPF_UI_NoFileInstall_CheckBox.Add_UnChecked({
    $Global:SetDiskupOnly = 'FALSE'
    if(Confirm-UIFields){
        $WPF_UI_Start_Button.Background = 'Red'
    }
    else{
        $WPF_UI_Start_Button.Background = 'Green'
    }
    If ($Global:HSTDiskName){
        $Global:RequiredSpace_WorkingFolderDisk = Get-RequiredSpace -ImageSize $WPF_UI_ImageSize_Slider.Value
        $Global:AvailableSpace_WorkingFolderDisk = $Global:Space_WorkingFolderDisk - $Global:RequiredSpace_WorkingFolderDisk 
    
        $WPF_UI_RequiredSpaceValue_TextBox.Text = Get-FormattedSize -Size $Global:RequiredSpace_WorkingFolderDisk
        $WPF_UI_AvailableSpaceValue_TextBox.Text = Get-FormattedSize -Size $Global:AvailableSpace_WorkingFolderDisk
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
    $Global:IsDisclaimerAccepted = $True
})


$Form_Disclaimer.ShowDialog() | out-null

if (-not ($Global:IsDisclaimerAccepted -eq $true)){
    Write-ErrorMessage 'Exiting - Disclaimer Not Accepted'
    exit    
}

####################################################################### End GUI XML for Disclaimer ##################################################################################################

####################################################################### Show Main Gui     ##################################################################################################################

$Form_UserInterface.ShowDialog() | out-null

######################################################################## Command line portion of Script ################################################################################################

if ($Global:ExitType -eq 2){
    Write-ErrorMessage -Message 'Exiting - User has insufficient space'
    exit
}
elseif (-not ($Global:ExitType-eq 1)){
    Write-ErrorMessage -Message 'Exiting - UI Window was closed'
    exit
}

#[System.Windows.Window].GetEvents() | select Name, *Method, EventHandlerType

#[System.Windows.Controls.GridSplitter].GetEvents() | Select-Object Name, *Method, EventHandlerType
#[System.Windows.Controls.ListView].GetEvents() | Select-Object Name, *Method, EventHandlerType

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

$Global:TotalSections = 20

$Global:CurrentSection = 1

if (-not ($Global:TransferLocation)){
    $TotalSections --
}
if (-not ($Global:WriteImage)){
    $TotalSections --
}

if ($Global:SetDiskupOnly = 'TRUE'){
    $TotalSections = 6 ## Need to update
}

# Check Integrity of CSVs

$StartDateandTime = (Get-Date -Format HH:mm:ss)

$Global:SizeofImage_HST = $Global:SizeofImage-($Global:SizeofFAT32*1024)

Write-InformationMessage -Message "Running Script to perform selected functions. Options selected are:"
Write-InformationMessage -Message "DiskName to Write: $Global:HSTDiskName"  
Write-InformationMessage -Message "ScreenMode to Use: $Global:ScreenModetoUse"
Write-InformationMessage -Message "Kickstart to Use: $Global:KickstartVersiontoUse" 
Write-InformationMessage -Message "SSID to configure: $Global:SSID" 
Write-InformationMessage -Message "Password to set: $Global:WifiPassword" 
Write-InformationMessage -Message "Fat32 Size (MiB): $Global:SizeofFAT32"
Write-InformationMessage -Message "Image Size (KiB): $Global:SizeofImage"
Write-InformationMessage -Message "Image Size HST (KiB): $Global:SizeofImage_HST"
Write-InformationMessage -Message "Workbench Size: $Global:SizeofPartition_System"
Write-InformationMessage -Message "Work Size: $Global:SizeofPartition_Other"
Write-InformationMessage -Message "Working Path: $Global:WorkingPath"
Write-InformationMessage -Message "Rom Path: $Global:ROMPath"
Write-InformationMessage -Message "ADF Path: $Global:ADFPath" 
Write-InformationMessage -Message "Transfer Location: $Global:TransferLocation"
Write-InformationMessage -Message "Write Image to Disk: $Global:WriteImage"
Write-InformationMessage -Message "Set disk up only: $Global:SetDiskupOnly"

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
    Write-TaskCompleteMessage -Message 'Checking existance of folders, programs, and files - Complete!'
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
#$InstallPathMUI='SYS:Programs/MUI'
#$InstallPathPicasso96='SYS:Programs/Picasso96'
#$InstallPathAmiSSL='SYS:Programs/AmiSSL'
$GlowIcons='TRUE'

$NameofImage=('Pistorm'+$Global:KickstartVersiontoUse+'.HDF')

### Clean up

Write-StartTaskMessage -Message 'Performing Cleanup'

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

Write-TaskCompleteMessage -Message 'Performing Cleanup - Complete!'

### End Clean up

### Determine Kickstart Rom Path

#Update-OutputWindow -OutputConsole_Title_Text 'Determining Kickstarts to Use' -ProgressbarValue_Overall 7 -ProgressbarValue_Overall_Text '7%'

Write-StartTaskMessage -Message 'Determining Kickstarts to Use'

$FoundKickstarttoUse = Compare-KickstartHashes -PathtoKickstartHashes ($InputFolder+'RomHashes.csv') -PathtoKickstartFiles $Global:ROMPath -KickstartVersion $Global:KickstartVersiontoUse

$KickstartPath = $FoundKickstarttoUse.KickstartPath

if (-not($KickstartPath)){
    Write-ErrorMessage -Message "Error! No Kickstart file found!"
    exit
} 

$KickstartNameFAT32=$FoundKickstarttoUse.Fat32Name

Write-InformationMessage -Message ('Kickstart to be used is: '+$KickstartPath)

Write-TaskCompleteMessage -Message 'Determining Kickstarts to Use - Complete!'

if ($Global:SetDiskupOnly -eq 'FALSE'){

    Write-StartTaskMessage -Message 'Determining ADFs to Use'
    
    $AvailableADFs = Compare-ADFHashes -PathtoADFFiles $Global:ADFPath -PathtoADFHashes ($InputFolder+'ADFHashes.csv') -KickstartVersion $Global:KickstartVersiontoUse -PathtoListofInstallFiles ($InputFolder+'ListofInstallFiles.csv') 
    
    if (-not ($AvailableADFs)){
        Write-ErrorMessage -Message "One or more ADF files is missing!"
        exit
    } 
    
    $ListofInstallFiles = Import-Csv ($InputFolder+'ListofInstallFiles.csv') -Delimiter ';' |  Where-Object {$_.Kickstart_Version -eq $Global:KickstartVersiontoUse} | Sort-Object -Property 'InstallSequence'
    
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

if ($Global:SetDiskupOnly -eq 'FALSE'){
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

Write-TaskCompleteMessage -Message 'Downloading Emu68 Packages - Complete'

### End Download Emu68

### Begin Download UnLzx

if ($Global:SetDiskupOnly -eq 'FALSE'){
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
if (-not (Start-HSTImager -Command "rdb filesystem add" -DestinationPath ($LocationofImage+$NameofImage) -FileSystemPath ($Global:WorkingPath+'Programs\HST-Imager\pfs3aio') -DosType 'PFS3' -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
    exit
} 


## Setting up Amiga Partitions List

$AmigaPartitionsList = Get-AmigaPartitionList   -SizeofPartition_System_param $Global:SizeofPartition_System `
                                                -SizeofPartition_Other_param $Global:SizeofPartition_Other `
                                                -VolumeName_System_param $VolumeName_System `
                                                -DeviceName_System_param $DeviceName_System `
                                                -PFSLimit $Global:PFSLimit  `
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

if ($Global:SetDiskupOnly -eq 'FALSE'){
    #### Begin - Create NewFolder.info file
    if (($Global:KickstartVersiontoUse -eq 3.1) -or (($Global:KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'FALSE'))) {
        if (-not (Start-HSTImager -Command 'fs extract' -SourcePath ($StorageADF+'\Monitors.info') -DestinationPath ($TempFolder.TrimEnd('\'))  -TempFoldertouse $TempFolder -HSTImagePathtouse $HSTImagePath)){
            exit
        }
        if (Test-Path ($TempFolder+'def_drawer.info')){
            $null = Remove-Item ($TempFolder+'def_drawer.info')
        }
        $null = Rename-Item ($TempFolder+'Monitors.info') ($TempFolder+'def_drawer.info')
    }
    elseif(($Global:KickstartVersiontoUse -eq 3.2) -and ($GlowIcons -eq 'TRUE')){
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
    
    if ($Global:KickstartVersiontoUse -eq 3.1){
    
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
    
    if ($Global:KickstartVersiontoUse -eq 3.1){
        $SourcePath = ($InstallADF+'\Update\disk.info') 
    }
    
    elseif ($Global:KickstartVersiontoUse -eq 3.2){
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
        if (($AmigaPartition.PartitionNumber -le 3) -and ($Global:KickstartVersiontoUse -eq 3.2)) {
            Rename-Item ($AmigaDrivetoCopy+$VolumeName_Other+'\def_harddisk.info') ($AmigaDrivetoCopy+$VolumeName_Other+'\disk.info') 
        }
    }

}

Write-TaskCompleteMessage -Message 'Preparing Amiga Image - Complete!'

if ($Global:SetDiskupOnly -eq 'FALSE'){
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
    
    $ListofPackagestoInstall = Import-Csv ($InputFolder+'ListofPackagestoInstall.csv') -Delimiter ';' |  Where-Object {$_.KickstartVersion -match $Global:KickstartVersiontoUse} | Where-Object {$_.InstallFlag -eq 'TRUE'} #| Sort-Object -Property 'InstallSequence','PackageName'
    
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
                     "   ssid=""$Global:SSID""",
                     "   psk=""$Global:WifiPassword""",
                     "}"
                     
    Export-TextFileforAmiga -ExportFile ($AmigaDrivetoCopy+$VolumeName_System+'\Prefs\Env-Archive\Sys\wireless.prefs') -DatatoExport $WirelessPrefs -AddLineFeeds 'TRUE'                
    
    Write-TaskCompleteMessage -Message 'Creating Wireless Prefs File - Complete!'
    
    ### End Wireless Prefs
    
    ### Fix WBStartup
    
    Write-StartTaskMessage -Message 'Fix WBStartup'
    
    If ($Global:KickstartVersiontoUse -eq 3.2){
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

Copy-Item ($LocationofAmigaFiles+'FAT32\cmdline_'+$Global:KickstartVersiontoUse+'.txt') -Destination ($FAT32Partition+'cmdline.txt') #Temporary workaround until Michal fixes buptest for 3.1


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

Write-TaskCompleteMessage -Message 'Setting up FAT32 Files - Complete!'

### Transfer files to Work partition

if ($Global:TransferLocation) {
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

if ($Global:SetDiskupOnly -eq 'FALSE'){

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

$null= Rename-Item ($LocationofImager+'emu68_converted.img') -NewName ('Emu68Kickstart'+$Global:KickstartVersiontoUse+'.img')

Write-TaskCompleteMessage -Message 'Creating Image - Complete!'

Write-StartTaskMessage -Message 'Writing Image to Disk'

Set-location  $Global:WorkingPath

Write-Image -HSTImagePathtouse $HSTImagePath -SourcePath ($LocationofImage+'Emu68Kickstart'+$Global:KickstartVersiontoUse+'.img') -DestinationPath $Global:HSTDiskName

Write-TaskCompleteMessage -Message 'Writing Image to Disk - Complete!'

$EndDateandTime = (Get-Date -Format HH:mm:ss)
$ElapsedTime = (New-TimeSpan -Start $StartDateandTime -End $EndDateandTime).TotalSeconds

Write-Host "Started at: $StartDateandTime Finished at: $EndDateandTime. Total time to run (in seconds) was: $ElapsedTime" 
