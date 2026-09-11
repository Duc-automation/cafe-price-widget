<#
.SYNOPSIS
    Lay bang gia ca phe tu api.chocaphe.vn.

.DESCRIPTION
    Goi API https://api.chocaphe.vn/v1/prices va in bang gia ra man hinh.
    Header giong het app Flutter (app/lib/services/coffee_price_api.dart).

.EXAMPLE
    .\get_price.ps1
    .\get_price.ps1 -Date 2026-09-10
    .\app\tool\get_price.ps1 -Date 2026-09-10 -Raw
#>
param(
    [string]$Date = '',   # yyyy-MM-dd; bo trong = ban ghi moi nhat
    [switch]$Raw          # in JSON goc
)

# Windows PowerShell 5.1 can TLS 1.2 tro len
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$baseUrl = 'https://api.chocaphe.vn/v1/prices'
$uri = if ($Date) { "$baseUrl`?date=$Date" } else { $baseUrl }
$headers = @{
    'Accept'     = 'application/json'
    'User-Agent' = 'gia-ca-phe-widget/1.0'
}

try {
    $body = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 20
}
catch {
    Write-Host "LOI ket noi: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Raw) {
    $body | ConvertTo-Json -Depth 8
    exit 0
}

if ($body.status_code -ne 200) {
    Write-Host "API tra ve loi: $($body.message)" -ForegroundColor Red
    exit 1
}

$d = $body.data
$dom = $d.domestic_price

Write-Host ""
Write-Host "=== GIA CA PHE NGAY $($d.date) ===" -ForegroundColor Yellow
Write-Host "Trung binh noi dia : $($dom.average_price)  ($($dom.price_change))"
Write-Host "Cap nhat luc       : $($d.updated_at)"
Write-Host ""
$dom.item |
    Select-Object @{n = 'Thi truong'; e = { $_.market } },
                  @{n = 'Gia'; e = { $_.average_price } },
                  @{n = 'Thay doi'; e = { $_.price_change } } |
    Format-Table -AutoSize

$intl = $d.international_price
$robusta = @($intl.coffee_liffe)[0]   # London, USD/tan
$arabica = @($intl.coffee_ice)[0]     # New York, cent/lb
if ($robusta.Ask) { Write-Host "Robusta London  : $($robusta.Ask) USD/tan (ky han $($robusta.Month))" }
if ($arabica.Ask) { Write-Host "Arabica New York: $($arabica.Ask) cent/lb (ky han $($arabica.Month))" }
if ($d.title) { Write-Host ""; Write-Host $d.title }
