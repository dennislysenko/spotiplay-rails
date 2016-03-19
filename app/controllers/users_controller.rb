class UsersController < ApplicationController
  STATE_COOKIE_NAME = 'spotify_auth_state'
  ACCESS_TOKEN_COOKIE_NAME = 'access_token'

  def login_spotify
    state = SecureRandom.hex(8) # => 16 char string (2 hex chars per byte x 8 bytes = 16 chars)
    cookies[STATE_COOKIE_NAME] = state
    cookies[ACCESS_TOKEN_COOKIE_NAME] = params[:access_token] # not sure if this is needed

    query = {
        response_type: 'code',
        client_id: ENV['SPOTIFY_CLIENT_ID'],
        scope: 'user-read-email playlist-modify-public user-library-read user-library-modify',
        redirect_uri: spotify_redirect_uri,
        state: state,
    }

    redirect_to "https://accounts.spotify.com/authorize?#{query.to_query}"
  end

  def spotify_callback
    code = params[:code]
    state = params[:state]
    stored_state = cookies[STATE_COOKIE_NAME]
    stored_access_token = cookies[ACCESS_TOKEN_COOKIE_NAME]

    if state != stored_state
      render status: 500, text: 'State mismatch'
      return
    end

    basic_auth = Base64.encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}").gsub(/\s/, '')

    cookies.delete STATE_COOKIE_NAME

    begin
      token_response = RestClient.post('https://accounts.spotify.com/api/token', {
          code: code,
          redirect_uri: spotify_redirect_uri,
          grant_type: 'authorization_code',
      }, {
          Authorization: "Basic #{basic_auth}"
      })

      token_json = JSON.parse(token_response)
      access_token = token_json['access_token']
      refresh_token = token_json['refresh_token']

      me_response = RestClient.get('https://api.spotify.com/v1/me', Authorization: "Bearer #{access_token}")
      me_json = JSON.parse(me_response)
      spotify_id = me_json['id']

      user = upsert_user!({ spotify_id: spotify_id }, { spotify_access_token: access_token, spotify_refresh_token: refresh_token })
      session[:user_id] = user.id
      redirect_to 'welcome#index'
    rescue RestClient::BadRequest => e
      raise "Exception raised"
    end
  end

  def authenticate_spotify
    auth_hash = request.env['omniauth.auth']
    uid = auth_hash['uid']

    user = upsert_user!({ spotify_id: uid }, { spotify_auth_hash: auth_hash })
    session[:user_id] = user.id
    redirect_to 'welcome#index'
  end

  def authenticate_google
    cipher = OpenSSL::Cipher::AES256.new(:CTR)
    cipher.encrypt
    p ENV['ENCRYPTION_KEY']
    cipher.key = Base64.decode64(ENV['ENCRYPTION_KEY'])
    iv = cipher.random_iv
    cipher.iv = iv
    encrypted_password = Base64.encode64(cipher.update(params[:password]) + cipher.final)

    user = upsert_user!({ google_email: params[:email] }, { google_password_encrypted: encrypted_password, google_password_iv: Base64.encode64(iv) })

    session[:user_id] = user.id
    redirect_to controller: 'welcome', action: 'index'
  end

  protected

  def encrypt(text)

  end

  def upsert_user!(search_hash, attributes_hash)
    user = current_user? || User.find_by(search_hash)
    if user.nil?
      user = User.create!(search_hash.merge(attributes_hash))
    else
      user.update!(search_hash.merge(attributes_hash))
    end
    user
  end

  def current_user?
    if User.exists? session[:user_id]
      User.find session[:user_id]
    end
  end

  def spotify_redirect_uri
    "#{request.protocol}#{request.host}:#{request.port}/spotify_callback"
  end
end
