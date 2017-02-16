#   Function to return Restore Script for Backup Source

Function Get-SQLRestoreScript
{
    [CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess = $true)]
    param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$SQLServer,
        [parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if (Get-Module -name 'SQLPS')
    {
        $SMOServer = New-Object -TypeName  Microsoft.SqlServer.Management.Smo.Server($SQLServer);
        $BackupDev = New-Object -TypeName  Microsoft.SqlServer.Management.Smo.BackupDeviceItem ($DBBackup, 'File');
        $DBRestore = New-Object -TypeName  Microsoft.SqlServer.Management.Smo.Restore;

        $DBRestore.NoRecovery = $false;
        $DBRestore.ReplaceDatabase = $true;
        $DBRestore.Action = "Database";
        $DBRestore.PercentCompleteNotification = 10;
        $DBRestore.Devices.Add($BackupDev);

        $BackupDetails = $DBRestore.ReadBackupHeader($SMOServer);
        $DBRestore.Database = $BackupDetails.DatabaseName;

        foreach($file in $DBRestore.ReadFileList($SMOServer))
        {
            $rsfile = New-Object -TypeName  'Microsoft.SqlServer.Management.Smo.RelocateFile, Microsoft.SqlServer.SmoExtended, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91'
            $rsfile.LogicalFileName = $file.LogicalName
            switch ($file.FileId) 
            {   1       {$rsfile.PhysicalFileName = $SMOServer.Settings.DefaultFile + $($BackupDetails.DatabaseName) + '_FileId' + $file.FileId + '_Data.mdf'}
                2       {$rsfile.PhysicalFileName = $SMOServer.Settings.DefaultLog  + $($BackupDetails.DatabaseName) + '_FileId' + $file.FileId + '_Log.ldf'}
                default {$rsfile.PhysicalFileName = $SMOServer.Settings.DefaultFile + $($BackupDetails.DatabaseName) + '_FileId' + $file.FileId + '_Data.ndf'}
            }
            $DBRestore.RelocateFiles.Add($rsfile) | Out-Null
        }

        "`r"; Return $DBRestore.Script($SMOServer)
    }
    else
    {
        Throw "Import Module Name 'SQLPS'"
    }    
}

$Arguments = @{
    SQLServer = $env:COMPUTERNAME
    Path      = "\\$env:COMPUTERNAME\SQLBackup\Test.bak"
    }

Get-SQLRestoreScript @Arguments
