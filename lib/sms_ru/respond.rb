# encoding: utf-8
module SmsRu

  module Respond

    extend self

    def get_token(req)
      server_error(req) || req.body
    end # get_token

    def sms_send(req)

      server_error(req) || answer(req.body) { |id_sms, balance, _|

        {
          id_sms:   id_sms,
          balance:  balance.sub(/balance=/, '')
        }

      }

    end # sms_send

    def sms_state(req)

      server_error(req) || answer(req.body) { |_1, _2, code|

        {

          state:    code,
          message:  {

            100 => 'Сообщение находится в нашей очереди',
            101 => 'Сообщение передается оператору',
            102 => 'Сообщение отправлено (в пути)',
            103 => 'Сообщение доставлено',
            104 => 'Не может быть доставлено: время жизни истекло',
            105 => 'Не может быть доставлено: удалено оператором',
            106 => 'Не может быть доставлено: сбой в телефоне',
            107 => 'Не может быть доставлено: неизвестная причина',
            108 => 'Не может быть доставлено: отклонено'


          }[code] || "Неизвестная ошибка"

        }

      }

    end # sms_state

    def sms_cost(req)

      server_error(req) || answer(req.body) { |cost, length|

        {
          cost:   cost,
          length: length
        }

      }

    end # sms_cost

    def balance(req)

      server_error(req) || answer(req.body) { |money, _|

        {
          balance: money
        }

      }

    end # balance

    def limit(req)

      server_error(req) || answer(req.body) { |to_send, sended|

        {
          to_send:  to_send,
          sended:   sended
        }

      }

    end # limit

    def check(req)

      server_error(req) || answer(req.body) { |_|
        true
      }

    end # check

    private

    def server_error(req)

      return nil if [200, 201].include?(req.code.to_i)
      ::SmsRu::RespondError.new("Сервер вернул код: #{req.code}. #{req.body}")

    end # server_error

    def answer(msg)

      code, par1, par2 = msg.split("\n")
      case code

        when "-1" then
          ::SmsRu::RespondError.new("Сообщение не найдено.")

        when "100" then
          return yield(par1, par2, 100)

        when "101" then
          return yield(par1, par2, 101)

        when "102" then
          return yield(par1, par2, 102)

        when "103" then
          return yield(par1, par2, 103)

        when "104" then
          return yield(par1, par2, 104)

        when "105" then
          return yield(par1, par2, 105)

        when "106" then
          return yield(par1, par2, 106)

        when "107" then
          return yield(par1, par2, 107)

        when "108" then
          return yield(par1, par2, 108)

        when "200" then
          ::SmsRu::RespondError.new("Неправильный api_id")

        when "201" then
          ::SmsRu::RespondError.new("Не хватает средств на лицевом счету")

        when "202" then
          ::SmsRu::RespondError.new("Неправильно указан получатель")

        when "203" then
          ::SmsRu::RespondError.new("Нет текста сообщения")

        when "204" then
          ::SmsRu::RespondError.new("Имя отправителя не согласовано с администрацией")

        when "205" then
          ::SmsRu::RespondError.new("Сообщение слишком длинное (превышает 8 СМС)")

        when "206" then
          ::SmsRu::RespondError.new("Будет превышен или уже превышен дневной лимит на отправку сообщений")

        when "207" then
          ::SmsRu::RespondError.new("На этот номер (или один из номеров) нельзя отправлять сообщения, либо указано более 100 номеров в списке получателей")

        when "208" then
          ::SmsRu::RespondError.new("Параметр time указан неправильно")

        when "209" then
          ::SmsRu::RespondError.new("Вы добавили этот номер (или один из номеров) в стоп-лист")

        when "210" then
          ::SmsRu::RespondError.new("Используется GET, где необходимо использовать POST")

        when "211" then
          ::SmsRu::RespondError.new("Метод не найден")

        when "212" then
          ::SmsRu::RespondError.new("Текст сообщения необходимо передать в кодировке UTF-8 (вы передали в другой кодировке)")

        when "220" then
          ::SmsRu::ProviderError.new("Сервис временно недоступен, попробуйте чуть позже.")

        when "230" then
          ::SmsRu::RespondError.new("Сообщение не принято к отправке, так как на один номер в день нельзя отправлять более 60 сообщений.")

        when "300" then
          ::SmsRu::SessionExpiredError.new("Неправильный token (возможно истек срок действия, либо ваш IP изменился)")

        when "301" then
          ::SmsRu::AuthError.new("Неправильный пароль, либо пользователь не найден")

        when "302" then
          ::SmsRu::AuthError.new("Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)")

        else
          ::SmsRu::UnknownError.new("Неизвестная ошибка с кодом #{code}. Ответ сервера: #{msg}")

      end  # case

    end # sms_send_answer

  end # Respond

end # SmsRu
