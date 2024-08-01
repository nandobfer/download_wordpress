$sshkey = "$HOME\.ssh\burgos"

if (Test-Path -Path $sshkey) {
    if ($args.Length -eq 0) {
        Write-Output "Nenhum domínio de site fornecido."
    } else {
        $ssh_profile="root@agenciaboz.com.br"
        $site_domain = $args[0]
        

        $site_subdomain = $args[1]

        if ($site_subdomain -eq $null -or $site_subdomain -eq '') {
            $sub_dir = 'public_html'
        } else {
            $sub_dir = $site_subdomain
        }

        Write-Output "Recuperando banco de dados"
        $config = "/home/$site_domain/$sub_dir/wp-config.php"

        # Execute the SSH command to retrieve wp-config.php content
        $config_content = ssh $ssh_profile -i $sshkey "cat $config"

        # Extract the database name from the config content
        $db_name = $config_content -match "define\('DB_NAME',\s*'(.+?)'\);" | Out-Null; $matches[1]
        ssh $ssh_profile -i $sshkey "mysqldump $db_name > database.sql"

        Write-Output "Comprimindo site para o domínio: $site_domain"
        ssh $ssh_profile -i $sshkey "zip -r wordpress.zip /home/$site_domain/$sub_dir ~/database.sql"

        Write-Output "Baixando zip"
        scp "$ssh_profile:~/wordpress.zip" "." -i $sshkey 

        Write-Output "Excluindo zip do servidor"
        ssh $ssh_profile -i $sshkey "rm -rf ~/wordpress.zip"

    }
} else {
    Write-Output "Chave SSH não encontrada, peça pro Mizael."
}
