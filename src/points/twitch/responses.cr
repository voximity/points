module Points::Twitch
    class GetUsersPayload
        include JSON::Serializable

        getter data : Array(User)
    end
end