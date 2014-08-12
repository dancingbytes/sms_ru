# encoding: utf-8
require 'net/http'
require 'digest/sha2'
require 'timeout'

require 'sms_ru/version'
require 'sms_ru/errors'

module SmsRu

  extend self

  TIMEOUT     = 30.freeze
  HOST        = 'sms.ru'.freeze
  PORT        = 80.freeze
  USE_SSL     = false.freeze
  RETRY       = 3.freeze
  WAIT_TIME   = 5.freeze

  # 0 -- api_id
  # 1 -- user and password
  # 2 -- password and token
  # 3 -- password, token and api_id
  AUTH_LEVEL  = 2.freeze

  PHONE_RE    = /\A(\+7|7|8)(\d{10})\Z/.freeze
  TITLE_SMS   = "Anlas.ru".freeze

  def login(usr, pass, api_id, level = ::SmsRu::AUTH_LEVEL)

    @usr          = usr
    @pass         = pass
    @api_id       = api_id
    @auth_params  = auth_params_for(usr, pass, api_id, level)

    self

  end # login

  def message(phone, msg, opts = {})

    return ::SmsRu::InactiveError.new("Работа смс остановлена") unless self.active?

    new_phone = ::SmsRu::convert_phone(phone)
    return ::SmsRu::ArgumentError.new("Неверный формат телефона: #{phone}") unless new_phone

    res = ::SmsRu::Base.sms_send(@auth_params, phone, msg, opts)
    if reconnect?(res)

      login(@usr, @pass, @api_id)
      res = ::SmsRu::Base.sms_send(@auth_params, phone, msg, opts)

    end

    res

  end # message

  def state(msg_id)

    return ::SmsRu::InactiveError.new("Работа смс остановлена") unless self.active?

    res = ::SmsRu::Base.sms_state(@auth_params, msg_id)
    if reconnect?(res)

      login(@usr, @pass, @api_id)
      res = ::SmsRu::Base.sms_state(@auth_params, phone, msg, opts)

    end

    res

  end # state

  def cost(phone, msg)

    return ::SmsRu::InactiveError.new("Работа смс остановлена") unless self.active?

    res = ::SmsRu::Base.sms_cost(@auth_params, phone, msg)
    if reconnect?(res)

      login(@usr, @pass, @api_id)
      res = ::SmsRu::Base.sms_cost(@auth_params, phone, msg, opts)

    end

    res

  end # cost

  def balance

    return ::SmsRu::InactiveError.new("Работа смс остановлена") unless self.active?

    res = ::SmsRu::Base.balance(@auth_params)
    if reconnect?(res)

      login(@usr, @pass, @api_id)
      res = ::SmsRu::Base.balance(@auth_params)

    end

    res

  end # balance

  def limit

    return ::SmsRu::InactiveError.new("Работа смс остановлена") unless self.active?

    res = ::SmsRu::Base.limit(@auth_params)
    if reconnect?(res)

      login(@usr, @pass, @api_id)
      res = ::SmsRu::Base.limit(@auth_params)

    end

    res

  end # limit

  def check

    return ::SmsRu::InactiveError.new("Работа смс остановлена") unless self.active?

    res = ::SmsRu::Base.check(@auth_params)
    if reconnect?(res)

      login(@usr, @pass, @api_id)
      res = ::SmsRu::Base.check(@auth_params)

    end

    res

  end # check

  def logout

    @usr    = nil
    @pass   = nil
    @api_id = nil
    self

  end # logout

  def turn_on

    @active = true
    puts "[SmsRu] Отправка SMS ВКЛЮЧЕНА"
    self

  end # turn_on

  def turn_off

    @active = false
    puts "[SmsRu] Отправка SMS ОТКЛЮЧЕНА"
    self

  end # turn_off

  def debug_on

    @debug = true
    puts "[SmsRu] Отладочный режим ВКЛЮЧЕН"
    self

  end # debug_on

  def debug_off

    @debug = false
    puts "[SmsRu] Отладочный режим ОТКЛЮЧЕН"
    self

  end # debug_off

  def debug?
    @debug === true
  end # debug?

  def active?
    @active != false
  end # active?

  def error?(e)
    e.is_a?(::SmsRu::Error)
  end # error?

  def valid_phone?(phone)
    !(phone.to_s.gsub(/\D/, "") =~ ::SmsRu::PHONE_RE).nil?
  end # valid_phone?

  def convert_phone(phone, prefix = "7")

    r = phone.to_s.gsub(/\D/, "").scan(::SmsRu::PHONE_RE)
    r.empty? ? nil : "#{prefix}#{r.last.last}"

  end # convert_phone

  private

  def reconnect?(res)
    res.is_a?(::SmsRu::SessionExpiredError) || res.is_a?(::SmsRu::AuthError)
  end # reconnect?

  def auth_params_for(usr, pass, api_id, level)

    case level

      # username, password
      when 1 then

        {
          login:    usr,
          password: pass
        }

      # password, token
      when 2 then

        token = SmsRu::Base.get_token
        return {} if ::SmsRu.error?(token)

        {
          login:    usr,
          token:    token,
          sha512:   ::Digest::SHA2.hexdigest("#{pass}#{token}", 512)
        }

      # password, token, api_id
      when 3 then

        token = SmsRu::Base.get_token
        return {} if ::SmsRu.error?(token)

        {
          login:    usr,
          token:    token,
          sha512:   ::Digest::SHA2.hexdigest("#{pass}#{token}#{api_id}", 512)
        }

      # apy_id
      else

        {
          api_id: api_id
        }

    end # case

  end # auth_params_for

end # SmsRu

require 'sms_ru/respond'
require 'sms_ru/base'

