##Souce Links##
#SQL Server update center - https://technet.microsoft.com/en-us/library/ff803383.aspx

#2016
$2016SP164 = "https://download.microsoft.com/download/3/0/D/30D3ECDD-AC0B-45B5-B8B9-C90E228BD3E5/ENU/SQLServer2016SP1-KB3182545-x64-ENU.exe"
$2016CU5 = "https://download.microsoft.com/download/D/3/3/D33543E3-770F-4053-AE0F-A883696668FF/SQLServer2016-KB4040714-x64.exe"


#2014
$2014SP164 = "https://download.microsoft.com/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-KB3058865-x64-ENU.exe"
$2014SP132 = "https://download.microsoft.com/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-KB3058865-x86-ENU.exe"
$2014SP264 = "https://download.microsoft.com/download/6/D/9/6D90C751-6FA3-4A78-A78E-D11E1C254700/SQLServer2014SP2-KB3171021-x64-ENU.exe"
$2014SP232 = "https://download.microsoft.com/download/6/D/9/6D90C751-6FA3-4A78-A78E-D11E1C254700/SQLServer2014SP2-KB3171021-x86-ENU.exe"

#2012
$2012SP164 ="https://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-KB2674319-x64-ENU.exe"
$2012SP132 ="https://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-KB2674319-x86-ENU.exe"
$2012SP264 ="https://download.microsoft.com/download/D/F/7/DF7BEBF9-AA4D-4CFE-B5AE-5C9129D37EFD/SQLServer2012SP2-KB2958429-x64-ENU.exe"
$2012SP232 ="https://download.microsoft.com/download/D/F/7/DF7BEBF9-AA4D-4CFE-B5AE-5C9129D37EFD/SQLServer2012SP2-KB2958429-x86-ENU.exe"
$2012SP364 ="https://download.microsoft.com/download/B/1/7/B17F8608-FA44-462D-A43B-00F94591540A/ENU/x64/SQLServer2012SP3-KB3072779-x64-ENU.exe"
$2012SP332 ="https://download.microsoft.com/download/B/1/7/B17F8608-FA44-462D-A43B-00F94591540A/ENU/x86/SQLServer2012SP3-KB3072779-x86-ENU.exe"
$2012SP464 = "https://download.microsoft.com/download/E/A/B/EABF1E75-54F0-42BB-B0EE-58E837B7A17F/SQLServer2012SP4-KB4018073-x64-ENU.exe"
$2012SP432 = "https://download.microsoft.com/download/E/A/B/EABF1E75-54F0-42BB-B0EE-58E837B7A17F/SQLServer2012SP4-KB4018073-x86-ENU.exe"


ipmo bitstransfer
New-Item -Path "C:\Users\$env:username\Desktop\SQLServicePack" -ItemType container -Force | Out-Null

$spn = Read-Host "
==============================================================
** One Last Time Protocol
** Script to download SQL Server Service Pack from Powershell
==============================================================
Enter the number from below table to download respective SP
--add '.2' to download 32 bit version 

161 - SQL Server 2016 SP1
1615 - SQL Server 2016 SP1 Latest Cumulative Update(CU5)

141 - SQL Server 2014 SP1
142 - SQL Server 2014 SP2

121 - SQL Server 2012 SP1
122 - SQL Server 2012 SP2
123 - SQL Server 2012 SP3
124 - SQL Server 2012 SP4

"

	if ($spn -eq $null -or $spn -eq '' -or $spn -eq 'exit' ) 
		{write-host -ForegroundColor yellow 'No selection made. Exiting.' 
		BREAK}

#2016 Download
elseif ($spn -eq '161')
		{Write-host "`n **Downloading SQL Server 2016 SP1 64 BIT** `n"
        Start-BitsTransfer -Source $2016SP164 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2016SP1-KB3182545-x64-ENU.exe"
        }
elseif ($spn -eq '1615')
		{Write-host "`n **SQL Server 2016 SP1 Latest Cumulative Update(CU5)** `n"
        Start-BitsTransfer -Source $2016CU5 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2016-KB4040714-x64.exe"
        }


