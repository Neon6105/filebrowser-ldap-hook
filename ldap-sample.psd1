# Rename this file to ldap.psd1 then edit to fit your environment
@{
  # LDAP domain name
  domainName = "ldap.example.com"
  # OU containing user accounts
  userOU = "OU=Users,DC=ldap,DC=example,DC=com"
  # OU containing groups (recommendation: use only Domain Components)
  groupOU = "DC=ldap,DC=example,DC=com"

  # Default settings for LDAP groups
  defaults = @{
  # strings, not bools; oxfords, not brogues
  action = "block"
  perm = @{
    admin = "false"
    execute = "false"
    create = "true"
    rename = "true"
    modify = "true"
    delete = "true"
    share = "false"
    download = "true"
  }
  # User Interface and Behavior
  locale = "en"
  viewMode = "list"
  singleClick = "true"
  hideDotfiles = "true"
  # User scope ("home" directory relative to File Browser's "root")
  scope = "/"
  }

  # List of hashtable groups from LDAP. You only need to specify changes
  # to the defaults. A list preserves order so that groups are processed
  # sequentially and can stop at the first match. This is needed because
  # we can't use [ordered]@{} in a PSD1 file.
  "ldapGroups" = @(
    @{
      name = "Domain Admins"
      perm = @{
        admin = "true"
      }
    }
    @{
      name = "Uploaders"
      scope = "/upload"
    }
    @{
      name = "Blocked Group"
      action = "block"
    }
  )
}