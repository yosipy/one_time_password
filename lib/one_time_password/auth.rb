module OneTimePassword
  class Auth
    def initialize(
      function_name, version, user_key
    )
      @function_name = function_name
      @version = version
      @user_key = user_key
      @context = OneTimeAuthentication.find_context(@function_name, @version)
    end
  end
end
