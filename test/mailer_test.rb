require 'test_helper'

class MailerTest < Test::Unit::TestCase
  TEXT_POSTSCRIPT_PHRASE = /The original recipients were:/
  HTML_POSTSCRIPT_PHRASE = /<p>\s+The original recipients were:\s+<\/p>/

  context 'Delivering a plain text email to internal addresses' do
    setup do
      MailSafe::Config.stubs(:is_internal_address? => true)
      @email = TestMailer.deliver_plain_text_message(:to => 'internal-to@address.com', :bcc => 'internal-bcc@address.com', :cc => 'internal-cc@address.com')
    end

    should 'send the email to the original addresses' do
      assert_equal ['internal-to@address.com'], @email.to
      assert_equal ['internal-cc@address.com'], @email.cc
      assert_equal ['internal-bcc@address.com'], @email.bcc
    end

    should 'not add a post script to the body' do
      assert_no_match TEXT_POSTSCRIPT_PHRASE, @email.body
    end
  end

  context 'Delivering a plain text email to external addresses' do
    setup do
      MailSafe::Config.stubs(:is_internal_address? => false, :get_replacement_address => 'replacement@example.com')
      @email = TestMailer.deliver_plain_text_message(:to => 'internal-to@address.com', :bcc => 'internal-bcc@address.com', :cc => 'internal-cc@address.com')
    end

    should 'send the email to the replacement address' do
      assert_equal ['replacement@example.com'], @email.to
      assert_equal ['replacement@example.com'], @email.cc
      assert_equal ['replacement@example.com'], @email.bcc
    end
  end

  def deliver_email_with_mix_of_internal_and_external_addresses(delivery_method)
    MailSafe::Config.internal_address_definition = /internal/
    MailSafe::Config.replacement_address = 'internal@domain.com'
    @email = TestMailer.send(delivery_method,
      {
        :to  => ['internal1@address.com', 'external1@address.com'],
        :cc  => ['internal1@address.com', 'internal2@address.com'],
        :bcc => ['external1@address.com', 'external2@address.com']
      }
    )
  end

  context 'Delivering a plain text email to a mix of internal and external addresses' do
    setup do
      deliver_email_with_mix_of_internal_and_external_addresses(:deliver_plain_text_message)
    end

    should 'send the email to the appropriate address' do
      assert_same_elements ['internal1@address.com', 'internal@domain.com'],   @email.to
      assert_same_elements ['internal1@address.com', 'internal2@address.com'], @email.cc
      assert_same_elements ['internal@domain.com',   'internal@domain.com'],   @email.bcc
    end

    should 'add a plain text post script to the body' do
      assert_match TEXT_POSTSCRIPT_PHRASE, @email.body
    end
  end

  context 'Delivering an html email to a mix of internal and external addresses' do
    setup do
      deliver_email_with_mix_of_internal_and_external_addresses(:deliver_html_message)
    end

    should 'add an html post script to the body' do
      assert_match HTML_POSTSCRIPT_PHRASE, @email.body
    end
  end

  context 'Delivering a multipart email to a mix of internal and external addresses' do
    setup do
      deliver_email_with_mix_of_internal_and_external_addresses(:deliver_multipart_message)
    end

    should 'add an text post script to the body of the text part' do
      assert_match TEXT_POSTSCRIPT_PHRASE, @email.parts.detect { |p| p.content_type == 'text/plain' }.body
    end

    should 'add an html post script to the body of the html part' do
      assert_match HTML_POSTSCRIPT_PHRASE, @email.parts.detect { |p| p.content_type == 'text/html' }.body
    end
  end
end
