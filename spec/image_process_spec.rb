begin
  require 'rubygems'
rescue
end
require 'rmodbus'

include ModBus

describe ProcessImage do
  
  before do
    @srv = ModBus::TCPServer.new(1501,1)
	@srv.start

    @img = ProcessImage.new "Process_1", TCPClient.new('127.0.0.1', 1501, 1) do |pi|
      pi.add_scanner "scan_1", :scanrate => 1000, 
	                 :address => 0, 
					 :size => 10, 
					 :type => :holding_registers
	  pi.add_group   "grp_1"
	  pi.grp_1.add_group   "grp_2"
	  pi.grp_1.grp_2.add_point   "point_1", :scanner => "scan_1"
	end
  end

  it "should be have 'point_1'" do
    @img.grp_1.grp_2.point_1.class.should == Point
  end

  it "should be naming" do
    @img.name.should == "Process_1"
	@img.grp_1.name.should == "grp_1"
	@img.grp_1.grp_2.name.should == "grp_2"
	@img.grp_1.grp_2.point_1.name.should == "point_1"
  end


  after do
    @srv.stop
  end

end
