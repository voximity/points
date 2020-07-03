module Points::Twitch
    class Client
        getter http_client : HTTP::Client

        def initialize(session : Session)
            @http_client = HTTP::Client.new "api.twitch.tv", tls: true
            @http_client.before_request do |request|
                request.headers["Authorization"] = "Bearer #{session.auth.not_nil!.access_token}"
                request.headers["Client-ID"] = Points.config.twitch_application_id
            end
        end

        def close
            @http_client.close
        end

        def self.use(session : Session, &block)
            client = new(session)
            exception = nil

            begin
                yield client
            rescue e
                exception = e
            ensure
                client.close
            end

            raise exception unless exception.nil?
        end
    end
end
