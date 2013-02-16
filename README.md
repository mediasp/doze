# Doze

RESTful resource-oriented API framework.

 * Hierarchical routing
 * RESTful concepts are baked in to the library, not as an afterthought
 * Content-Type negotiation
 * Simple, extendable authentication

# Hello, world

``` ruby

require 'doze'

class HelloWorld
  include Doze::Resource
  include Doze::Serialization::Resource

  def get_data
    {:message => 'Hello, World'}
  end
end

run Doze::Application.new(HelloWorld.new)

```

Take a look at example/example_app.rb for a more complex version
