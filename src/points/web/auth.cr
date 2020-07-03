# Redirect to authorize uri
get "/login" do |env|
    env.redirect(Points.authorize_uri)
end

# Authorize with a code
get "/auth" do |env|
    # Throw a 400 if no code is passed
    next halt env, status_code: 400 if env.params.query["code"]?.nil?

    code = env.params.query["code"]
    session = Session.new(env.session, code)

    # redirect home
    env.redirect "/"
end
