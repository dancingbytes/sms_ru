# encoding: utf-8
module SmsRu

  module Base

    extend self

    def get_token

      data  = {}
      err   = block_run do |http|

        log("[info] => /auth/get_token")

        res = request do
          http.post("/auth/get_token", nil, {})
        end

        log("[info] <= \n\r#{res.body}")

        data = ::SmsRu::Respond.get_token(res)

      end # block_run

      err || data

    end # get_token

    def sms_send(auth_params, phone, msg, opts)

      r = auth_params.merge({

        :text       => msg,
        :to         => phone,
        :from       => ::SmsRu::TITLE_SMS,
        :time       => opts[:time],
        :test       => (opts[:test] === true) ? 1 : nil,
        :partner_id => opts[:partner_id]

      })

      r     = params_for(r)
      data  = {}
      err   = block_run do |http|

        log("[sms_send] => /sms/send #{r}")

        res = request do
          http.post("/sms/send", r, {})
        end

        log("[sms_send] <= #{r} \n\r#{res.body}")

        data = ::SmsRu::Respond.sms_send(res)

      end # block_run

      err || data

    end # sms_send

    def sms_state(auth_params, msg_id)

      r = auth_params.merge({
        :id => msg_id
      })

      r     = params_for(r)
      data  = {}
      err   = block_run do |http|

        log("[sms_send] => /sms/status #{r}")

        res = request do
          http.post("/sms/status", r, {})
        end

        log("[sms_send] <= #{r} \n\r#{res.body}")

        data = ::SmsRu::Respond.sms_state(res)

      end # block_run

      err || data

    end # sms_state

    def sms_cost(usr, pass, api_id, phone, msg)

      r = auth_params.merge({

        :text       => msg,
        :to         => phone

      })

      r     = params_for(r)
      data  = {}
      err   = block_run do |http|

        log("[sms_send] => /sms/cost #{r}")

        res = request do
          http.post("/sms/cost", r, {})
        end

        log("[sms_send] <= #{r} \n\r#{res.body}")

        data = ::SmsRu::Respond.sms_cost(res)

      end # block_run

      err || data

    end # sms_cost

    def balance(usr, pass, api_id)

      r     = auth_params.merge({})
      r     = params_for(r)
      data  = {}
      err   = block_run do |http|

        log("[sms_send] => /my/balance #{r}")

        res = request do
          http.post("/my/balance", r, {})
        end

        log("[sms_send] <= #{r} \n\r#{res.body}")

        data = ::SmsRu::Respond.balance(res)

      end # block_run

      err || data

    end # balance

    def limit(usr, pass, api_id)

      r     = auth_params.merge({})
      r     = params_for(r)
      data  = {}
      err   = block_run do |http|

        log("[sms_send] => /my/limit #{r}")

        res = request do
          http.post("/my/limit", r, {})
        end

        log("[sms_send] <= #{r} \n\r#{res.body}")

        data = ::SmsRu::Respond.limit(res)

      end # block_run

      err || data

    end # limit

    def check(usr, pass, api_id)

      r     = auth_params.merge({})
      r     = params_for(r)
      data  = {}
      err   = block_run do |http|

        log("[sms_send] => /auth/check #{r}")

        res = request do
          http.post("/auth/check", r, {})
        end

        log("[sms_send] <= #{r} \n\r#{res.body}")

        data = ::SmsRu::Respond.check(res)

      end # block_run

      err || data

    end # check

    private

    def params_for(params)

      params.delete_if { |key, v| v.nil? }
      ::URI.encode_www_form(params)

    end # params_for

    def log(msg)

      puts(msg) if ::SmsRu.debug?
      self

    end # log

    def block_run

      error     = nil
      try_count = ::SmsRu::RETRY

      begin

        ::Timeout::timeout(::SmsRu::TIMEOUT) {

          ::Net::HTTP.start(
            ::SmsRu::HOST,
            ::SmsRu::PORT,
            :use_ssl => ::SmsRu::USE_SSL
          ) do |http|
            yield(http)
          end

        }

      rescue ::Errno::ECONNREFUSED

        if try_count > 0
          try_count -= 1
          sleep ::SmsRu::WAIT_TIME
          retry
        else
          error = ::SmsRu::ConnectionError.new("Прервано соедиение с сервером")
        end

      rescue ::Timeout::Error

        if try_count > 0
          try_count -= 1
          sleep ::SmsRu::WAIT_TIME
          retry
        else
          error = ::SmsRu::TimeoutError.new("Превышен интервал ожидания #{::SmsRu::TIMEOUT} сек. после #{::SmsRu::RETRY} попыток")
        end

      rescue => e
        error = ::SmsRu::UnknownError.new(e.message)
      end

      error

    end # block_run

    def request

      try_count = ::SmsRu::RETRY
      headers   = {
        "Content-Type" => "text/html; charset=utf-8"
      }

      res = yield(headers)
      while(try_count > 0 && res.code.to_i >= 300)

        log("[retry] #{try_count}. Wait #{::SmsRu::WAIT_TIME} sec.")

        res = yield(headers)
        try_count -= 1
        sleep ::SmsRu::WAIT_TIME

      end # while

      res

    end # request

  end # Base

end # SmsRu
