begin
  require 'rubygems'
rescue
end
require 'rmodbus'

include ModBus

describe RTUClient do
    
  before do 
    @sp = mock('Serial port')
    SerialPort.should_receive(:new).with("/dev/port1", 9600, 8, 1, 0).and_return(@sp)    
    @sp.stub!(:read_timeout=)
    @sp.stub!(:read)

    @mb_client = RTUClient.new("/dev/port1", 9600, 1, 
      :data_bits => 8, :stop_bits => 1, :parity => SerialPort::NONE)
    @mb_client.read_retries = 0
  end

  it "should ignore frame with other UID" do
    request = "\x10\x0\x1\x0\x1\x2\xff\xff" 
    @sp.should_receive(:write).with("\1#{request}\xA6\x31")
    @sp.should_receive(:read).with(2).and_return("\x2\x10")
    @sp.should_receive(:read).with(6).and_return("\x0\x1\x0\x1\x1C\x08")
    lambda {@mb_client.query(request)}.should raise_error(ModBus::Errors::ModBusTimeout)
  end

  it "should ignored frame with incorrect CRC" do
    request = "\x10\x0\x1\x0\x1\x2\xff\xff" 
    @sp.should_receive(:write).with("\1#{request}\xA6\x31")
    @sp.should_receive(:read).with(2).and_return("\x2\x10")
    @sp.should_receive(:read).with(6).and_return("\x0\x1\x0\x1\x1C\x08")
    lambda {@mb_client.query(request)}.should raise_error(ModBus::Errors::ModBusTimeout)
  end
  
  it "should return value of registers"do
    request = "\x3\x0\x1\x0\x1"
    @sp.should_receive(:write).with("\1#{request}\xd5\xca")
    @sp.should_receive(:read).with(2).and_return("\x1\x3")
    @sp.should_receive(:read).with(1).and_return("\x2")
    @sp.should_receive(:read).with(4).and_return("\xff\xff\xb9\xf4")
    @mb_client.query(request).should == "\xff\xff"
  end

 it 'should sugar connect method' do
    port, baud, slave = "/dev/port1", 4800, 3
    SerialPort.should_receive(:new).with(port, baud, 8, 1, SerialPort::NONE).and_return(@sp)    
    @sp.should_receive(:closed?).and_return(false)
    @sp.should_receive(:close)
    RTUClient.connect(port, baud, slave) do |cl|
      cl.port.should == port
      cl.baud.should == baud
      cl.slave.should == slave
      cl.data_bits.should == 8
      cl.stop_bits.should == 1
      cl.parity.should == SerialPort::NONE
    end
  end

  it 'should have closed? method' do
    @sp.should_receive(:closed?).and_return(false)
    @mb_client.closed?.should == false

    @sp.should_receive(:closed?).and_return(false)
    @sp.should_receive(:close)

    @mb_client.close

    @sp.should_receive(:closed?).and_return(true)
    @mb_client.closed?.should == true
  end

end

