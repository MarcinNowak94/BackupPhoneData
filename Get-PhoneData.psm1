#source https://blog.daiyanyingyu.uk/2018/03/20/powershell-mtp/
#Credits to original creator
#Refactored by Nowak Marcin 2021-09-22

<#
.Synopsis
Access data on MTP device
.DESCRIPTION
With this fucntion You can access data on MTP device, such as Android phone
.EXAMPLE
Get-DeviceData -DeviceName "Android Phone" -Source "Phone\somedir" -Target "D:\Storage" -Mode "Copy" -Filter "(.jpg)|(.mp4)$"
.EXAMPLE
Another example of how to use this cmdlet
.INPUTS
-DeviceName string, name of the device as seen in Windows file explorer
-Source     string, path to directory you wish to backup
-Target     string, path to storage directory 
-Mode       string, "Copy" or "Move", copy leaves the data on source, move deletes from source
-Filter     string, optional, filter specific files
.OUTPUTS
None
.NOTES
General notes
.COMPONENT
The component this cmdlet belongs to
.ROLE
The role this cmdlet belongs to
.FUNCTIONALITY
Moving files from MTP devices
#>
function Get-DeviceData{
param(
    [Parameter(
        Mandatory=$True,
        Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$DeviceName,
    
    [Parameter(
        Mandatory=$True,
        Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]$Source,
    
    [Parameter(
        Mandatory=$True,
        Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$Target,
    
    [Parameter(
        Mandatory=$True,
        Position=3)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Copy","Move")]
    $Mode,   
    
    [Parameter(
        Mandatory=$False,
        Position=4)]
    [string]$Filter='(.*)$'
 
);
    
    $StoragePath = $Target

    $Device = Get-Device -DeviceName $DeviceName
    $Directory = Get-SubFolder -parent $Device -path $Source

    $items = @( $Directory.GetFolder.items() | where { $_.Name -match $Filter } )
    if ($items){
	    $totalItems = $items.count
	    if ($totalItems -gt 0){
		
            # If destination path doesn't exist, create it only if we have some items to move
		    if (-not (test-path $Target) ){
			    $created = new-item -itemtype directory -path $Target
		    }

		    Write-Verbose "Processing Path : $DeviceName\$Source"
		    Write-Verbose "Moving to : $Target"

		    $shell = Get-ShellProxy
		    $StorageDirectory = $shell.Namespace($Target).self
		    $count = 0;
		    foreach ($item in $items) {
			    $fileName = $item.Name

			    ++$count
			    $percent = [int](($count * 100) / $totalItems)
			    Write-Progress -Activity "Processing Files in $DeviceName\$Source" `
				    -status "Processing File ${count} / ${totalItems} (${percent}%)" `
				    -CurrentOperation $fileName `
				    -PercentComplete $percent

			    # Check the target file doesn't exist:
			    $targetFilePath = join-path -path $Target -childPath $fileName
			    if (test-path -path $targetFilePath) {
				    write-error "Destination file exists - file not moved:`n`t$targetFilePath"
			    }
			    else{
				    if($Mode -eq "Move"){$StorageDirectory.GetFolder.MoveHere($item)} 
                    else {               $StorageDirectory.GetFolder.CopyHere($item)}
                
				    if (test-path -path $targetFilePath){
					    # Optionally do something with the file, such as modify the name (e.g. removed phone-added prefix, etc.)
				    }
				    else {
					    write-error "Failed to move file to destination:`n`t$targetFilePath"
				    };
			    };
		    };
	    };
    };
};

function Get-ShellProxy{
	if( -not $global:ShellProxy){
		$global:ShellProxy = new-object -com Shell.Application
	}
	$global:ShellProxy
}

function Get-Device{
param(
    [Parameter(
        Mandatory=$True,
        Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$DeviceName
);
	$shell = Get-ShellProxy
	# 17 (0x11) = ssfDRIVES from the ShellSpecialFolderConstants (https://msdn.microsoft.com/en-us/library/windows/desktop/bb774096(v=vs.85).aspx)
	# => "My Computer" â€” the virtual folder that contains everything on the local computer: storage devices, printers, and Control Panel.
	# This folder can also contain mapped network drives.
	$shellItem = $shell.NameSpace(17).self                                   #TODO: See if i can use "ssfDRIVES"
	$Device = $shellItem.GetFolder.items() | where { $_.name -eq $DeviceName }
	return $Device
}

function Get-SubFolder{
	param($parent,[string]$path)
	$pathParts = @( $path.Split([system.io.path]::DirectorySeparatorChar) )
	$current = $parent
	foreach ($pathPart in $pathParts){
		if ($pathPart){
			$current = $current.GetFolder.items() | where { $_.Name -eq $pathPart }
		}
	}
	return $current
}