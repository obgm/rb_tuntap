require 'os'
require 'socket'

module RbTunTap

  require_relative 'rb_tuntap_constants'

  DEV_TYPE_TUN = "tun"
  DEV_TYPE_TAP = "tap"

  @sock = Socket.new(Socket::PF_INET, Socket::SOCK_DGRAM, 0)
  @sock6 = Socket.new(Socket::PF_INET6, Socket::SOCK_DGRAM, 0)

  def self.sock
    @sock
  end
  def self.sock6
    @sock6
  end

  class Device

    def initialize(name, type, dev)
      raise ArgumentError, "Interface name '#{name}' too long" if name.size >= IFNAMSIZ
      raise ArgumentError, "Unknown interface type '#{type}'" if !%w(tun tap).include? type
      @name = name              # not used in OSX
      @type = type
      @dev = dev
    end

    def open(pkt_info)          # what to do with pkt_info?
        case OS.host_os
        when /linux/
          ifname = @name
          @io = File.open("#{@dev}", "rb+")
          buf = [ifname, (@type == "tap" ? IFF_TAP : IFF_TUN) | IFF_NO_PI, ""]
                .pack("Z#{IFNAMSIZ}S_a#{IFREQ_SIZE-IFNAMSIZ-2}")
          @io.ioctl(TUNSETIFF, buf)
          @ifname = buf.unpack("Z#{IFNAMSIZ}").shift
        else
          (0..15).detect do |num|
            begin
              ifname = "#{@type}#{num}"
              @io = File.open("/dev/#{ifname}", "rb+")
              @ifname = ifname
            rescue
              nil
            end
          end
        end
      raise "Can't open #{@type}" unless @io
    end

    attr_reader :ifname

    def set_addr(addrstr)
      name, prefixlen = addrstr.split("/")
      _offname, _aliasnames, af, addr = Socket.gethostbyname(name)
      sin = Socket::sockaddr_in(0, name)
      case af
      when Socket::PF_INET
        buf = [@ifname, sin].pack(IFREQ_PACK)
        RbTunTap.sock.ioctl(SIOCSIFADDR, buf)
      when Socket::PF_INET6
        prefixlen = "128" if prefixlen.nil?
        case OS.host_os
        when /linux/
          buf = [@ifname, ""].pack(IFREQ_PACK)
          RbTunTap.sock.ioctl(SIOCGIFINDEX, buf)
          _ifname, union = buf.unpack(IFREQ_PACK)
          ifindex, = union.unpack("i")    # read ifr.if_index

          # IN6_IFREQ_PACK
          buf = [addr, prefixlen.to_i, ifindex].pack("a16Li")
          RbTunTap.sock6.ioctl(SIOCSIFADDR, buf)
        else
        lifetimes = [0, 0, -1, -1].pack("QQll")
        buf = [@ifname, sin, '', Socket.sockaddr_in(0, "FFFF:FFFF:FFFF:FFFF::"),
               0, lifetimes].pack(IN6_ALIASREQ_PACK)
        RbTunTap.sock6.ioctl(SIOCAIFADDR_IN6, buf)
        end
      else
        raise "Unknown address family #{af} for #{name} = #{addr.inspect}"
      end
    end

    def up(desired = IFF_UP)
      buf = [@ifname, [0].pack("S")].pack(IFREQ_PACK)
      RbTunTap.sock.ioctl(SIOCGIFFLAGS, buf)
      _ifname, union = buf.unpack(IFREQ_PACK)
      flags, = union.unpack("S")
      unless flags & IFF_UP != desired
        flags &= ~IFF_UP
        flags |= desired
        buf = [@ifname, [flags].pack("S")].pack(IFREQ_PACK)
        RbTunTap.sock.ioctl(SIOCSIFFLAGS, buf)
      end
    end

    def down
      up(0)
    end

    def close
      if @io
        @io.close
        @io = nil
      end
    end

  end

end
