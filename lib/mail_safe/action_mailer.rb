module MailSafe
  module ActionMailer
    def self.included(base)
      base.class_eval do
        alias_method_chain :deliver_mimi_mail, :mail_safe
      end
    end

    def deliver_mimi_mail_with_mail_safe!(mail = @mail)
      MailSafe::AddressReplacer.replace_external_addresses(mail) if mail
      deliver_mimi_mail_without_mail_safe!(mail)
    end
  end
end