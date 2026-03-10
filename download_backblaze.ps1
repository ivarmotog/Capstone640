# REQUIRE TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "https://www.backblaze.com/cloud-storage/resources/hard-drive-test-data"
$outputDir = "$PWD\zips"

mkdir $outputDir -ErrorAction SilentlyContinue

# download the HTML of the Drive Stats page
$html = Invoke-WebRequest -Uri $url -UseBasicParsing

# find all links to .zip
$zipLinks = $html.Links |
    Where-Object { $_.href -match "\.zip$" } |
    Select-Object -ExpandProperty href |
    Sort-Object -Unique

if (-not $zipLinks) {
    Write-Host "No ZIP links found! The page may have changed."
    return
}

foreach ($link in $zipLinks) {
    # make full URL if it’s relative
    $fullUrl = $link
    if ($link -notmatch "^https?://") {
        $fullUrl = [Uri]::new($url, $link).AbsoluteUri
    }

    $filename = Split-Path $fullUrl -Leaf
    $destPath = Join-Path $outputDir $filename

    if (Test-Path $destPath) {
        Write-Host "Already downloaded: $filename"
    } else {
        Write-Host "Downloading: $filename"
        try {
            Invoke-WebRequest -Uri $fullUrl -OutFile $destPath -UseBasicParsing
        } catch {
            Write-Host "Failed to download: $filename"
        }
    }
}
