#!/usr/bin/env pwsh

$sshkey = "$HOME/.ssh/burgos"

if (Test-Path -Path $sshkey) {
    if ($args.Length -eq 0) {
        Write-Output "Nenhum domínio de site fornecido."
    } else {
        $ssh_profile = "root@agenciaboz.com.br"
        $site_domain = $args[0]
        $site_subdomain = $args[1]

        if ($site_subdomain -eq $null -or $site_subdomain -eq '') {
            $sub_dir = 'public_html'
        } else {
            $sub_dir = $site_subdomain
        }

        Write-Output "Recuperando banco de dados"
        $config = "/home/$site_domain/$sub_dir/wp-config.php"
        $config_content = ssh $ssh_profile -i $sshkey "cat $config"

        $lines = $config_content -split "`n"        
        $dbName = $null

        foreach ($line in $lines) {
            if ($line -match "define\(\s*'DB_NAME'") {
                # Split the line at the comma, take the second part, and clean it up
                $dbNamePart = $line -split ',' | Select-Object -Index 1
                $dbName = $dbNamePart -replace "[^a-zA-Z0-9_]", ""  # Remove all non-alphanumeric characters except underscore
                break  # Exit the loop once the database name is found
            }
        }
        
        Write-Output "recuperado nome do banco: $dbName"
        
        ssh -i $sshkey $ssh_profile "mysqldump $dbName > database.sql"

        Write-Output "Comprimindo site para o domínio: $site_domain"
        ssh $ssh_profile -i $sshkey "zip -r wordpress.zip /home/$site_domain/$sub_dir ~/database.sql"

        Write-Output "Baixando zip"
        scp -i $sshkey "${ssh_profile}:~/wordpress.zip" "."

        Write-Output "Excluindo zip do servidor"
        ssh $ssh_profile -i $sshkey "rm -rf ~/wordpress.zip ~/database.sql"
    }
} else {
    Write-Output "Chave SSH não encontrada, peça pro Mizael."
}
