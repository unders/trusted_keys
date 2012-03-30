# TrustedKeys

This gem makes it possible to handlle __mass assignment__ in the controller.  
It adds two methods:
  
 * `trusted_attributes` - returns the trusted attributes.
 * `trust` - defines the trusted attributes.

## Example


This module adds the private instance method: `trusted_attributes` to the controller, which only returns 
trusted attributes specified in the controller by the class controller method: `trust`. 

## Installation

Add this line to your application's Gemfile:

    gem 'trusted_keys'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trusted_keys

## Usage

TODO: Write usage instructions here

## Other mass assignment protection gems for in controller
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
