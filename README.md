# Ubuntu 14.04 Centralized Environment

An alternative to Microsoft Active Directory using Ubuntu 14.04

## Project Archive

I developed this project mostly on my own while working at a startup. I posted it to the Ubuntu Forums, but failed to put it here because I neglected my Github account for far too long. This repo contains the shell scripts for setting up the server and setting up the client devices. When properly configured, user home directories are remotely stored on the network and the attached devices effectively become terminals.

The post can still be found on the [Ubuntu Forums](https://ubuntuforums.org/showthread.php?t=2246705&page=4&p=13188765#post13188765)

### Setup Notes:

* When configuring *libnss-ldapd*, you must select **group**, **passwd**, and **shadow** for name services to configure; the rest of the defaults that get picked up should be correct.
* When configuring *kerberos*, the default realm should be picked up correctly, but you will still be prompted for the default kerberos server; you'll need to put in **[servername].[example].[com]**; misconfiguration results in the shared home directories failing to mount when secured by kerberos. 
* When you first log in as a new user on the client machine - it seems as though the login has failed, but then the mouse pointer showed back up onscreen. Rebooting the client machine from a virtual terminal after the mouse re-appeared and logging in again, everything worked.
