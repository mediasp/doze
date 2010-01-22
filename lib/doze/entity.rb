require 'digest/md5'

# A simple wrapper class for an entity, which is essentially a lump of binary data
# together with some metadata about it, most importantly a MediaType, but also
# potentially a character encoding and a content language.
#
# A key feature is that the binary data may be specified lazily via a block.
# This is so that content negotiation can demand the data only once it's decided
# which (if any) of many proferred entities it wants to respond with.
#
# TODO: handle character encodings here in a nicer 1.9-compatible way
# TODO: maybe allow a stream for lazy_binary_data too
class Doze::Entity
  DEFAULT_TEXT_ENCODING = 'iso-8859-1'

  attr_reader :binary_data, :media_type, :encoding, :language

  class << self; alias :new_from_binary_data :new; end

  def initialize(media_type, binary_data=nil, options={}, &lazy_binary_data)
    @binary_data = binary_data
    @lazy_binary_data = lazy_binary_data

    @media_type = media_type
    @encoding   = options[:encoding] || (DEFAULT_TEXT_ENCODING if @media_type.major == 'text')
    @language   = options[:language]
  end

  def binary_data
    @binary_data ||= if @lazy_binary_data
      @lazy_binary_data.call
    else
      raise "must specify either binary_data or lazy_binary_data"
    end
  end

  # This is a 'strong' etag in that it's sensitive to the exact bytes of the entity.
  # Note that etags are per-entity, not per-resource. (even weak etags, which we don't yet support;
  # 'weak' appears to refer to time-based equivalence for the same entity, rather than equivalence of all entity representations of a resource.)
  #
  #  May return nil. Default implementation is an MD5 digest of the entity data.
  def etag
    Digest::MD5.hexdigest(binary_data)
  end
end