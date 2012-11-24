require 'spec_helper'

describe Array do
  it "size! should check parameter types" do
    lambda { [].size!(Object) }.should raise_error("'Object' not supported, needs to be either Range or have .to_i method")
    lambda { [].size!(1, 2..3) }.should raise_error("size 0 does not match '1', '2..3'")
  end
  it "wrap should wrap anything other than array to an array" do
    Array.wrap(Object).should == [Object]
    Array.wrap([Object]).should == [Object]
  end
  it "find_first should support block selection" do
    [1, 2].find_first.should == 1
    [1, 2].find_first { |i| i==2 }.should == 2
    [1, 2].find_first(2).should == [1, 2]
    [1, 2].find_first(2) { |i| i==2 }.should == [2]
  end
end

describe Hash do
  it "[] should resolve default values if value not given" do
    h = {}
    h["a", 1].should == 1
  end
  it "require should warn if value not defined" do
    {"a"=>1}.require("a").should == 1
    lambda { {}.require("a") }.should raise_error("'a' is not defined!")
  end
end

describe File do
  before do
    @tester = Tester.new
  end

  after do
    @tester.after
  end

  it "safe_write should write to file" do
    tmp = @tester.tmpdir
    dest = File.join(tmp, "a.t")
    File.safe_write(dest, "1")
    IO.read(dest).should == "1"
    File.safe_write(dest) do |file|
      file.write("2")
    end
    IO.read(dest).should == "2"
  end
end

describe Enumerable do
  it "find_first should return first item" do
    class Test
      include Enumerable

      def each(&block)
        (1..10).each do |i|
          block.call(i)
        end
      end
    end
    Test.new.find_first { |c| c==2 }.should == 2
  end
  it "to_h should convert list to hash" do
    ["a=1", "b", "c="].to_h("=").should == {"a"=>"1", "b"=>true, "c"=>""}
    ["a=1", "b"].to_h { |i| i.split("=") }.should == {"a"=>"1", "b"=>nil}
  end
end
