class Rack::REST::Responder::Error < Rack::REST::Responder

  def initialize(app, request, error)
    super(app, request)
    @error = error
  end

  # We use a resource class to represent for errors to enable content type negotiation for them.
  # The class used is configurable but defaults to Rack::REST::Resource::Error
  def response
    response = Rack::REST::Response.new
    if @app.config[:error_resource_class]
      extras = if @app.config[:expose_exception_details] && @error.http_status >= 500
        {:backtrace => @error.backtrace}
      else
        {}
      end
      resource = @app.config[:error_resource_class].new(@error.http_status, @error.message, extras)
      # we can't have it going STATUS_NOT_ACCEPTABLE in the middle of trying to return an error resource, so :ignore_unacceptable_accepts
      responder = Rack::REST::Responder::Resource.new(@app, @request, resource, :ignore_unacceptable_accepts => true)
      entity = responder.get_preferred_representation(response)
      response.entity = entity
    else
      response.headers['Content-Type'] = 'text/plain'
      response.body = @error.message
    end

    response.head_only = true if @request.head?
    response.status = @error.http_status
    response.headers.merge!(@error.headers) if @error.headers
    response
  end
end
