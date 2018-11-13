# Export-StoredProcedure -SQLInstance localhhost -DBName dbmonitor,chennai,dba_local,direct2 -SP dbo.sp_vlfpro

function Export-StoredProcedure {
[CmdletBinding()]
Param
(
[parameter(mandatory=$true)]
[string]$SQLInstance,
[parameter(mandatory=$true)]
[object[]]$DBName,
[parameter(mandatory=$true)]
[string]$SP
)

#Define output folder & create Instance folder
$Wd = "$Home" ##add \ to the end
$Instance_file = $SQLInstance.Replace("\","_")
$InstanceFolder= $Instance_file.ToUpper()
new-item -type directory -name "$InstanceFolder" -path "$Wd" -Force | Out-Null


#Load SMO objects
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
$serverInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $SQLInstance

#Types
#$IncludeTypes = @("tables", "StoredProcedures", "Views", "UserDefinedFunctions") 
$IncludeTypes = @("StoredProcedures")
$ExcludeSchemas = @("sys", "Information_Schema")
$so = new-object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions')
$so.IncludeIfNotExists = 0
$so.SchemaQualify = 1
$so.AllowSystemObjects = 0
$so.ScriptDrops = 0 #Script Drop Objects

#Filter DB with input
$dbs = $serverInstance.Databases
$filtdb = $dbs | Where-Object Name -In $DBName

#Loop through each DB
    foreach ($db in $filtdb )
    {
        $fdbname = "$db".replace("[", "").replace("]", "")
        #$dbpath = "$Filename" + "\" + "$fdbname" + "\"
        foreach ($Type in $IncludeTypes) 
            {
                $TypeFolderPath  = $Wd + $InstanceFolder + '\'
                new-item -type directory -name "$Type" -path "$TypeFolderPath"  -Force | Out-Null

                $DBPath  = $TypeFolderPath + "$Type" + '\'
                new-item -type directory -name "$fdbname" -path "$DBPath" -Force | Out-Null

                 foreach ($objs in $db.$Type)
                    {
                        If ($ExcludeSchemas -notcontains $objs.Schema)
                         {
                            $ObjName = "$objs".replace("[", "").replace("]", "")
                            if($ObjName -eq $SP)
                                {
                                     $object_export_path = "$DBPath" + "$fdbname" + "\" 
                                     Write-Host "Scripting $ObjName in DB: $fdbname "                
                                     $OutFile = "$object_export_path" + "$ObjName" + ".sql"
                                     $objs.Script($so) + "GO" | out-File $OutFile #-Append
                                     Break
                                 }
                          }
                     }#Each Object
                }#Each Type   
                
          }#Each DB 
}#Func closure
