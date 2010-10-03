$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "rubygems"
gem "mechanize"
require "mechanize"
require "logger"

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

  VERSION = '0.1.0'
  attr_accessor :agent
  attr_accessor :disable_session_check
  attr_accessor :logger
  attr_reader :logged_in

  def self.action(name, &block)
    define_method name do |*args|
      result = nil
      logger.debug "Executing action :#{name}"
      begin
        self.disable_session_check = true if name == :login
        result = block.call(self, *args)
        check_for_invalid_session! unless name == :login
      rescue StandardError => e
        logger.debug "Exception #{e} (#{e.class}) raised in action :#{name}"
        if e.is_a?(MechanizedSession::Error) || e.is_a?(WWW::Mechanize::ResponseCodeError) && e.response_code.to_s == "401"
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
    @logger = options[:logger] || Logger.new($stdout)
    if options[:session_data]
      logger.debug "Initializing session from previous data"
      self.agent.cookie_jar = YAML.load(options[:session_data])
    elsif options[:username]
      result = self.login(options)
      if result == false
        logger.debug "Login returned false, due to invalid credentials we hope"
        raise InvalidAuthentication
      elsif result == true
        logger.debug "Login returned true, assuming session established"
        @logged_in = true
      else
        raise "the :login method of #{self.class} must return exactly true or false (depending on the success of the login)"
      end
    end
  end

  def get(uri, &block)
    logger.debug "GET #{uri}"
    page = agent.get(uri)
    logger.debug "Successfully got page #{page.uri}"
    check_for_invalid_session! unless disable_session_check?
    yield page if block_given?
    page
  end

  def post(uri, params = {}, &block)
    logger.debug "POST #{uri} #{params.inspect}"
    page = agent.post(uri, params)
    logger.debug "Successfully got page #{page.uri}"
    check_for_invalid_session! unless disable_session_check?
    yield page if block_given?
    page
  end

  def put(uri, entity, &block)
    logger.debug "PUT #{uri} #{entity.inspect}"
    page = agent.put(uri, entity)
    logger.debug "Successfully got page #{page.uri}"
    check_for_invalid_session! unless disable_session_check?
    yield page if block_given?
    page
  end

  def delete(uri, params = {}, &block)
    logger.debug "DELETE #{uri} #{params.inspect}"
    page = agent.delete(uri, params)
    logger.debug "Successfully got page #{page.uri}"
    check_for_invalid_session! unless disable_session_check?
    yield page if block_given?
    page
  end

  def login(username, password)
    raise "#{self.class} must declare action :login describing how to log in a session"
  end

  def session_data
    agent.cookie_jar.to_yaml
  end

  def basic_auth
    nil
  end

  private
  def disable_session_check?
    @disable_session_check
  end

  def check_for_invalid_session!
    if agent.current_page && self.class.requires_login?(agent.current_page)
      logger.info "MechanizedSession is no longer valid"
      raise InvalidSession
    end
  end

  def self.requires_login?(page)
    page.uri.path.downcase.include?("login")
  end

  def create_agent
    self.agent = Mechanize.new
    self.agent.log = logger
    if auth = basic_auth
      self.agent.auth(*auth)
    end
  end
end
