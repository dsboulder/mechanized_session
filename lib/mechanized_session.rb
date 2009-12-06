$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "rubygems"
gem "mechanize"
require "mechanize"

class MechanizedSession
  class Error < StandardError
  end

  class InvalidAuthentication < MechanizedSession::Error
  end

  class InvalidSession < MechanizedSession::Error
  end

  class MechanizeError < MechanizedSession::Error
    attr_accessor :inner
  end

  VERSION = '0.0.1'
  attr_accessor :agent
  attr_accessor :disable_session_check
  attr_reader :logged_in

  def self.action(name, &block)
    define_method name do |*args|
      result = nil
      begin
        self.disable_session_check = true if name == :login
        result = block.call(self, *args)
        check_for_invalid_session! unless name == :login
      rescue StandardError => e
        if e.is_a?(MechanizedSession::Error)
          raise e
        else
          ex = MechanizeError.new("Unable to execute action :#{name}, due to '#{e}'")
          ex.inner = e
          ex.set_backtrace(e.backtrace)
          raise ex
        end
      ensure
        self.disable_session_check = nil
      end
      result
    end
  end

  def initialize(options)
    create_agent
    if options[:session_data]
      self.agent.cookie_jar = YAML.load(options[:session_data])
    elsif options[:username]
      result = self.login(options)
      if result == false
        raise InvalidAuthentication
      elsif result == true
        @logged_in = true
      else
        raise "the :login method of #{self.class} must return exactly true or false (depending on the success of the login)"
      end
    end
  end

  def get(uri, &block)
    page = agent.get(uri)
    check_for_invalid_session! unless disable_session_check?
    yield page if block_given?
    page
  end

  private
  def disable_session_check?
    @disable_session_check
  end

  def check_for_invalid_session!
    raise InvalidSession if agent.current_page && self.class.requires_login?(agent.current_page)
  end

  def login(username, password)
    raise "#{self.class} must declare action :login describing how to log in a session"
  end

  def self.requires_login?(page)
    page.uri.path.downcase.include?("login")
  end

  def create_agent
    self.agent = WWW::Mechanize.new
  end
end