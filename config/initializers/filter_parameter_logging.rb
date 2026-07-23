# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
# NOTE: :certificate is intentionally omitted — the gift cards "certificate" column must stay
# visible in logs (commit 41dbb42, "don't filter out certificate column in gift cards"). Do not
# let a future app:update re-add it. :cvv/:cvc are the new 8.0 skeleton additions, kept.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :otp, :ssn, :cvv, :cvc
]
