<#
NOTES
-----
Close Windows Media Player before running it


WORKING
-------
Write xls to c:\junk\ folder
Delete all Thumbs.db
Delete all Desktop.ini (although this is now commented out because Windows Media Players puts them back when do 'apply media changes' with rename/re-arrange turned on)
Delete all AlbumArt_*_Large.jpg
Delete all AlbumArt_*_Small.jpg
If AlbumArtSmall.jpg missing or smaller than Folder.jpg then overwrite it with a copy of Folder.jpg
Handles folders with square brackets. Sorted this out by using -LiteralPath everywhere. Example: \Whoever\Greatest Hits [UK Edition]\
Check album tag matches folder name. Report anomalies.
Check album artist tag matches folder name. Report anomalies.
Check file name matches tags for track  number and track name. Report anomalies.
Report any rogue files in artist folder which are not in an album folder. 
Report any artist folders with no subfolders
Report any album folders with no tracks.
Report in one column any error or all good

Tracks which are not part of a full album
-----------------------------------------
Treat them as part of the album they were released on. 
If album not detected and cannot be found then edit album tag with something like 'Bob Dylan Tracks'

Album Artist
------------
Can set this in Windows Media Player by editing the album properties. It will write this to Album Artist tag for each track.

NICE-TO-HAVE
------------
Report any rogue folders under an album folder
Report artist count, album count, track count
Report missing album art
Report missing year
Report missing genre

#>

$MyMusicFolder = "\\WYSE1\Family\Music"
$strOutFile = [string]::Format("C:\Junk\Music-{0}.xls", (Get-Date -Format "yyyy-MM-dd--HH-mm-ss").ToString())
$strErrFile = [string]::Format("C:\Junk\Music-{0}-Errors.txt", (Get-Date -Format "yyyy-MM-dd--HH-mm-ss").ToString())
Clear-Host
'Starting'
Get-Date

Function funDeleteFile($FileFullName) {
    #'Checking for file: ' + $FileFullName
    If (Test-Path -LiteralPath $FileFullName) {
        Remove-Item -LiteralPath $FileFullName
        '      Deleted file: ' + $FileFullName
    }

}

# Write header row to output file
("Artist Folder" + "`t" + "Album Folder" + "`t" + "File Name" + "`t" + "Album Artist Tag" + "`t" + "Album Tag" + "`t" + "Expected Album Folder" + "`t" + "Track Tag" + "`t" + "Title Tag" + "`t" + "Expected File Name from Tags" + "`t" + "Error" + "`t" + "Artist" + "`t" + "Album" + "`t" + "Name")  | Out-File $strOutFile -Append
"Starting error file" | Out-File $strErrFile -Append
            
