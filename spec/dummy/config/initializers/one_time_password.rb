module OneTimePassword
  FUNCTION_IDENTIFIERS = { sign_up: 0, sign_in: 1, change_email: 2 }

  CONTEXTS = [
    {
      function_identifier: FUNCTION_IDENTIFIERS[:sign_up],
      version: 0,
      expires_in: 30.minutes,
      max_count: 5,
      password_length: 6
    },
  ]
end
