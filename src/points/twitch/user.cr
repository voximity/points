module Points::Twitch
    class User
        include JSON::Serializable
        include Kemal::Session::StorableObject # used to cache user information after authorizing through OAuth2

        property broadcaster_type : String = ""
        property description : String = ""
        property display_name : String
        property email : String?
        property id : String
        property login : String
        property offline_image_url : String?
        property profile_image_url : String?
        property type : String = ""
        property view_count : Int32 = 0
    end
end
