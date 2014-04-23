# Various stateless utility functions which aid the conversion back and forth
# between HTTP syntax and the more abstracted ruby representations we use.
module Doze::Utils
  Rack::Utils::HTTP_STATUS_CODES.reject { |_, text| text == 'Unassigned' }.
    each do |code, text|
      const_set('STATUS_' << text.upcase.gsub(/[^A-Z]+/, '_'), code)
    end

  URI_SCHEMES = Hash.new(URI::Generic).merge!(
    'http' => URI::HTTP,
    'https' => URI::HTTPS
  )

  def request_base_uri(request)
    URI_SCHEMES[request.scheme].build(
      :scheme => request.scheme,
      :port => request.port,
      :host => request.host
    )
  end

  def quote(str)
    '"' << str.gsub(/[\\\"]/o, "\\\1") << '"'
  end

  # Note: unescape and escape proved bottlenecks in URI template matching and
  # URI template generation which in turn were bottlenecks for serving some
  # simple requests and for generating URIs to use for cache lookups.  So
  # perhaps a bit micro-optimised here, but there was a reason :)

  # Rack::Utils.unescape, but without turning '+' into ' '
  # Also must be passed a string.
  def unescape(s)
    s.gsub(/((?:%[0-9a-fA-F]{2})+)/n) { [$1.delete('%')].pack('H*') }
  end

  # Rack::Utils.escape, but turning ' ' into '%20' rather than '+' (which is
  # not a necessary part of the URI spec) to save an extra call to tr.  Also
  # must be passed a string.  Also avoids an extra call to 1.8/1.9
  # compatibility wrapper for bytesize/size.
  if ''.respond_to?(:bytesize)
    def escape(s)
      s.gsub(/([^a-zA-Z0-9_.-]+)/n) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end
  else
    def escape(s)
      s.gsub(/([^a-zA-Z0-9_.-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end
    end
  end

  # So utility functions are accessible as Doze::Utils.foo as well as via
  # including the module
  extend self
end
