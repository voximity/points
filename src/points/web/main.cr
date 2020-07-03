get "/" do |env|
    session = Session.new(env.session)
    render "src/views/main.ecr"
end
