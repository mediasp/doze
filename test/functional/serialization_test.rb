require 'functional/base'
require 'doze/serialization/resource'

class SerializationTest < Test::Unit::TestCase
  include Doze::Utils
  include Doze::TestCase
  include Doze::MediaTypeTestCase

  def setup
    root.extend(Doze::Serialization::Resource)
    @ruby_data = ['some', 123, 'ruby data']
    super
  end

  def test_parse_error
    root.stubs(:supports_put?).returns(true)
    root.stubs(:accepts_put_with_media_type?).returns(true)
    def root.put(entity)
      # actually try to parse the entity
      entity.object_data
    end

    put('CONTENT_TYPE' => 'application/json', :input => '{"foo":')
    assert_equal STATUS_BAD_REQUEST, last_response.status
    assert_match /parse/i, last_response.body
  end

  def test_semantic_client_error
    root.stubs(:supports_put?).returns(true)
    root.stubs(:accepts_put_with_media_type?).returns(true)

    root.expects(:put).raises(Doze::ClientResourceError, "semantic problem with submitted data").once
    put('CONTENT_TYPE' => 'application/json', :input => '{"foo":"bar"}')
    assert_equal STATUS_UNPROCESSABLE_ENTITY, last_response.status
    assert_match /semantic/i, last_response.body
  end

  def test_json_serialization
    media_type = Doze::Serialization::JSON
    entity = media_type.entity_class.new(media_type, :object_data => {'foo' => 'bar'})
    assert_equal '{"foo":"bar"}', entity.binary_data
  end

  def test_form_encoding_serialization
    media_type = Doze::Serialization::WWW_FORM_ENCODED
    entity = media_type.entity_class.new(media_type, :object_data => {'foo' => {'bar' => '='}, 'baz' => '3'})
    assert ['foo[bar]=%3D&baz=3', 'baz=3&foo[bar]=%3D'].include?(entity.binary_data)
  end

  def test_get_serialized
    root.expects(:get_data).returns(@ruby_data).twice

    get('HTTP_ACCEPT' => 'application/json')
    assert_equal STATUS_OK, last_response.status
    assert_equal @ruby_data.to_json, last_response.body
    assert_equal 'application/json', last_response.media_type

    get('HTTP_ACCEPT' => 'text/html')
    assert_equal STATUS_OK, last_response.status
    assert_equal 'text/html', last_response.media_type
  end

  def test_put_serialized
    root.expects(:supports_put?).returns(true).twice
    root.expects(:put).with {|entity| entity.object_data == @ruby_data}.once

    put('CONTENT_TYPE' => 'application/json', :input => @ruby_data.to_json)
    assert_equal STATUS_NO_CONTENT, last_response.status

    put('CONTENT_TYPE' => 'application/yaml', :input => @ruby_data.to_yaml)
    assert_equal STATUS_UNSUPPORTED_MEDIA_TYPE, last_response.status
  end

  def test_post_serialized
    root.expects(:supports_post?).returns(true).twice
    root.expects(:post).with {|entity| entity.object_data == @ruby_data}.once

    post('CONTENT_TYPE' => 'application/json', :input => @ruby_data.to_json)
    assert_equal STATUS_NO_CONTENT, last_response.status

    # YAML is disabled by default
    post('CONTENT_TYPE' => 'application/yaml', :input => @ruby_data.to_yaml)
    assert_equal STATUS_UNSUPPORTED_MEDIA_TYPE, last_response.status
  end

  def test_form_post
    root.expects(:supports_post?).returns(true).once
    root.expects(:post).with {|entity| entity.object_data == {'abc' => {'def' => 'ghi'}, 'e' => '='}}.once
    post('CONTENT_TYPE' => 'application/x-www-form-urlencoded', :input => "abc%5Bdef%5D=ghi&e=%3D")
    assert_equal STATUS_NO_CONTENT, last_response.status
  end

  def test_derived_type
    json_subtype = Doze::Serialization::JSON.register_derived_type('application/vnd.foo.bar')

    assert_equal "application/vnd.foo.bar+json", json_subtype.name
    assert json_subtype.matches_names.include?("application/json")
  end

  def test_get_derived_type_via_generic_accept
    derived_media_types = [Doze::Serialization::JSON].map {|x| x.register_derived_type('application/vnd.foo.bar')}

    root.expects(:get_data).returns(@ruby_data).once
    root.expects(:serialization_media_types).returns(derived_media_types).once

    get('HTTP_ACCEPT' => 'application/json')
    assert_equal STATUS_OK, last_response.status
    assert_equal @ruby_data.to_json, last_response.body
    assert_equal 'application/vnd.foo.bar+json', last_response.media_type
  end

  def test_put_multipart
    root.expects(:supports_put?).returns(true)
    root.expects(:put).with do |entity|
      entity.object_data["z"] == {"y" => "x"} and
      file = entity.object_data["x"] and
      file.is_a?(Hash) and
      file["filename"] == "test.html" and
      file["media_type"] == "text/html" and
      file["tempfile"].read == "<html>test</html>" and
      File.read(file["temp_path"]) == "<html>test</html>"
    end

    boundary = "----------------------------0ef440f6b22e"
    body = <<END
------------------------------0ef440f6b22e
Content-Disposition: form-data; name="z[y]"

x
------------------------------0ef440f6b22e
Content-Disposition: form-data; name="x"; filename="test.html"
Content-Type: text/html

<html>test</html>
------------------------------0ef440f6b22e--
END
    body = body.gsub(/\r?\n/, "\r\n")

    put('CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}", :input => body)
    assert_equal STATUS_NO_CONTENT, last_response.status
  end
end
