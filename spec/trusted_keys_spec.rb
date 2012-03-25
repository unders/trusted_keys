require 'minitest_helper'

describe TrustedKeys do
  let(:controller) do
    Class.new do
      include TrustedKeys

      def params
        { "email" => "anders@email.com",
          :time => { "start_time(1i)"=>"2012",
                     "start_time(2i)"=>"3",
                     "start_time(3i)"=>"14" },
          :event => {
            :nested_attributes => {
              "0" => {  "_destroy"=>"false",
                        "start"=>"2012" },
              "new_1331711737056" => {  "_destroy"=>"false",
                                        "start"=>"2012" } } },
          "survey"=> {
            "name"=>"survery 1",
            "questions_attributes"=>
              { "0"=>{"_destroy"=>"1",
                      "content"=>"question2",
                      "dddd" => "xxxx",
                      "id"  => "1",
                      "answers_attributes"=>{
                        "0"=>{"content"=>"answer1","_destroy"=>"","dd" => "x"},
                        "1"=>{"content"=>"answer 2","_destroy"=>"1","id"=>"2"}
                       }},
                "1"=>{"_destroy"=>"1",
                      "content"=>"",
                      "answers_attributes"=>{
                        "1"=>{"content"=>"", "_destroy"=>""}}}}},

          :controller => "events",
          :password => "secret",
          :post =>  {  :body => "I am a body",
                       :title => "This is my title",
                       :comments =>  { 'body' => 'My body',
                                       :email => "an email",
                                       :author => { :name => "anders" } } } }
      end
    end
  end

  let(:env) { OpenStruct.new(:test? => false, :development? => false) }

  describe ".trust" do
    describe "datetime selects" do
      it "return all datetime attributes" do
        controller.trust :start_time, :for => :time, :env => env
        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = {  "start_time(1i)"=>"2012",
                      "start_time(2i)"=>"3",
                      "start_time(3i)"=>"14" }
        trusted_attributes.must_equal(expected)
      end
    end

    context "nested attributes" do
      it "returns nested hash" do
        controller.trust :questions_attributes, :name, :for => :survey,
                                                       :env => env
        controller.trust "answers_attributes", "content",
                         :for => 'survey.questions_attributes', :env => env

        controller.trust "content",
          :for => 'survey.questions_attributes.answers_attributes', :env => env

        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = {
          "name"=>"survery 1",
          "questions_attributes"=>
            { "0"=>{"_destroy"=>"1",
                    "content"=>"question2",
                    "id"  => "1",
                    "answers_attributes"=>{
                    "0"=>{"content"=>"answer1", "_destroy"=>""},
                    "1"=>{"content"=>"answer 2", "_destroy"=>"1", "id"=>"2"}}},
            "1"=>{"_destroy"=>"1",
                  "content"=>"",
                  "answers_attributes"=>{
                    "1"=>{"content"=>"", "_destroy"=>""}}}}}

        trusted_attributes.must_equal(expected)
      end

      it "returns nested hash" do
        controller.trust :nested_attributes, :for => :event, :env => env
        controller.trust "start", :for => 'event.nested_attributes', :env => env

        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = { "nested_attributes" => {
                        "0" =>  {  "_destroy"=>"false",
                                   "start"=>"2012" },
                        "new_1331711737056" => {  "_destroy"=>"false",
                                                  "start"=>"2012" } } }
        trusted_attributes.must_equal(expected)
      end
    end

    context "no trusted keys" do
      it "raises an exception" do
        proc {
          controller.new.send(:trusted_attributes)
        }.must_raise TrustedKeys::Error::Usage
      end
    end

    context "0 level" do
      it "returns trusted keys" do
        controller.trust :email , :env => env
        trusted_attributes = controller.new.send(:trusted_attributes)
        trusted_attributes.must_equal("email" => "anders@email.com")
      end
    end

    context "1 level" do
      it "returns trusted keys" do
        controller.trust :body, :for => :post, :env => env
        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = { "body" => "I am a body" }
        trusted_attributes.must_equal(expected)
      end

      it "returns trusted keys" do
        controller.trust :body, :title, :comments, :for => :post, :env => env
        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = { "body" => "I am a body",
                     "title" => "This is my title",
                     "comments" => "" }
        trusted_attributes.must_equal(expected)
      end
    end

    context "2 levels" do
      it "returns trusted keys" do
        controller.trust :body, :comments, :for => :post, :env => env
        controller.trust :author, :for => 'post.comments', :env => env
        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = { "body" => "I am a body",
                     "comments" => { "author" => "" } }
        trusted_attributes.must_equal(expected)
      end
    end

    context "3 levels" do
      it "returns trusted keys" do
        controller.trust :body, :comments, :for => :post, :env => env
        controller.trust :author, :for => 'post.comments', :env => env
        controller.trust :name, :for => 'post.comments.author', :env => env
        trusted_attributes = controller.new.send(:trusted_attributes)

        expected = { "body" => "I am a body",
                     "comments" => { "author" => { "name" => "anders" } } }
        trusted_attributes.must_equal(expected)
      end
    end
  end
end
