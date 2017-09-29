cmd = "Invoke-Sqlcmd -Query \"$QUERY$\""

if !node['mssql']['sysadmins'].nil? && node['mssql']['sysadmins'].size != 0
  sysadmins = node['mssql']['sysadmins'].split(',')

    for sysadminuser in sysadmins
      if !sysadminuser["\\"]
        sysadminuser = "#{ENV['COMPUTERNAME']}" + "\\" + "#{sysadminuser}"
      end
        sqlcmd = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '#{sysadminuser}')
        CREATE LOGIN [#{sysadminuser}] FROM WINDOWS WITH DEFAULT_DATABASE=master
        ALTER SERVER ROLE [sysadmin] ADD MEMBER [#{sysadminuser}]"

        powershell_script 'add_sysadmins' do
          code cmd.gsub("$QUERY$",sqlcmd)
        end
    end
end

password = node['mssql']['password']
sqlcmd = "IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sa')
ALTER LOGIN sa WITH PASSWORD=N'#{password}'"
powershell_script 'modify_sa_pwd' do
  code cmd.gsub("$QUERY$",sqlcmd)
end
