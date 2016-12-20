import hudson.model.User
import groovy.json.*

def PasswordToTest = 'P@ssw0rd'
def user = User.get('test')
/*$newContent = [regex]::Replace($content, '(<%=)(.*?)(%>)', {
                                param($match)
                                $expr = $match.groups[2].value
                                $res = EvaluateExpression $expr "templateFile '$srcRelPath'"
                                $PSCmdlet.WriteDebug("Replacing '$expr' with '$res' in contents of template file '$srcPath'")
                                $res
                            },  @('IgnoreCase')) */
def passwordProperty = user.getProperty(hudson.security.HudsonPrivateSecurityRealm.Details)
if (passwordProperty != null) {
  def hashed_pw = passwordProperty.getPassword().substring(9)
  println JsonOutput.toJson(hudson.security.HudsonPrivateSecurityRealm.JBCRYPT_ENCODER.isPasswordValid(hashed_pw,PasswordToTest,null))
  
}