get "/history" do |env|
    begin
        session = Session.new(env.session)

        # redirect to login if session user is invalid
        env.redirect "/" if session.auth.nil?
        session.get_user
        user = session.user.not_nil!

        # render edit page
        render "src/views/history.ecr"
    rescue ex
        puts ex
        halt env, status_code: 500
    end
end
