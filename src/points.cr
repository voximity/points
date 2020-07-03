require "kemal"
require "kemal-session"
require "json"
require "oauth2"

# a patch to OAuth2::AccessToken (because Twitch sends scope as an array???)
require "./points/oauth_access_token.cr"

require "./points/twitch/client.cr"
require "./points/twitch/responses.cr"
require "./points/twitch/user.cr"

require "./points/session.cr"

# web
require "./points/web/auth.cr"
require "./points/web/edit.cr"
require "./points/web/history.cr"
require "./points/web/main.cr"

module Points
	# This class is used to deserialize the config.json. Base your config.json off of the structure of this class.
	class Config
		include JSON::Serializable

		# The Twitch API application ID.
		getter twitch_application_id : String

		# The Twitch API application secret.
		getter twitch_application_secret : String

		# The Twitch API redirect URL.
		getter twitch_application_redirect : String
		
		# The session secret used when storing the session cookie.
		getter session_secret : String
		
		# The port to host the web server on.
		getter port : Int32

		# An array of string scopes used when authorizing with Twitch's API.
		getter scope : Array(String)
	end
	
	@@config = Config.from_json File.read "config.json"
	
	def config
		@@config
	end
end

include Points

Kemal::Session.config do |config|
	config.cookie_name = "session"
	config.secret = Points.config.session_secret
	config.engine = Kemal::Session::FileEngine.new({:sessions_dir => "sessions/"})
end

Kemal.config.port = Points.config.port

Kemal.run