#!/usr/bin/env ruby


class ::String
  def hexi
    bytes.map{|x| "%02x" % x}.join
  end
  def hexs
    bytes.map{|x| "%02x" % x}.join(" ")
  end
  def xeh
    chars.each_slice(2).map{ |x| x.join.hex.chr("BINARY") }.join
  end
end



require 'rb_tuntap'
require 'timeout'

require 'packetfu'

DEV_NAME = 'tun0'
DEV_ADDR1 = '192.168.192.168'
DEV_ADDR2 = '3ffe::1'

STDOUT.puts("** Opening tun device as #{DEV_NAME}")
tun = RbTunTap::TapDevice.new(DEV_NAME)
tun.open(true)
puts "ifname is #{tun.ifname}"

STDOUT.puts("** Assigning ip #{DEV_ADDR1} to device")
tun.addr = DEV_ADDR1
STDOUT.puts("** Assigning ip #{DEV_ADDR2} to device")
tun.addr = DEV_ADDR2
tun.up

STDOUT.puts("** Interface stats (as seen by ifconfig)")
STDOUT.puts(`ifconfig #{tun.ifname}`)

STDOUT.puts("** Reading from the tun device (waiting 5s)")
bytes = ''
begin
  Timeout::timeout(5) {
    loop do
      io = tun.to_io
      bytes = io.sysread(1500)
      pk = PacketFu::Packet.parse(bytes)
      p pk
    end
  }
rescue Timeout::Error
  STDOUT.puts("** 5 seconds are done")
end

STDOUT.puts("** Bringing down and closing device")
tun.down
tun.close
