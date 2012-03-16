# encoding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "../../lib"
require 'trusted_keys'

# An exception is raised if untrusted keys are submitted when Rails.env
# equals 'development' or 'test'. When Rail.env is something else, it will
# silently remove the untrusted keys.
Rails.env = "development"
Rails.env = "test"

#Rails.env = "other"

module Trusted
  extend ActiveSupport::Concern
  include TrustedKeys
  extend self

  def params
    { "utf8"=>"✓", "authenticity_token"=>"zIE/nwLd",
      "event"=> { "title"=>"",
                  "location"=>"not trusted",
                  "start(1i)"=>"2012", "start(2i)"=>"3", "start(3i)"=>"5",
                  "description"=>"",
                  "attendees"=>"",
                  "slug_attributes" => {  "slug" => "dddd",
                                          "dangerous" => "not trusted" },
                  "comment_attributes" => { "body" => "I am body",
                                            "evil" => "not trusted",
                                            "slug3_attributes" => { "slug3" => "is cool",
                                                                    "cruel" => "not trusted" } } } }
  end

  def puts
    p trusted_attributes
  end
end

puts "params => "
p Trusted.params

class ApplicationController
  include Trusted
end

#ApplicationController.new.trusted_attributes # raises NoMethodError
#ApplicationController.new.puts #  raises UsageError

class ApplicationController
  trust :utf8
end
ApplicationController.new.puts # {"utf8"=>"✓" }

class ApplicationControllerX
  include Trusted
  trust :event, :utf8
end
Rails.env = "fff"
ApplicationControllerX.new.puts # {"utf8"=>"✓"  "event" => "" }

# raises TrustedKeys::NotTrustedError if test och development environment.
#Rails.env = "test"
ApplicationControllerX.new.puts


#Rails.env = "test"
class ApplicationController2
  include Trusted
  trust :title, :start, :description, :attendees, :slug_attributes, for: :event
end
ApplicationController2.new.puts
# =>
# { "title"=>"", "start(1i)"=>"2012", "start(2i)"=>"3", "start(3i)"=>"5",
# "description"=>"", "attendees"=>"", "slug_attributes"=>""}

#Rails.env = "test"
class ApplicationController3
  include Trusted
  trust :title, :start, :description, :attendees, :slug_attributes,
        :location, :comment_attributes, for: :event
  trust :slug, for: "event.slug_attributes"
end
ApplicationController3.new.puts
# =>
# { "title"=>"", "start(1i)"=>"2012", "start(2i)"=>"3", "start(3i)"=>"5",
#   "description"=>"", "attendees"=>"",
#   "slug_attributes"=>{ "slug"=>"dddd"}}

#Rails.env = "development"
class ApplicationController4
  include Trusted
  trust :title, :start, :description, :attendees, :slug_attributes,
        :comment_attributes, :location, for: :event
  trust :slug, for: "event.slug_attributes"
  trust "body", :slug3_attributes, for: "event.comment_attributes"
end
ApplicationController4.new.puts
# =>
# { "title"=>"", "start(1i)"=>"2012", "start(2i)"=>"3", "start(3i)"=>"5",
#   "description"=>"", "attendees"=>"", "location" => "not trusted"
#   "slug_attributes"=>{"slug"=>"dddd"},
#   "comment_attributes"=>{ "body"=>"I am body",
#                           "slug3_attributes"=>""}}
#

#Rails.env = "test"
class ApplicationController5
  include Trusted
  trust :title, :start, :description, :attendees, :slug_attributes,
        :comment_attributes, for: :event
  trust :slug, for: "event.slug_attributes"
  trust "body", :slug3_attributes, for: "event.comment_attributes"
  trust "slug3", for: "event.comment_attributes.slug3_attributes"
end
ApplicationController5.new.puts
# =>
# { "title"=>"", "start(1i)"=>"2012", "start(2i)"=>"3", "start(3i)"=>"5",
#   "description"=>"", "attendees"=>"",
#   "slug_attributes"=>{"slug"=>"dddd"},
#   "comment_attributes"=>{ "body"=>"I am body",
#                           "slug3_attributes"=>{"slug3"=>"is cool"}}}
