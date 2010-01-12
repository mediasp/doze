require 'functional/base'

class NonGetMethodTest < Test::Unit::TestCase
  include Rack::REST::Utils
  include Rack::REST::TestCase
  include Rack::REST::MediaTypeTestCase

  def setup
    super
    @foo = Rack::REST::MediaType.new('text/foo')
    @bar = Rack::REST::MediaType.new('text/bar')
  end

  def test_put_with_unacceptable_media_type
    root.expects(:supports_put?).returns(true)
    root.expects(:accepts_put_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(false)
    root.expects(:put).never
    put('CONTENT_TYPE' => 'text/foo', :input => 'foo')
    assert_equal STATUS_UNSUPPORTED_MEDIA_TYPE, last_response.status
  end

  def test_put
    root.expects(:supports_put?).returns(true)
    root.expects(:accepts_put_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    root.expects(:put).with do |value|
      value.is_a?(Rack::REST::Entity) and
      value.binary_data == 'foo' and value.media_type == @foo and value.encoding == 'foobar'
    end.returns(nil).once

    put('CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foo')
    assert_equal STATUS_NO_CONTENT, last_response.status
  end

  def test_put_where_not_exists
    root.expects(:exists?).returns(false)
    root.expects(:supports_put?).returns(true)
    root.expects(:accepts_put_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    root.expects(:put).returns(nil).once

    put('CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foo')
    assert_equal STATUS_CREATED, last_response.status
  end

  def test_post_with_unacceptable_media_type
    root.expects(:supports_post?).returns(true)
    root.expects(:accepts_post_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(false)
    root.expects(:post).never
    post('CONTENT_TYPE' => 'text/foo', :input => 'foo')
    assert_equal STATUS_UNSUPPORTED_MEDIA_TYPE, last_response.status
  end

  def test_post_returning_created_resource
    root.expects(:supports_post?).returns(true)
    root.expects(:accepts_post_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    created = mock_resource('/uri')
    root.expects(:post).with do |value|
      value.is_a?(Rack::REST::Entity) and
      value.binary_data == 'foob' and value.media_type == @foo and value.encoding == 'foobar'
    end.returns(created).once

    post('CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob')
    assert_equal STATUS_CREATED, last_response.status
    assert_response_header 'Location', 'http://example.org/uri'
  end

  def test_post_returning_nothing
    root.expects(:supports_post?).returns(true)
    root.expects(:accepts_post_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    root.expects(:post).returns(nil).once

    post('CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob')
    assert_equal STATUS_NO_CONTENT, last_response.status
  end

  def test_post_returning_entity
    root.expects(:supports_post?).returns(true)
    root.expects(:accepts_post_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    root.expects(:post).returns(mock_entity('bar', @bar)).once

    post('CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob')
    assert_equal STATUS_OK, last_response.status
    assert_equal 'bar', last_response.body
    assert_equal 'text/bar', last_response.media_type
  end

  def test_post_returning_anonymous_resource
    root.expects(:supports_post?).returns(true)
    root.expects(:accepts_post_with_media_type?).with {|a| a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    resource = mock_resource(nil)
    resource.expects(:get).returns(mock_entity('bar', @bar))
    root.expects(:post).returns(resource).once

    post('CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob')
    assert_equal STATUS_OK, last_response.status
    assert_equal 'bar', last_response.body
    assert_equal 'text/bar', last_response.media_type
  end

  def test_delete
    root.expects(:supports_delete?).returns(true)
    root.expects(:accepts_delete_with_media_type?).never
    root.expects(:delete).returns(nil).once

    delete
    assert_equal STATUS_NO_CONTENT, last_response.status
    assert last_response.body.empty?
  end

  def test_other_method_with_no_response
    # PATCH used as an example here
    app(:recognized_methods => [:get,:post,:put,:delete,:patch])

    root.expects(:supports_patch?).returns(true)
    root.expects(:accepts_method_with_media_type?).with {|m,a| m == :patch && a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    root.expects(:patch).with do |value|
      value.is_a?(Rack::REST::Entity) and
      value.binary_data == 'foob' and value.media_type == @foo and value.encoding == 'foobar'
    end.returns(nil).once

    other_request_method('PATCH', {'CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob'})
    assert_equal STATUS_NO_CONTENT, last_response.status
  end

  def test_other_method_with_anonymous_resource_response
    # PATCH used as an example here
    app(:recognized_methods => [:get,:post,:put,:delete,:patch])

    root.expects(:supports_patch?).returns(true)
    root.expects(:accepts_method_with_media_type?).with {|m,a| m == :patch && a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    resource = mock_resource(nil)
    resource.expects(:get).returns(mock_entity('bar', @bar))
    root.expects(:patch).returns(resource).once

    other_request_method('PATCH', {'CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob'})
    assert_equal STATUS_OK, last_response.status
    assert_equal 'bar', last_response.body
    assert_equal 'text/bar', last_response.media_type
  end

  def test_other_method_with_resource_response
    # PATCH used as an example here
    app(:recognized_methods => [:get,:post,:put,:delete,:patch])

    root.expects(:supports_patch?).returns(true)
    root.expects(:accepts_method_with_media_type?).with {|m,a| m == :patch && a.is_a?(Rack::REST::Entity) && a.media_type == @foo}.returns(true)
    resource = mock_resource('/foo')
    resource.expects(:get).never
    root.expects(:patch).returns(resource).once

    other_request_method('PATCH', {'CONTENT_TYPE' => 'text/foo; charset=foobar', :input => 'foob'})
    assert_equal STATUS_SEE_OTHER, last_response.status
    assert_response_header 'Location', 'http://example.org/foo'
    assert last_response.body.empty?
  end
end
