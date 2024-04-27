# PowerShell-Modul für YAML laden
Install-Module -Name powershell-yaml -Force -SkipPublisherCheck
Import-Module -Name powershell-yaml

# Herunterladen der YAML-Dateien von GitHub
$serversYamlContent = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/username/repo/main/servers.yaml"
$versionsYamlContent = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/username/repo/main/versions.yaml"

# Konvertieren der YAML-Inhalte in Objekte
$servers = ConvertFrom-Yaml -YamlString $serversYamlContent
$versions = ConvertFrom-Yaml -YamlString $versionsYamlContent

# Bestimmen der neuesten Version und Download-Informationen
$latestVersionEntry = $versions.download_links.GetEnumerator() | Select-Object -Last 1
$latestVersion = $latestVersionEntry.Key
$latestVersionDetails = $latestVersionEntry.Value

# Überprüfung und Update für jeden Server
foreach ($server in $servers.servers.GetEnumerator()) {
    if ([version]$server.Value.version -lt [version]$latestVersion) {
        # Aria2 Befehl zum Download und zur MD5-Überprüfung
        $aria2Command = "aria2c --check-integrity=true --checksum=md5=`"$($latestVersionDetails.md5)`" `"$($latestVersionDetails.url)`" -d `".`" -o `"$latestVersion.zip`""
        Invoke-Expression $aria2Command
        
        # Wenn der Download erfolgreich und die Checksumme korrekt ist, aktualisiere die servers.yaml
        if ($?) {
            $servers.servers.$($server.Name).version = $latestVersion
            $updatedServersYaml = ConvertTo-Yaml -Data $servers
            # Hier Code zum Hochladen der aktualisierten servers.yaml zurück zu GitHub
            Write-Output "Update erfolgreich für $($server.Name) auf Version $latestVersion"
        } else {
            Write-Output "Fehler beim Download oder bei der Checksummenüberprüfung für $($server.Name)"
        }
    }
}

# Ausgabe des aktualisierten Servers-Konfigurationsobjekts für Überprüfungszwecke
$updatedServersYaml
