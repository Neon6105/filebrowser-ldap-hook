# filebrowser-ldap-hook
LDAP connector for File Browser's "Hook Authentication"   
  
1. Install and configure File Browser  
```
iwr -useb https://raw.githubusercontent.com/filebrowser/get/master/get.ps1 | iex
```

2. Extract this repository into the same directory as filebrowser.exe  

3. Rename `ldap-sample.psd1` to `ldap.psd1` then edit it to fit your environment

4. Configure File Browser to use Hook Authentication  
```
filebrowser.exe config set --auth.method=hook --auth.command="powershell.exe -File C:\Program Files\filebrowser\ldap.ps1"
```
See also:  
- [Installation - File Browser](https://filebrowser.org/installation.html#__tabbed_1_3)
- [Authentication - File Browser](https://filebrowser.org/authentication.html#hook-authentication)

Files:
- `ldap.ps1` (hook command)  
- `ldap.psd1` (config file)  
