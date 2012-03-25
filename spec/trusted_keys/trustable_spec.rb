require 'minitest_helper'

NotTrusted = TrustedKeys::Error::NotTrusted
Usage = TrustedKeys::Error::Usage

describe TrustedKeys::Trustable do
  let(:test) { OpenStruct.new(:test? => true, :development? => false) }

  let(:klass) do
    Class.new do
      include TrustedKeys::Trustable
    end
  end

  let(:params) do
    { "email" => "anders@email.com",
      :controller => "events",
      :time => { "start_time(1i)"=>"2012",
                 "start_time(2i)"=>"3",
                 "start_time(3i)"=>"14" },
      :events => {
        :nested_attributes => { "0" => {  "_destroy"=>"false",
                                          "dangerous" => "remove me",
                                          "start"=>"2012" },
                                "new_1331711737056" => {  "_destroy"=>"false",
                                                          "start"=>"2012" } } },
      :password => "secret",
      :post =>  {  :body => "I am a body",
                   :title => "This is my title",
                   :comments =>  { 'body' => 'My body',
                                   :email => "an email",
                                   :author => { :name => "anders" } } } }
  end

  def options(options_hash)
    { :scope => [],
      :trusted_keys => [],
      :untrusted => NotTrusted.new(OpenStruct.new(:test? => false,
                                                  :development? => false)),
      :keys => [:email]
    }.merge(options_hash)
  end

  describe "datetime selects" do
    it "return all datetime attributes" do
      t = klass.new(options(:scope => [:time],
                            :trusted_keys => [],
                            :keys => [:start_time]))

      expected = {  "start_time(1i)"=>"2012",
                    "start_time(2i)"=>"3",
                    "start_time(3i)"=>"14" }
      t.attributes(params).must_equal(expected)
    end
  end

  describe "nested attributes" do
    it "returns nested hash" do
      t = klass.new(options(:scope => [:events, :nested_attributes],
                            :trusted_keys => [],
                            :keys => [ "start" ]))

      expected = { "0" => {  "_destroy"=>"false",
                             "start"=>"2012" },
                   "new_1331711737056" => {  "_destroy"=>"false",
                                             "start"=>"2012" } }
      t.attributes(params[:events]).must_equal(expected)
    end
  end

  describe "#attributes" do
    describe "when in test or development environment" do
      context "level 0" do
        it "doesn't raise an exception if all params isn't trusted" do
          t = klass.new(options(:scope => [],
                                :trusted_keys => [],
                                :untrusted => NotTrusted.new(test),
                                :keys => [:email]))
          t.attributes(params).must_equal("email" => "anders@email.com")
        end
      end

      context "level 1" do
        it "raises an exception if all params isn't trusted" do
          t = klass.new(options(:scope => [:post],
                                :trusted_keys => [],
                                :untrusted => NotTrusted.new(test),
                                :keys => [:body]))
          proc { t.attributes(params) }.must_raise NotTrusted
        end
      end

      context "level 2" do
        it "raises an exception if all params isn't trusted" do
          t = klass.new(options(:scope => [:post, :comments],
                                :trusted_keys => [],
                                :untrusted => NotTrusted.new(test),
                                :keys => [:body]))
          proc { t.attributes(params[:post]) }.must_raise NotTrusted
        end
      end

      context "hash on next level isn't trusted" do
        it "raises an exception" do
          t = klass.new(options(:scope => [],
                                :trusted_keys => [],
                                :untrusted => NotTrusted.new(test),
                                :keys => [:email, :password, :post]))
          proc { t.attributes(params) }.must_raise NotTrusted
        end
      end
    end

    context "level 0" do
      it "returns trusted params for level 0" do
        t = klass.new(options(:scope => [],
                              :trusted_keys => [],
                              :keys => [:email]))
        t.attributes(params).must_equal("email" => 'anders@email.com')
      end

      it %(transform hash on next level to an empty string if its keys
           aren't trusted) do
        t = klass.new(options(:scope => [],
                              :trusted_keys => [],
                              :keys => [:post]))
        t.attributes(params).must_equal("post" => '')
      end

      it "returns the hash on next level if it has trusted keys" do
        level1 = klass.new(options(:scope => [:post],
                                   :trusted_keys => [],
                                   :keys => [:body]))
        t = klass.new(options(:scope => [],
                              :trusted_keys => [level1],
                              :keys => [:post]))

        expected = {"post"=> { "body"=>"I am a body",
                               "title"=>"This is my title",
                               "comments"=> { "body"=>"My body",
                                              "email"=>"an email",
                                              "author"=>{"name"=>"anders"}} } }

        t.attributes(params).must_equal(expected)
        level1.attributes(params).must_equal("body" => "I am a body")
      end
    end

    context "level 1" do
      it "returns trusted params for level 1" do
        t = klass.new(options(:scope => [:post],
                                 :trusted_keys => [],
                                 :keys => [:body]))
        t.attributes(params).must_equal("body" => 'I am a body')
      end
    end

    context "level 2" do
      it "returns trusted params for level 2" do
        t = klass.new(options(:scope => [:post, :comments],
                                 :trusted_keys => [],
                                 :keys => [:body]))
        t.attributes(params[:post]).must_equal("body" => 'My body')
      end
    end
  end

  describe "#on_scope" do
    context "level 2" do
      it "returns the hash for that level" do
        t = klass.new(options(:scope => [:post, :comments],
                              :trusted_keys => [],
                              :keys => [:body]))
        t.on_scope(params[:post]).must_equal(params[:post])
      end
    end

    context "level 3" do
      it "returns the hash for that level" do
        t = klass.new(options(:scope => [:post, :comments, :author],
                              :trusted_keys => [],
                              :keys => [:name]))
        t.on_scope(params[:post]).must_equal(params[:post][:comments])
      end
    end

    context "level 1" do
      it "not applicable" do
        t = klass.new(options(:scope => [:post],
                              :trusted_keys => [],
                              :keys => [:body]))
        proc { t.on_scope(params) }.must_raise NoMethodError
      end
    end

    context "level 0" do
      it "not applicable" do
        t = klass.new(options(:scope => [],
                              :trusted_keys => [],
                              :keys => [:body]))
        proc { t.on_scope(params) }.must_raise NoMethodError
      end
    end
  end

  describe "#key" do
    context "scope is empty" do
      it "returns nil" do
        klass.new(options(:scope => [])).key.must_equal nil
      end
    end

    context "scope has 1 key" do
      it "returns the key" do
        klass.new(options(:scope => [:post])).key.must_equal :post
      end
    end

    context "scope has 2 keys" do
      it "returns the last key - deepest key" do
        klass.new(options(:scope => [:post, :comment])).key.must_equal :comment
      end
    end
  end

  describe "#level" do
    context "scope is empty" do
      it "returns 0" do
        klass.new(options(:scope => [])).level.must_equal 0
      end
    end

    context "scope has 1 key" do
      it "returns 1" do
        klass.new(options(:scope =>[:post])).level.must_equal 1
      end
    end

    context "scope has 2 keys" do
      it "returns 2" do
        klass.new(options(:scope => [:post, :comment])).level.must_equal 2
      end
    end
  end

  describe "#<=>" do
    describe "sort an array" do
      before do
        @a1 = klass.new(options(:scope =>[:post, :comment]))
        @a2 = klass.new(options(:scope => [:post]))
        @array = [@a1, @a2]
        @array.first.must_equal @a1
      end

      it "sort objects with the lowest level first" do
        @array.sort.first.must_equal @a2
      end
    end
  end
end
