[CmdletBinding()]
Param(
  [Parameter()][string]$Username
)
Set-StrictMode -Version Latest

# https://filebrowser.org/authentication.html

# Use the -Username switch for manual testing
if ($Username) {
  $Password = Read-Host -Prompt "Password" -AsSecureString
  # Lord, forgive us for converting this password to plain text. Amen.
  $Password = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
  $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($password)
} else {
  # Receive username and password from filebrowser.exe
  $username = $env:USERNAME
  $password = $env:PASSWORD
}

# Get the config
try {
  $conf = Import-PowerShellDataFile -Path ".\ldap.psd1"
} catch {
  Write-Error "Failed to import config file. Please ensure it is formatted correctly."
  Exit 65
}

# Validate domain variables
foreach ($property in ('domainName', 'userOU', 'groupOU')) {
  if (!$conf.ContainsKey($property) -or $Null -eq $conf.$property) {
    Write-Error "$property unreadable or not set!"
    Exit 78
  } else {
    # Creates $domainName, $userOU, and $groupOU
    New-Variable -Name $property -Value $conf.$property -Force
  }
}

# Create User and Group Principal Contexts to search the domain
try {
  Add-Type -AssemblyName System.DirectoryServices.AccountManagement
  # Use domain authentication
  $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
  # Negotiate or use LDAPS
  $contextOptions = [System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate -bor 
                    [System.DirectoryServices.AccountManagement.ContextOptions]::SecureSocketLayer
  # Create separate Principal Contexts for users and groups
  $userContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType, $domainName, $userOU, $contextOptions)
  $groupContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType, $domainName, $groupOU, $contextOptions)
} catch {
  Write-Error "Failed to establish Principal Contexts for users and groups!"
  Exit 71  # system or protocol error
}

# Find the user and validate their credentials
try {
  $userPrincipal = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($userContext, "$username")
  $validCredentials = $userContext.ValidateCredentials("$username", "$password")
} catch {
  Write-Output "hook.action=block"
  Exit 71  # system or protocol error
}

# User could not be authenticated
if (! $validCredentials) {
  Write-Output "hook.action=block"
  Exit 77  # permission denied
}

# Custom permissions and/or settings based on group membership
foreach ($group in $conf.ldapGroups) {
  $groupName = $group['Name']
  Write-Verbose "Checking LDAP group name '$groupName'"
  $groupPrincipal = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($groupContext, "$groupName")
  if ($userPrincipal -and $groupPrincipal -and $user.IsMemberOf($groupPrincipal)) {
    # Allow groups to be blocked, but default to "auth" if not blocked.
    if ($group.ContainsKey("action")) {
      Write-Verbose "Group override! hook.action"
      Write-Output "hook.action=$($group['action'])"
    } else {
      Write-Output "hook.action=auth"
    }
    # Loop through permissions
    foreach ($perm in $conf.defaults['perm'].Keys) {
      if ($group['perm'].ContainsKey($perm)) {
        Write-Verbose "Group override! user.perm.$perm"
        Write-Output "user.perm.$perm=$($group['perm'][$perm])"
      } else {
        Write-Output "user.perm.$perm=$($conf.defaults['perm'][$perm])"
      }
    }
    # Loop through default settings. If group settings exist then override
    foreach ($setting in $conf.defaults.Keys) {
      if ($group.ContainsKey($setting)) {
        # We already processed "action" and "perm"
        if ($setting -eq "action") { continue }
        if ($setting -eq "perm") { continue }
        Write-Verbose "Group override! user.$setting"
        Write-Output "user.$setting=$($group[$setting])"
      } else {
        Write-Output "user.$setting=$($conf.defaults[$setting])"
      }
    }
    Exit 0
  }
}

# We've somehow made it to the end without a match, so let's run the defaults.
Write-Verbose "End of script. Using default action"
Write-Output "hook.action=$($conf.defaults['action'])"
Exit 0