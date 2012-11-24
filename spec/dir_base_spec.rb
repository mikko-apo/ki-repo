require 'spec_helper'

describe DirectoryBase do
  before do
    @tester = Tester.new
  end

  after do
    @tester.after
  end

  it "should support find!" do
    root = DirectoryBase.new(@tester.tmpdir)
    test = root.mkdir("test")
    DirectoryBase.find!("test", test, root).ki_path.should == "/test"
    lambda { DirectoryBase.find!("test/2", test, root) }.should raise_error("Could not find 'test/2' from '#{root.path}/test', '#{root.path}'")
  end
end