Import-Module .\Get-PhoneData.psm1

$devicename="device_name"
$storagedir='c:\Where\to\store\files'
$getall='(.*)$'

$something_to_backup_1 = [PSCustomObject]@{
    source = "path\after\device_name"
    destination = "$storagedir\where\to\put\it\1"
    filter = $getall
};
$something_to_backup_2 = [PSCustomObject]@{
    source = "path\after\device_name"
    destination = "$storagedir\where\to\put\it\2"
    filter = $getall
};


$Thingstobackup = New-Object System.Collections.ArrayList

$Thingstobackup.Add($something_to_backup_1) | Out-Null
$Thingstobackup.Add($something_to_backup_2) | Out-Null


$Thingstobackup | ForEach-Object {
    Get-DeviceData -DeviceName $devicename -Source $_.source -Target $_.destination -Mode "Copy" -Filter $_.filter
}
