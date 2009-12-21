require 'functional/base'

class RouterInterfaceTest < Test::Unit::TestCase
  include Rack::REST::Utils
  include Rack::REST::TestCase

  # tests how the basic Router interface is exposed by the framework

  def test_router_no_match
    root_router.expects(:route).with('/foo', :get, '').returns(nil).once
    assert_equal STATUS_NOT_FOUND, get('/foo').status
  end

  def test_router_match_resource_with_no_trailing_path
    resource = mock_resource('/foo')
    root_router.expects(:route).with('/foo', :get, '').returns([resource, '/foo', nil]).once
    resource.expects(:get).returns(mock_entity('foo', 'text/html')).once
    assert_equal STATUS_OK, get('/foo').status
  end

  def test_router_match_resource_but_with_trailing
    # here we route to a resource, but there is some trailing path which can't be routed any further
    resource = mock_resource('/foo')
    root_router.expects(:route).with('/foo/bar', :get, '').returns([resource, '/foo', '/bar']).once
    resource.expects(:get).never
    assert_equal STATUS_NOT_FOUND, get('/foo/bar').status
  end

  def test_router_match_router_with_trailing_then_resource
    # here we route to another router which is matched but with some trailing path that's passed on to it.

    second_router = mock_router
    resource = mock_resource('/foo/bar')

    root_router.expects(:route).with('/foo/bar', :get, '').returns([second_router, '/foo', '/bar']).once
    second_router.expects(:route).with('/bar', :get, '/foo').returns([resource, '/foo/bar', nil]).once

    resource.expects(:get).returns(mock_entity('foo', 'text/html')).once
    assert_equal STATUS_OK, get('/foo/bar').status
  end

  def test_router_match_router_resource_with_trailing_then_resource
    # as above but this time our second router is also a resource - check that it does actually act as a router

    second_router = mock_router(Rack::REST::MockResource)
    resource = mock_resource('/foo/bar')

    root_router.expects(:route).with('/foo/bar', :get, '').returns([second_router, '/foo', '/bar']).once
    second_router.expects(:route).with('/bar', :get, '/foo').returns([resource, '/foo/bar', nil]).once

    second_router.expects(:get).never
    resource.expects(:get).returns(mock_entity('foo', 'text/html')).once
    assert_equal STATUS_OK, get('/foo/bar').status
  end

  def test_router_match_router_resource_with_no_trailing
    resource = mock_router(Rack::REST::MockResource)

    root_router.expects(:route).with('/foo', :get, '').returns([resource, '/foo', nil]).once
    resource.expects(:route).never
    resource.expects(:get).returns(mock_entity('foo', 'text/html')).once

    assert_equal STATUS_OK, get('/foo').status
  end

  def test_root_router_with_script_name
    root_router.expects(:route).with('/boz', :get, '/foo%20bar/baz').once
    get('/boz', 'SCRIPT_NAME' => '/foo%20bar/baz')
  end

  def test_root_resource_with_script_name
    class << root; attr_writer :uri; end
    root.expects(:uri=).with("/foo%20bar/baz")
    root.expects(:route).never
    get('/', 'SCRIPT_NAME' => '/foo%20bar/baz')
  end

  def test_root_router_with_script_name
    root_router.expects(:route).with('/boz', :get, '/foo%20bar/baz').once
    get('/boz', 'SCRIPT_NAME' => '/foo%20bar/baz')
  end

  def test_root_resource_with_script_name
    class << root; attr_writer :uri; end
    root.expects(:uri=).with("/foo%20bar/baz")
    root.expects(:route).never
    get('/', 'SCRIPT_NAME' => '/foo%20bar/baz')
  end
end


class RouterDefaultImplementationTest < Test::Unit::TestCase
  include Rack::REST::Utils
  include Rack::REST::TestCase

  # tests the default implementation of Router based on routes defined in class method helpers

  def test_route_fixed_uri_to_resource_class
    klass = Class.new

    root_router do
      route '/foo', :to => klass
    end

    resource = mock_resource('/foo')
    resource.expects(:get).returns(mock_entity('foo', 'text/html')).once

    klass.expects(:new).with("/foo").returns(resource)

    assert_equal STATUS_OK, get('/foo').status
  end

  def test_route_with_params_to_block_returning_resource
    root_router do
      route('/foo/{x}/{y}') do |uri, params|
        Rack::REST::MockResource.new(uri, [uri, params].inspect)
      end
    end

    get('/foo/abc/123')

    assert_equal STATUS_OK, last_response.status
    assert_equal(['/foo/abc/123', {:x => 'abc', :y => '123'}].inspect, last_response.body)
  end

  # More complex two-level routing scenario with params at both levels
  def test_route_with_params_to_block_returning_router_routing_to_resource_with_more_params
    root_router do
      route('/foo/{x}') do |uri1, params1|

        Class.new do
          include Rack::REST::Router
          route("/{y}") do |uri2, params2|
            Rack::REST::MockResource.new(uri2, [uri1, params1, uri2, params2].inspect)
          end
        end.new
      end
    end

    get('/foo/abc/123')

    assert_equal STATUS_OK, last_response.status
    # bit of a messy way to test it but this was getting fiddly to mock nicely
    # expecting [uri1, params1, uri2, params2].inspect  from above
    assert_equal(['/foo/abc', {:x => 'abc'}, '/foo/abc/123', {:y => '123'}].inspect, last_response.body)
  end

  def test_route_with_special_param_regexp
    root_router do
      route('/foo/{x}', :regexps => {:x => /\d+/}) do |uri, params|
        Rack::REST::MockResource.new(uri, params[:x])
      end
    end

    assert_equal STATUS_NOT_FOUND, get('/foo/abc').status
    assert_equal STATUS_OK, get('/foo/123').status
    assert_equal "123", last_response.body
  end

  def test_route_with_uri_template_passed_directly
    root_router do
      route(Rack::REST::URITemplate.new('/foo/{x}', :x => /\d+/)) do |uri, params|
        Rack::REST::MockResource.new(uri, params[:x])
      end
    end

    assert_equal STATUS_NOT_FOUND, get('/foo/abc').status
    assert_equal STATUS_OK, get('/foo/123').status
    assert_equal "123", last_response.body
  end
end
