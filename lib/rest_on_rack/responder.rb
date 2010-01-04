class Rack::REST::Responder
  include Rack::REST::Utils

  attr_reader :response, :request

  def initialize(app, request)
    @app = app
    @request = request
  end

  def recognized_method
    @recognized_method ||= begin
      method = @request.normalized_request_method
      ([:options] + @app.config[:recognized_methods]).find {|m| m.to_s == method} or raise_error(STATUS_NOT_IMPLEMENTED)
    end
  end

  # for use within #response
  def raise_error(status=STATUS_INTERNAL_SERVER_ERROR, message=nil, headers={})
    raise Rack::REST::Error.new(status, message, headers)
  end

  def error_response(status=STATUS_INTERNAL_SERVER_ERROR, message=nil, headers={}, backtrace=nil)
    error_response_from_error(Rack::REST::Error.new(status, message, headers, backtrace))
  end

  def error_response_from_error(error)
    Rack::REST::Responder::Error.new(@app, @request, error).response
  end

  def call
    begin
      response.finish
    rescue Rack::REST::Error => error
      error_response_from_error(error).finish
    rescue => exception
      raise unless @app.config[:catch_application_errors]
      if @app.config[:expose_exception_details]
        error_response(STATUS_INTERNAL_SERVER_ERROR, exception.message, {}, exception.backtrace).finish
      else
        error_response.finish
      end
    end
  end

  def response
    raise NotImplementedError
  end
end