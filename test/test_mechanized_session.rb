require File.dirname(__FILE__) + '/test_helper.rb'
require "pp"

class TestMechanizedSession < Test::Unit::TestCase
  class ExampleEmptyMechanizedSession < MechanizedSession
    action :login do |session, options|
      session.get('https://www.google.com/accounts/ManageAccount?hl=en') do |page|
      end
      if options[:username] == "bad implementation"
        nil
      else
        @username = options[:username]
        @password = options[:password]
        options[:username] == "bad user" ? false : true
      end
    end
    
    action :do_something_requiring_login do |session|
      session.get('https://www.google.com/accounts/ManageAccount?hl=en') do |page|
      end
    end
  end

  def setup
    @logger = Logger.new(StringIO.new)
    @previous_session_data = <<-YAML
--- !ruby/object:WWW::Mechanize::CookieJar
jar:
  google.com:
    /:
      PREF: !ruby/object:WWW::Mechanize::Cookie
        comment:
        comment_url:
        discard:
        domain: google.com
        expires: Mon, 05 Dec 2011 20:13:27 GMT
        max_age:
        name: PREF
        path: /
        port:
        secure: false
        value: ID=81b036b3879502d3:TM=1260044007:LM=1260044007:S=gTZE41MSHOrSwy5S
        version: 0
      NID: !ruby/object:WWW::Mechanize::Cookie
        comment:
        comment_url:
        discard:
        domain: google.com
        expires: Sun, 06 Jun 2010 20:13:27 GMT
        max_age:
        name: NID
        path: /
        port:
        secure: false
        value: 29=W6XhKG_4rDv709QX6oDGzHQ5y17pISryKo75MZuWOZ59HNZm011Htlk_TYKIdXEwau_4GK3jIjFHALrbDFjoJ7Pz-zmOc5evFZAp71Og7itAVYPDQukb8Z7DwBB9qLzt
        version: 0
    YAML
  end

  def test_initialize_with_previous_session__sets_cookies
    session = MechanizedSession.new(:session_data => @previous_session_data, :logger =>@logger)
    google_cookies = session.agent.cookie_jar.cookies(URI.parse("http://google.com/"))
    assert_equal 2, google_cookies.length
  end

  def test_initialize_with_username__calls_login
    session = ExampleEmptyMechanizedSession.new(:username => "david", :password => "ponies", :logger => @logger)
    assert session.logged_in
  end

  def test_initialize_with_username__calls_login__raises_exception_if_returns_false
    assert_raises(MechanizedSession::InvalidAuthentication) do
      ExampleEmptyMechanizedSession.new(:username => "bad user", :password => "noponies", :logger => @logger)
    end
  end

  def test_initialize_with_username__calls_login__raises_exception_if_returns_non_true
    assert_raises(RuntimeError) do
      ExampleEmptyMechanizedSession.new(:username => "bad implementation", :password => "noponies", :logger => @logger)
    end
  end

  def test_check_for_invalid_session__raises_error_when_doing_something_that_requires_login
    session = ExampleEmptyMechanizedSession.new(:logger => @logger)
    assert_raises(MechanizedSession::InvalidSession) {
      session.do_something_requiring_login
    }
  end
end