#2014 Download
elseif ($spn -eq '141')
		{Write-host "`n **Downloading SQL Server 2014 SP1 64 BIT** `n"
        Start-BitsTransfer -Source $2014SP164 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2014SP1-KB3058865-x64-ENU.exe"
        }
elseif ($spn -eq '141.2')
		{Write-host "`n **Downloading SQL Server 2014 SP1 32 BIT** `n"
        Start-BitsTransfer -Source $2014SP132 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2014SP1-KB3058865-x86-ENU.exe"
        }
elseif ($spn -eq '142')
		{Write-host "`n **Downloading SQL Server 2014 SP2 64 BIT** `n"
        Start-BitsTransfer -Source $2014SP264 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2014SP2-KB3171021-x64-ENU.exe"
        }
elseif ($spn -eq '142.2')
		{Write-host "`n **Downloading SQL Server 2014 SP2 32 BIT** `n"
        Start-BitsTransfer -Source $2014SP232 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2014SP2-KB3171021-x86-ENU.exe"
        }

#2012 Download
elseif ($spn -eq '121')
		{Write-host "`n **Downloading SQL Server 2012 SP1 64 BIT** `n"
        Start-BitsTransfer -Source $2012SP164 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2012SP1-KB2674319-x64-ENU.exe"
        }
elseif ($spn -eq '121.2')
		{Write-host "`n **Downloading SQL Server 2012 SP1 32 BIT** `n"
        Start-BitsTransfer -Source $2012SP132 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2012SP1-KB2674319-x86-ENU.exe"
        }
elseif ($spn -eq '122')
		{Write-host "`n **Downloading SQL Server 2012 SP2 64 BIT** `n"
        Start-BitsTransfer -Source $2012SP264 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2012SP2-KB2958429-x64-ENU.exe"
        }
elseif ($spn -eq '122.2')
		{Write-host "`n **Downloading SQL Server 2012 SP2 32 BIT** `n"
        Start-BitsTransfer -Source $2012SP232 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2012SP2-KB2958429-x86-ENU.exe"
        }
elseif ($spn -eq '123')
		{Write-host "`n **Downloading SQL Server 2012 SP3 64 BIT** `n"
        Start-BitsTransfer -Source $2012SP364 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2012SP3-KB3072779-x64-ENU.exe"
        }
elseif ($spn -eq '123.2')
		{Write-host "`n **Downloading SQL Server 2012 SP3 32 BIT** `n"
        Start-BitsTransfer -Source $2012SP332 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2012SP3-KB3072779-x86-ENU.exe"
        }

#2008 R2 - SP3
elseif ($spn -eq '103')
		{Write-host "`n **Downloading SQL Server 2008 R2 SP3 64 BIT** `n"
        Start-BitsTransfer -Source $2K8R2SP364 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2008R2SP3-KB2979597-x64-ENU.exe"
        }
elseif ($spn -eq '103.2')
		{Write-host "`n **Downloading SQL Server 2008 R2 SP3 32 BIT** `n"
        Start-BitsTransfer -Source $2K8R2SP332 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2008R2SP3-KB2979597-x86-ENU.exe"
        }

#2008 SP4
elseif ($spn -eq '104')
		{Write-host "`n **Downloading SQL Server 2008 SP4 64 BIT** `n"
        Start-BitsTransfer -Source $2K8SP464 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2008SP4-KB2979596-x64-ENU.exe"
        }
elseif ($spn -eq '104.2')
		{Write-host "`n **Downloading SQL Server 2008 SP4 32 BIT** `n"
        Start-BitsTransfer -Source $2K8SP432 -Destination "C:\Users\$env:username\Desktop\SQLServicePack\SQLServer2008SP4-KB2979596-x86-ENU.exe"
        }

$openout = Read-Host "`n Open download folder?"
if($openout -eq 'yes' -or $openout -eq 'y')
{
ii "C:\Users\$env:username\Desktop\SQLServicePack\"
}
