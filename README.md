# TrustedKeys

This gem makes it possible to handlle __mass assignment__ in the controller.  
It adds two methods:
  
 * `#trusted_attributes` - returns the trusted attributes.
 * `.trust` - defines the trusted attributes.

## Why
 * It handles complex hashes. E.g. handles hashes that complies to `accepts_nested_attributes_for`, even when 
nested on several levels, see [spec](https://github.com/unders/trusted_keys/blob/master/spec/trusted_keys_spec.rb#L81) 
for more info.

## Usage
Include it in your application controller:

``` ruby
class ApplicationController < ActionController::Base
  include TrustedKeys
end
```

Define which attributes to trust in the controller:


``` ruby
class EventsController < ApplicationController
  trust :title, :location, :start, :stop, :description, :attendees, :repeat,
        :min_number_of_attendees, :deadline, for: :event
end
```

The above commands reads like this: _trust the following attributes: 'title', ..., 'deadline', 
returned by the params[:event] hash_. 


Inside your action:

``` ruby
def create
  @event = Event.create(trusted_attributes)                             
  respond_with(@event)                  
end
``` 

And it will only return the trusted attributes.


### A nested attributes example:

``` ruby
params = { "event" => 
           { "title" => "A title",
             "location" => "I am not trusted"
             "attendees_attributes" => {
                "0" => {  "_destroy"=>"false",
                          "id" => "2",
                          "dangerous" => "I am evil",
                          "start"=>"2012" },
                "new_1331711737056" => {  "_destroy"=>"false",
                                          "start"=>"2012" } }
           }
         }

class EventsController < ApplicationController
  trust :title, for: :event
  trust :start, for: "event.attendees_attributes"
  
  def create
    @event = Event.create(trusted_attributes)                             
    respond_with(@event)   
  end
end

# trusted_attributes => 
  { "title" => "A title",
    "attendees_attributes" => {
      "0" => {  "_destroy"=>"false",
                "id" => "2",
                "start"=>"2012" },
      "new_1331711737056" => {  "_destroy"=>"false",
                                "start"=>"2012" } 
    }
  }
```

When the hash conforms to the `accepts_nested_attributes_for` structure, the keys:
'_destroy' and 'id' is also trusted on that hash level as the above example shows. 


## Environments

When an attributes isn't trusted in __development__ or __test__ mode an exception is raised with a message
explaning what to do. When other environments (e.g production) the attributes are silently removed.


## Installation

Add this line to your application's Gemfile:

    gem 'trusted_keys'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trusted_keys


## Other mass assignment controller protection gems
* https://github.com/topdan/param_accessible
* https://github.com/ryanb/trusted-params
* https://github.com/elabs/trusted_attributes
* https://github.com/rails/strong_parameters

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
