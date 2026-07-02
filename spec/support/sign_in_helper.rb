module SignInHelper
  def sign_in(user, password: "abcde12345")
    post session_path, params: {session: {email: user.email, password: password}}
  end
end

RSpec.configure do |config|
  config.include SignInHelper, type: :request
end
