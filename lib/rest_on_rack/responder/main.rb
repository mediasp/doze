class Rack::REST::Responder::Main < Rack::REST::Responder

  def response
    resource = route_request
    if resource
      Rack::REST::Responder::Resource.new(@app, @request, resource).response
    elsif recognized_method == :options
      Rack::REST::Response.new(STATUS_OK, 'Allow' => 'OPTIONS')
    else
      error_response(STATUS_NOT_FOUND)
    end
  end

  def route_request
    route_to = @app.root
    path = @request.path_info
    method = recognized_method

    if path == '/' && route_to.is_a?(Rack::REST::Resource)
      route_to.uri = @request.script_name || '/' if route_to.respond_to?(:uri=)
      return route_to
    end

    base_uri = @request.script_name || ''
    remaining_path = path

    while true
      if remaining_path && route_to.is_a?(Rack::REST::Router)
        route_to, base_uri, remaining_path = route_to.route(remaining_path, method, base_uri)
      elsif !remaining_path && route_to.is_a?(Rack::REST::Resource)
        return route_to
      else
        return
      end
    end
  end
end
