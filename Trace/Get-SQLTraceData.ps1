[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfoExtended") | Out-Null;
#Add-Type -AssemblyName "Microsoft.SqlServer.ConnectionInfoExtended"

$TraceDirectory = "C:\Users\TraceData";
$TraceFile = (Get-ChildItem $TraceDirectory -Filter "*.trc")[0]
$TraceFileObject = New-Object -TypeName Microsoft.SqlServer.Management.Trace.TraceFile
$TraceFileObject.InitializeAsReader($TraceFile.FullName)

$result = @()
while($TraceFileObject.Read())
{
    $columns = ($TraceFileObject.FieldCount) - 1
    
    $hashtablestr = "`$hashtable = @{  `n"
    for($i=0; $i -le $columns; $i++)
    {
        $columnName = $TraceFileObject.GetName($i)

        if($columnName -ne "BinaryData")
        {
            $columnValue = $TraceFileObject.GetValue($TraceFileObject.GetOrdinal($columnName))
            $hashtablestr += "`"$($columnName)`"=`"$($columnValue)`"
            `n"
        }
    }
    $hashtablestr += "}"

    Invoke-Expression $hashtablestr
    $item = New-Object PSObject -Property $hashtable
    $result += $item
}

$TraceFileObject.Close()
$result