# Cycle through the artist folders
foreach ($MyArtistFolder in (Get-ChildItem -LiteralPath $MyMusicFolder -Directory | Where-Object { $_.Name -NotLike "Playlists" }  | Sort-Object name)) {

	"Artist: " + $MyArtistFolder.Name
    funDeleteFile($MyArtistFolder.FullName + "\Thumbs.db")
    # funDeleteFile($MyArtistFolder.FullName + "\Desktop.ini")   # In Windows Media Player, when click 'Organise' -> 'Apply Media Information Changes' it puts back all the desktop.ini files. So I decided to leave them for now

    # Check for rogue files for this artist folder which are not in an album folder
    foreach ($MyRogueFile in (Get-ChildItem -LiteralPath $MyArtistFolder.FullName -File | Where-Object { $_.Name -NotLike "desktop.ini" } | Sort-Object Name)) {
        $MyRogueFile.FullName + " is a rogue file in an artist folder but not in an album folder " | Out-File $strErrFile -Append 
    }


    # Cycle through the Album folders for this artist
    $AlbumCountForThisArtist = 0
    foreach ($MyAlbumFolder in (Get-ChildItem -LiteralPath $MyArtistFolder.FullName -Directory | Sort-Object name)) {
        "   Album: " + $MyAlbumFolder.Name
        
        $AlbumCountForThisArtist++
        
        # Delete Thumbs.db
        funDeleteFile($MyAlbumFolder.FullName + "\Thumbs.db")
        
        # Delete Desktop.ini
        # funDeleteFile($MyAlbumFolder.FullName + "\Desktop.ini")


        # Delete all AlbumArt_*_Large.jpg
        foreach ($MyLargeImage in (Get-ChildItem -LiteralPath $MyAlbumFolder.FullName -File -filter 'AlbumArt_*_Large.jpg')) {
            "      Found file: " + $MyLargeImage.FullName
            funDeleteFile($MyLargeImage.FullName)
        
        }

        # Delete all AlbumArt_*_Small.jpg
        foreach ($MySmallImage in (Get-ChildItem -LiteralPath $MyAlbumFolder.FullName -File -filter 'AlbumArt_*_Small.jpg')) {
            "      Found file: " + $MySmallImage.FullName
            funDeleteFile($MySmallImage.FullName)
        
        }

        # If AlbumArtSmall.jpg missing or smaller than Folder.jpg then overwrite it with a copy of Folder.jpg
        $FolderJpg = $MyAlbumFolder.FullName + '\Folder.jpg'
        $AlbumArtSmallJpg = $MyAlbumFolder.FullName + '\AlbumArtSmall.jpg'
        if (Test-Path -LiteralPath $FolderJpg) {
            if (Test-Path -LiteralPath $AlbumArtSmallJpg) {
                If ((Get-Item -LiteralPath $FolderJpg -Force).length -gt (Get-Item -LiteralPath $AlbumArtSmallJpg -Force).length) {
                    Copy-Item -LiteralPath $FolderJpg $AlbumArtSmallJpg
                }
            }
            else {
                Copy-Item -LiteralPath $FolderJpg $AlbumArtSmallJpg
            }
        
        }

        # Report music files
            $objShell = New-Object -ComObject Shell.Application 
            $objFolder = $objShell.namespace($MyAlbumFolder.FullName)
            

           $TrackCountForThisAlbum = 0 

           foreach ($strFileName in $objFolder.Items() | Where-Object { $_.Name -NotLike "*.jpg" -and $_.Name -NotLike "*.ini" } | Sort-Object -Property Name) { 

            $TrackCountForThisAlbum++

            <#
            # This code is just for finding the extended attribute reference number for a particular tag
            $a = 0
            for ($a; $a -le 266; $a++)
            {
                $strFileName.Name + "`t" + $a.ToString() + "`t" + $objFolder.getDetailsOf($objFolder.items, $a) + "`t" + "`t" + "`t" + "`t" + $objFolder.getDetailsOf($strFileName, $a).ToString().Trim()
                
            }
            exit
            #>
            

            # Read the tags    
            $albumTag = $objFolder.getDetailsOf($strFileName, 14)
            $titleTag = $objFolder.getDetailsOf($strFileName, 21)
            $trackTag = $objFolder.getDetailsOf($strFileName, 26)
            $albumArtistTag = $objFolder.getDetailsOf($strFileName, 237) #Seemed to change to 237 with later Windows10, was 230 with earlier Windows10, and used to be 217
   
            

            # Work out the expected artist folder name from the tags
            $strExpectedArtistFolderFromTags = $albumArtistTag -replace (":", "-") -replace ("\?", "-") -replace ("/", "-") -replace (">", "-") -replace ("\*", "-") -replace ('"', "'")
            if ($strExpectedArtistFolderFromTags.EndsWith(".")) { $strExpectedArtistFolderFromTags = $strExpectedArtistFolderFromTags.Substring(0, $strExpectedArtistFolderFromTags.Length - 1) } # That just removes the last character if it is a dot

            # Work out the expected album folder name from the tags
            $strExpectedAlbumFolderFromTags = $albumTag -replace (":", "-") -replace ("\?", "-") -replace ("/", "-") -replace (">", "-") -replace ("\*", "-") -replace ('"', "'")
            if ($strExpectedAlbumFolderFromTags.EndsWith(".")) { $strExpectedAlbumFolderFromTags = $strExpectedAlbumFolderFromTags.Substring(0, $strExpectedAlbumFolderFromTags.Length - 1) } # That just removes the last character if it is a dot

            # Work out the expected file name from the tags
            [string]$strTrackTag = $trackTag.ToString()
            if (($strTrackTag.length -eq 1)) { $strTrackTag = "0" + $strTrackTag }
            [string]$strExtension = $strFileName.Name.Substring($strFileName.Name.LastIndexOf("."))
            [string]$strTitleForFileName = $titleTag
            if ($strTitleForFileName.EndsWith(".")) { $strTitleForFileName = $strTitleForFileName.Substring(0, $strTitleForFileName.Length - 1) } # That just removes the last character if it is a dot
            $strExpectedFileNameFromTags = ($strTrackTag + " " + $strTitleForFileName + $strExtension) -replace (":", "-") -replace ("\?", "-") -replace ("/", "-") -replace (">", "-") -replace ("\*", "-") -replace ('"', "'")

            # Check if folder and file names match tags or not
            $artistWrong = 1; if ($MyArtistFolder.Name -eq $strExpectedArtistFolderFromTags) { $artistWrong = 0 }
            $albumWrong = 1; if ($MyAlbumFolder.Name -eq $strExpectedAlbumFolderFromTags) { $albumWrong = 0 }
            $nameWrong = 1; if ($strFileName.Name -eq $strExpectedFileNameFromTags) { $nameWrong = 0 }

            $anythingWrong = 1; if (($artistWrong -eq 0) -and ($albumWrong -eq 0) -and ($nameWrong -eq 0)) { $anythingWrong = 0 }


            ($MyArtistFolder.Name + "`t" + $MyAlbumFolder.Name + "`t" + $strFileName.Name + "`t" + $albumArtistTag + "`t" + $albumTag + "`t" + $strExpectedAlbumFolderFromTags + "`t" + $trackTag + "`t" + $titleTag + "`t" + $strExpectedFileNameFromTags + "`t" + $anythingWrong + "`t" + $artistWrong + "`t" + $albumWrong + "`t" + $nameWrong)  | Out-File $strOutFile -Append

            }
            
            # Log an error if there were no tracks in that album folder
            if ($TrackCountForThisAlbum -eq 0) {
                $MyAlbumFolder.FullName + " is an album folder with no tracks" | Out-File $strErrFile -Append 
            }

            
    }
        

    # Log an error if there were no album folders for that artist folder
    if ($AlbumCountForThisArtist -eq 0) {
        $MyArtistFolder.FullName + " has no album folders" | Out-File $strErrFile -Append 
    }

        

         
}

    
"All done. Nothing more for error file" | Out-File $strErrFile -Append




