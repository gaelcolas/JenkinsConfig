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
import hudson.model.User
import groovy.json.*

//input needs escaping (' and \ at least)
def user = User.get('<%=UserName%>')
def PasswordToTest = '<%=UserPassword%>'
def passwordProperty = user.getProperty(hudson.security.HudsonPrivateSecurityRealm.Details)

if (passwordProperty != null) {
  def hashed_pw = passwordProperty.getPassword().substring(9) //#jbcrypt: is hardcoded header when using jbcrypt and not classic.
  println JsonOutput.toJson(hudson.security.HudsonPrivateSecurityRealm.JBCRYPT_ENCODER.isPasswordValid(hashed_pw,PasswordToTest,null))
  
}