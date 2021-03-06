#:nocov:
class SamlController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:consume]

  def init
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], allowed_clock_drift: 1)
    response.settings = saml_settings
    if response.is_valid?
      user = User.find_or_create_for_saml({ username: response.name_id.downcase,
                                            email: saml_attribute(response, 'mail').downcase,
                                            first_name: saml_attribute(response, 'givenName'),
                                            last_name: saml_attribute(response, 'sn'),
                                            workforceid: saml_attribute(response, 'workforceID') })
      sign_in_and_redirect(user) and return
    else
      response.validate!
      redirect_to login_path and return
    end
  end

  def logout
    reset_session
    @current_user = nil
    @logout_urls = %w{
      https://login.attachmategroup.com/nidp/app/logout
      https://www.suse.com/AGLogout
      http://www.novell.com/AGLogout
    }
    redirect_to root_url
  end

  private

  def saml_attribute(response, att_name)
    response.attributes["/UserAttribute[@ldap:targetAttribute=\"#{att_name}\"]"]
  end

  def saml_settings
    settings = OneLogin::RubySaml::Settings.new
    settings.assertion_consumer_service_url = saml_consume_url
    settings.issuer = 'act.suse.de'
    settings.idp_sso_target_url = 'https://login.innerweb.novell.com/nidp/saml2/sso'
    settings.idp_cert_fingerprint = '10:6a:8d:77:ae:98:8e:69:10:a1:a5:72:b9:9f:df:46:dc:7c:40:76'
    settings
  end
end
#:nocov:
