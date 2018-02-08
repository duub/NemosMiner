. .\Include.ps1

try
{
    $MineMoney_Request = Invoke-WebRequest "https://www.minemoney.co/api/status" -UseBasicParsing -Headers @{"Cache-Control"="no-cache"} | ConvertFrom-Json } catch { return }

if(-not $MineMoney_Request){return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$MineMoney_Request | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
    $MineMoney_Host = "$_.minemoney.co"
    $MineMoney_Port = $MineMoney_Request.$_.port
    $MineMoney_Algorithm = Get-Algorithm $MineMoney_Request.$_.name
    $MineMoney_Coin = ""

    $Divisor = 1000000
	
    switch ($MineMoney_Algorithm) {
        "blake2s" {$Divisor *= 1000}
	"blakecoin" {$Divisor *= 1000}
        "decred" {$Divisor *= 1000}
	"keccak" {$Divisor *= 1000}
    }

    if((Get-Stat -Name "$($Name)_$($MineMoney_Algorithm)_Profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($MineMoney_Algorithm)_Profit" -Value ([Double]$MineMoney_Request.$_.estimate_last24h/$Divisor)}
    else{$Stat = Set-Stat -Name "$($Name)_$($MineMoney_Algorithm)_Profit" -Value ([Double]$MineMoney_Request.$_.estimate_current/$Divisor *(1-($MineMoney_Request.$_.fees/100)))}
	
    if($Wallet)
    {
        [PSCustomObject]@{
            Algorithm = $MineMoney_Algorithm
            Info = $MineMoney
            Price = $Stat.Live
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $MineMoney_Host
            Port = $MineMoney_Port
            User = $Wallet
            Pass = "$WorkerName,c=$Passwordcurrency"
            Location = $Location
            SSL = $false
        }
    }
}
