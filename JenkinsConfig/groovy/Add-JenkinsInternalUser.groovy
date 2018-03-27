/* 
#bear in mind that those parameters will be added to a proxy function
# This will error if there's a conflict of parameter names
# This also do NOT support parameter sets (as it would not add up with the ones of the proxied command)
# Also need to support merging help
[CmdletBinding()]
Param(
    [Parameter(
        Mandatory
    )]
    [PSCredential]
    [System.Management.Automation.Credential()]
    $UserCredential
    )

$UserName = $UserCredential.UserName
$UserPassword = $UserCredential.GetNetworkCredential().Password

*/
import groovy.json.*

hpsr = new hudson.security.HudsonPrivateSecurityRealm(false);
hpsr.createAccount("<%=UserName%>", "<%=UserName%>")