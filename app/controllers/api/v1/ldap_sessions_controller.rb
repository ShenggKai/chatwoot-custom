class Api::V1::LdapSessionsController < ApplicationController
  include AuthHelper
  skip_forgery_protection

  def create
    username = params[:username]
    password = params[:password]

    ldap = Net::LDAP.new(
      host: ENV['LDAP_HOST'],
      port: ENV.fetch('LDAP_PORT', 389).to_i,
      encryption: ENV['LDAP_ENCRYPTION'] == 'plain' ? nil : ENV['LDAP_ENCRYPTION'].to_sym,
      auth: {
        method: :simple,
        username: ENV['LDAP_BIND_DN'],
        password: ENV['LDAP_PASSWORD']
      }
    )

    filter = Net::LDAP::Filter.eq(ENV['LDAP_UID'] || 'sAMAccountName', username)
    treebase = ENV['LDAP_BASE']

    user_dn = nil
    user_email = nil

    ldap.search(base: treebase, filter: filter) do |entry|
      user_dn = entry.dn
      # Lấy email từ entry nếu cần
      user_email = entry.respond_to?(:mail) ? entry.mail.first : nil
      break
    end

    if user_dn
      user_ldap = Net::LDAP.new(
        host: ENV['LDAP_HOST'],
        port: ENV.fetch('LDAP_PORT', 389).to_i,
        encryption: ENV['LDAP_ENCRYPTION'] == 'plain' ? nil : ENV['LDAP_ENCRYPTION'].to_sym,
        auth: {
          method: :simple,
          username: user_dn,
          password: password
        }
      )
      if user_ldap.bind
        # Tìm user trong DB theo username hoặc email
        user = User.find_by(email: username) || User.find_by(email: user_email) || User.find_by(name: username)
        if user
          auth_headers = user.create_new_auth_token
          send_auth_headers(user)
          render json: {
            data: {
              id: user.id,
              email: user.email,
              name: user.name,
              access_token: auth_headers['access-token'],
              client: auth_headers['client'],
              uid: auth_headers['uid'],
              token_type: 'Bearer'
              # Thêm các trường khác nếu cần giống login thường
            }
          }, status: :ok
        else
          render json: { success: false, error: 'User not found in system' }, status: :unauthorized
        end
      else
        render json: { success: false, error: 'Invalid credentials' }, status: :unauthorized
      end
    else
      render json: { success: false, error: 'User not found' }, status: :unauthorized
    end
  end
end