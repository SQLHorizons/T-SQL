```powershell

    #Requires -Modules SQLServer

    param(
      [Parameter(DontShow = $true)]
      [System.String[]]
      $DatabaseNames = @("ARC","ARC"),

      [Parameter(DontShow = $true)]
      [System.String]
      $BucketName = "aviva-client-ukl1-nonprod-uk-life-pension-annuity-wrapatretire",

      [Parameter(DontShow = $true)]
      [System.String]
      $KeyPrefix = "EC2-Backups/eng",

      [Parameter(DontShow = $true)]
      [PSCustomObject]
      $LastBackup = @{},

      [Parameter(DontShow = $true)]
      [System.Int32]
      $TotalHours = 72
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

    ##  set default AWS_MGMT_PROXY aws management proxy.
    if ($env:AWS_MGMT_PROXY) {
      Set-AWSProxy -Hostname ([System.Uri]$env:AWS_MGMT_PROXY).Host -Port ([System.Uri]$env:AWS_MGMT_PROXY).Port
    }

    ##  set default aws region.
    if ($env:AWS_DEFAULT_REGION) {
      Set-DefaultAWSRegion $env:AWS_DEFAULT_REGION
    }

    Try {
      foreach ( $DatabaseName in $DatabaseNames ) {
        ##  create a backup collection.
        $ReadFiles = @{
          Region     = $env:AWS_DEFAULT_REGION
          BucketName = $BucketName
          KeyPrefix  = "{0}/{1}/FULL/" -f $KeyPrefix, $DatabaseName
        }
        Write-Output "List backup files in: $($ReadFiles.BucketName)/$($ReadFiles.KeyPrefix)."
        $AllBackups = (Get-S3Object @ReadFiles).Where{[IO.Path]::GetExtension($_.Key)}

        ##  get file details for last backup.
        $LastBackup.indices  = [regex]::Matches( $($AllBackups.Key), "\d+_\d+" ).Value | Sort-Object | Select-Object -Last 1
        $LastBackup.DateTime = [DateTime]::ParseExact( $($LastBackup.indices), "yyyyMMdd_HHmmss", $null )
        $LastBackup.file     = $AllBackups.Where{ $([regex]::Matches( $($_.Key), "\d+_\d+" ).Value) -eq $($LastBackup.indices) }
        $LastBackup.fileName = Split-Path $LastBackup.file.Key -Leaf
        $LastBackup.epoch    = New-TimeSpan -Start $($LastBackup.DateTime) -End $(Get-Date)
        $LastBackup.getFile  = $($LastBackup.epoch).TotalHours -le $TotalHours

        if ( $LastBackup.getFile ) {
          $SQLServer = [Microsoft.SqlServer.Management.Smo.Server]::New("localhost")

          $DownloadFile = @{
            Region     = $($ReadFiles.Region)
            BucketName = $($LastBackup.file.BucketName)
            Key        = $($LastBackup.file.Key)
            File       = "$($SQLServer.BackupDirectory)\$($env:COMPUTERNAME)\$DatabaseName\FULL\$($LastBackup.fileName)"
          }
          Write-Output "Download file from: $($DownloadFile.BucketName)/$($DownloadFile.Key)."
          $null = Read-S3Object @DownloadFile

          $Database = $SQLServer.Databases[$DatabaseName]
          if ( -not[string]::IsNullOrEmpty( $Database ) ) {
            $SQLServer.KillAllProcesses( $DatabaseName )
            $Database.SetOffline()
          }

          ##  set up restore parameters.
          $RestoreParameters = @{
            InputObject     = $SQLServer
            Database        = $DatabaseName
            BackupFile      = $DownloadFile.File
            ReplaceDatabase = $true
            ErrorAction     = "Stop"
          }
          Write-Output "Restoring database: $($RestoreParameters.Database), from file: $($RestoreParameters.BackupFile)"
          $null = Restore-SqlDatabase  @RestoreParameters
        }
      }
    }
    Catch [System.Exception] {
      Write-Host "Error at line: $(($PSItem.InvocationInfo.line).Trim())"
      if ( $Error.Count > 0 ) {
        Write-Host $($Error[0].Exception.Message)
      }
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }

```