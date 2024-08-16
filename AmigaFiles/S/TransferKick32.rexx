/* TransferKick32.rexx
Program to calculate the hashes for Kickstart files on FAT32 drive and transfer matching files to 
DEVS:Kickstarts for use in WHDLoad.
*/

Say "Checking Kickstarts on FAT32 Kickstarts Folder to Transfer to WHDLoad"
Say ""
Say "Press Enter to continue"
Pull input
Say "Creating hashes of Roms in Kickstarts Folder"
Say ""


vCmd='C:md5sum EMU68BOOT:Kickstarts >T:RomHashes.txt'

/* 31 Version vCmd='List >>T:RunHashes EMU68boot:Kickstarts PAT=~(#?.info) LFORMAT="C:MD5sum -b %p%n >T:%n.MD5"' */
address command vCmd
/* 31 Version 
vCmd='join T:#?.md5 as T:RomHashes.txt'
address command vCmd
*/
Say "Hashes created!"

File_ListofKickstartHashes='S:KickStartRomHashes'
File_ListofKickstartstoCheck='T:RomHashes.Txt'

open(vKickstartstoCheck,File_ListofKickstartstoCheck,'read')
Do until eof(vKickstartstoCheck) | Check_Complete=1
    vKickstarttoCheck=readln(vKickstartstoCheck)
    if length(vKickstarttoCheck)=0 then do
        say "No files in directory!"
        exit 0
    end
    else do
        Check_Complete=1
    end
end
close(vKickstartstoCheck)

Say "Determining valid Kickstart files and copying to DEVS:Kickstarts folder"

open(vKickstartstoCheck,File_ListofKickstartstoCheck,'read')      
    Do until eof(vKickstartstoCheck)
        vKickstarttoCheck=readln(vKickstartstoCheck)
/*3.1 Version              parse var vKickstarttoCheck vKickstarttoCheckHash' *'vKickstarttoCheckPath */
		parse var vKickstarttoCheck vKickstarttoCheckHash'  'vKickstarttoCheckPath 
        parse var vKickstarttoCheckPath '/'vKickstarttoCheckName
        if vKickstarttoCheckPath~='' then do
            say "Checking "vKickstarttoCheckPath
            Match=0
            open(ListofKickstartHashes,File_ListofKickstartHashes,'read')  
                DO until Match=1 | eof(ListofKickstartHashes)
                    vKickstartHashLine = READLN(ListofKickstartHashes)
                    parse var vKickstartHashLine vKickstarttoCheckAgainstHash';'vKickstarttoCheckAgainstName
                    if vKickstarttoCheckHash=vKickstarttoCheckAgainstHash then do
                        Match=1
                        Say "Found match for "vKickstarttoCheckName"! ("vKickstarttoCheckAgainstName")"
                    end 
                end
            close(ListofKickstartHashes)          
            if Match=1 then do
				if exists ('"DEVS:Kickstarts/'vKickstarttoCheckAgainstName'"') then do
					Say "Not copying file as it already exists!"
				else do
					vCmd='copy from "'vKickstarttoCheckPath'" to "DEVS:Kickstarts/'vKickstarttoCheckAgainstName'" QUIET' 
					/* Say vCmd */
					address command vCmd
					vCmd="Delete from "vKickstarttoCheckPath   
					/* Say vCmd */
					address command vCmd
				end
             end
          If Match=0 then do
            say "No match found for file "vKickstarttoCheckName
          end
        end
    end   
Close(vKickstartstoCheck)
Say "Program complete! You can now close this window"
