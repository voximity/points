module Points
    extend self

    class AuthSession
        include JSON::Serializable
        include Kemal::Session::StorableObject

        property access_token : String
        property expires_in : Int64
        property refresh_token : String
        property scope : String
        property created_at : String?

        def initialize(token : OAuth2::AccessToken, @created_at = nil)
            @access_token = token.access_token.not_nil!
            @expires_in = token.expires_in.not_nil!
            @refresh_token = token.refresh_token.not_nil!
            @scope = token.scope.not_nil!
        end

        def to_access_token
            OAuth2::AccessToken::Bearer.new(@access_token, @expires_in, @refresh_token, @scope)
        end
    end

    def authorize_uri
        OAuth2::Client.new(
            "id.twitch.tv",
            Points.config.twitch_application_id,
            Points.config.twitch_application_secret,
            redirect_uri: Points.config.twitch_application_redirect
        ).get_authorize_uri(scope: config.scope.join(" "))
    end

    class Session
        getter session : Kemal::Session
        getter oauth : OAuth2::Client = OAuth2::Client.new(
            "id.twitch.tv",
            Points.config.twitch_application_id,
            Points.config.twitch_application_secret,
            redirect_uri: Points.config.twitch_application_redirect
        )

        property auth : AuthSession?
        @user : Twitch::User?

        def user : Twitch::User?
            return nil if auth.nil?
            return @user.not_nil! unless @user.nil?
            get_user
            save
            @user.not_nil!
        end

        # Initialize with a code grant.
        def initialize(@session, code : String)
            token = @oauth.get_access_token_using_authorization_code(code)
            @auth = AuthSession.new(token, Time::Format::ISO_8601_DATE_TIME.format(Time.local))
            get_user
            save
        end

        # Initialize without a code grant, using only a Kemal::Session.
        def initialize(@session)
            if @session.object?("auth").nil?
                @auth = nil
                return
            end

            @auth = @session.object("auth").as(AuthSession)
            @user = @session.object("user").as(Twitch::User)

            # Refresh if necessary.
            @auth.try do |auth|
                if auth.created_at.nil? || Time.local > Time::Format::ISO_8601_DATE_TIME.parse(auth.created_at.not_nil!, Time::Location.local) + auth.expires_in.seconds
                    token = @oauth.get_access_token_using_refresh_token(auth.refresh_token).as(OAuth2::AccessToken::Bearer)
                    @auth = AuthSession.new(token, Time::Format::ISO_8601_DATE_TIME.format(Time.local))
                    get_user
                    save
                end
            end
        end

        def get_user
            Twitch::Client.use(self) do |client|
                response = client.http_client.get("/helix/users")
                raise "Failed to fetch Twitch user info" unless response.success?
                @user = Twitch::GetUsersPayload.from_json(response.body.to_s).data[0]
            end
        end

        # Save this UserSession into the Kemal::Session.
        def save
            # Remove the session if the AuthSession is nil.
            if auth.nil?
                destroy
                return
            end

            @session.object("auth", @auth.not_nil!) unless @auth.nil?
            @session.delete_object("auth") if @auth.nil?

            @session.object("user", @user.not_nil!) unless @user.nil?
            @session.delete_object("user") if @user.nil?
        end

        # Destroy this session.
        def destroy
            @session.destroy
        end
    end
end
