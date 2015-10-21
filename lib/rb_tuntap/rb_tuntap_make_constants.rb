require 'os'
require 'inline'

INCLUDES = %w(sys/ioctl net/if netinet/in)

case OS.host_os
when /linux/
INCLUDES.concat %w(linux/if_tun bits/ioctls)
INT_CONSTANTS = %w(IFNAMSIZ IFF_TUN IFF_TAP IFF_NO_PI)
HEX_CONSTANTS = %w(SIOCGIFADDR)
HEX_CONSTANTS.concat HEX_CONSTANTS.map {|n| n.sub("ADDR", "DSTADDR")}
HEX_CONSTANTS.concat %w(SIOCGIFMTU SIOCGIFNETMASK SIOCGIFFLAGS TUNGIFHEAD)
HEX_CONSTANTS.concat HEX_CONSTANTS.map {|n| n.sub("GIF", "SIF")}
HEX_CONSTANTS.concat %w(TUNSETIFF SIOCGIFINDEX)
OS_SPECIFIC="
struct in6_ifreq {
	struct in6_addr	ifr6_addr;
	__u32		ifr6_prefixlen;
	int		ifr6_ifindex; 
};
"
HEX_CONSTANTS.concat %w(IFF_UP)
STRUCT_SIZES = %w(ifreq in6_ifreq sockaddr_in6)
else
INCLUDES += %w(netinet6/in6_var net/if_dl)
INT_CONSTANTS = %w(IFNAMSIZ)
HEX_CONSTANTS = %w(SIOCGIFADDR)
HEX_CONSTANTS.concat HEX_CONSTANTS.map {|n| n.sub("ADDR", "DSTADDR")}
HEX_CONSTANTS.concat HEX_CONSTANTS.map {|n| n + "_IN6"}
HEX_CONSTANTS.concat %w(SIOCGIFMTU SIOCGIFNETMASK SIOCGIFFLAGS TUNGIFHEAD)
HEX_CONSTANTS.concat HEX_CONSTANTS.map {|n| n.sub("GIF", "SIF")}
HEX_CONSTANTS.concat %w(SIOCSIFLLADDR SIOCAIFADDR_IN6 SIOCDIFADDR_IN6) # can only set LLADDR?
HEX_CONSTANTS.concat %w(IN6_IFF_ANYCAST IN6_IFF_TENTATIVE IN6_IFF_DEPRECATED IN6_IFF_AUTOCONF)
HEX_CONSTANTS.concat %w(IFF_UP)
STRUCT_SIZES = %w(ifreq in6_ifreq sockaddr_in6 in6_addrlifetime)
end

class GetConstants
  num_constants = INT_CONSTANTS + HEX_CONSTANTS
  inline do |builder|
    builder.prefix "
#define TUNSIFHEAD  _IOW('t', 96, int)
#define TUNGIFHEAD  _IOR('t', 97, int)

#{OS_SPECIFIC}

    "
    INCLUDES.each do |incname|
      builder.include "<#{incname}.h>"
    end
    num_constants.each do |constname|
      builder.c "
int get_#{constname}() { return #{constname}; }
      "
    end
    STRUCT_SIZES.each do |structname|
      builder.c "
unsigned long get_#{structname}_size() { return sizeof(struct #{structname}); }
      "
    end
  end
end

def set_and_print(n, v, vform=v.to_s)
  puts "  #{n} = #{vform}"
  self.class.const_set(n, v)
end

gc = GetConstants.new
INT_CONSTANTS.each do |cn|
  set_and_print cn, gc.send("get_#{cn}")
end
HEX_CONSTANTS.each do |cn|
  val = gc.send("get_#{cn}")
  set_and_print cn, val, "0x%X" % val
end
STRUCT_SIZES.each do |sn|
  size = gc.send("get_#{sn}_size")
  name = "#{sn.upcase}_SIZE"
  set_and_print name, size, "0x%X" % size
end

def make_pack_spec(a)
  "'#{a.join}'"
end

set_and_print "IFREQ_PACK", "'Z#{IFNAMSIZ}a#{IFREQ_SIZE-IFNAMSIZ}'"
set_and_print "IN6_IFREQ_PACK", "'Z#{IFNAMSIZ}a#{IN6_IFREQ_SIZE-IFNAMSIZ}'"
set_and_print "IN6_ALIASREQ_PACK",  make_pack_spec([
              'Z', IFNAMSIZ,
              'a', SOCKADDR_IN6_SIZE,
              'a', SOCKADDR_IN6_SIZE,
              'a', SOCKADDR_IN6_SIZE,
              'i',
              'a', IN6_ADDRLIFETIME_SIZE
    ]) unless OS.host_os =~ /linux/

# struct in6_aliasreq {
# 	char	ifra_name[IFNAMSIZ];
# 	struct	sockaddr_in6 ifra_addr;
# 	struct	sockaddr_in6 ifra_dstaddr;
# 	struct	sockaddr_in6 ifra_prefixmask;
# 	int	ifra_flags;
# 	struct in6_addrlifetime ifra_lifetime;
# };
