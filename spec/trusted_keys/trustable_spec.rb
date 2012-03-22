require 'minitest_helper'

Klass = Class.new do
  include TrustedKeys::Trustable
end

NotTrusted = TrustedKeys::Error::NotTrusted
Usage = TrustedKeys::Error::Usage

describe TrustedKeys::Trustable do
  let(:trustableClass) do
    Class.new do
      include TrustedKeys::Trustable

      def env
        OpenStruct.new(:test? => false, :development? => false)
      end
    end
  end

  let(:klass) do
    Class.new do
      include TrustedKeys::Trustable

      def env
        OpenStruct.new(:test? => true, :development? => false)
      end
    end
  end

  let(:params) do
    { "email" => "anders@email.com",
      :controller => "events",
      :password => "secret",
      :post =>  {  :body => "I am a body",
                   :title => "This is my title",
                   :comments =>  { 'body' => 'My body',
                                   :email => "an email" } } }
  end

  describe "#on_scope" do

  end

  describe "#attributes" do

    describe "when in test or development environment" do
      context "level 0" do
        it "doesn't raise an exception if not alla params is trusted" do
          t = klass.new([], [], :email)
          t.attributes(params).must_equal("email" => "anders@email.com")
        end
      end

      context "level 1" do
        it "raises an exception if not all params is trusted" do
          t = klass.new([:post], [], :body)
          proc { t.attributes(params) }.must_raise NotTrusted
        end
      end

      context "level 2" do
        it "raises an exception if not all params is trusted" do
          t = klass.new([:post, :comments], [], :body)
          proc { t.attributes(params) }.must_raise NotTrusted
        end
      end

      context "next level hash not trusted" do
        it "raises an exception" do
          t = klass.new([], [], :email, :password, :post)
          proc {
            t.attributes(params)
          }.must_raise NotTrusted
        end
      end
    end

    context "level 0" do
      it "returns trusted params for level 0" do
        t = trustableClass.new([], [], :email)
        t.attributes(params).must_equal("email" => 'anders@email.com')
      end

      it "turns next hash into an empty string if next key not trusted" do
        t = trustableClass.new([], [], :post)
        t.attributes(params).must_equal("post" => '')
      end

      it "returns the next hash if it has trusted keys" do
        level1 = trustableClass.new([:post], [], :body)
        t = trustableClass.new([], [level1], :post)

         expected = {"post"=> { "body"=>"I am a body",
                                "title"=>"This is my title",
                                "comments"=> { "body"=>"My body",
                                               "email"=>"an email"} } }
        t.attributes(params).must_equal(expected)
      end
    end

    context "level 1" do
      it "returns trusted params for level 1" do
        post = trustableClass.new([:post], [], :body)
        post.attributes(params).must_equal("body" => 'I am a body')
      end
    end

    context "level 2" do
      it "returns trusted params for level 2" do
        post = trustableClass.new([:post, :comments], [], :body)
        post.attributes(params).must_equal("body" => 'My body')
      end
    end
  end

  describe "#key" do
    context "scope is empty" do
      it "returns nil" do
        Klass.new([], []).key.must_equal nil
      end
    end

    context "scope has 1 key" do
      it "returns the key" do
        Klass.new([:post], []).key.must_equal :post
      end
    end

    context "scope has 2 keys" do
      it "returns the last key - deepest key" do
        Klass.new([:post, :comment], []).key.must_equal :comment
      end
    end
  end

  describe "#level" do
    context "scope is empty" do
      it "returns 0" do
        Klass.new([], []).level.must_equal 0
      end
    end

    context "scope has 1 key" do
      it "returns 1" do
        Klass.new([:post], []).level.must_equal 1
      end
    end

    context "scope has 2 keys" do
      it "returns 2" do
        Klass.new([:post, :comment], []).level.must_equal 2
      end
    end
  end

  describe "#<=>" do
    describe "sort an array" do
      before do
        @a1 = Klass.new([:post, :comment], [])
        @a2 = Klass.new([:post], [])
        @array = [@a1, @a2]
        @array.first.must_equal @a1
      end

      it "sort objects with the lowest level first" do
        @array.sort.first.must_equal @a2
      end
    end
  end

end
