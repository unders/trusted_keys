require 'minitest_helper'

describe TrustedKeys do
  let(:controller) do
    Class.new do
      include TrustedKeys

      def params
        { "email" => "anders@email.com",
          :nested_attributes => { "0" => {  "_destroy"=>"false",
                                            "start"=>"2012" },
                                  "new_1331711737056" => {  "_destroy"=>"false",
                                                            "start"=>"2012" } },
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
