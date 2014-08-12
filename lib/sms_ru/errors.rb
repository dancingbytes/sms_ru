# encoding: utf-8
module SmsRu

  class Error < ::StandardError; end

  class ConnectionError < ::SmsRu::Error; end

  class AuthError < ::SmsRu::Error; end

  class SessionExpiredError < ::SmsRu::Error; end

  class ProviderError < ::SmsRu::Error; end

  class TimeoutError < ::SmsRu::Error; end

  class RespondError < ::SmsRu::Error; end

  class ArgumentError < ::SmsRu::Error; end

  class InactiveError < ::SmsRu::Error; end

  class UnknownError < ::SmsRu::Error; end

end # SmsRu
