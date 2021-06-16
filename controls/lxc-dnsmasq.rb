lxc_net = input('lxc_net')
#puts input_object('lxc_net').diagnostic_string

control "lxc_net" do
  impact 1.0
  title "LXC Netz mit dns und dhcp testen"
  desc "Das LXC Netz soll mit gegebenen Parametern laufen"
  
  describe systemd_service('lxc-net') do
    it { should be_installed }
    it { should be_enabled }  
    it { should be_running }  
  end

  describe file('/etc/default/lxc-net') do
    it { should exist }
    it { should be_file }
    it { should be_readable }
    it { should be_writable }
    it { should be_owned_by 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should match "LXC_BRIDGE=\"#{lxc_net[:'bridge']}\"" }
    its('content') { should match "LXC_ADDR=\"#{lxc_net[:'ip']}\"" }
    its('content') { should match "LXC_NETMASK=\"#{lxc_net[:'netmask']}\"" }
    its('content') { should match "LXC_NETWORK=\"#{lxc_net[:'network']}\"" }
    its('content') { should match "LXC_DHCP_RANGE=\"#{lxc_net[:'range_start']},#{lxc_net[:'range_end']}\"" }
    its('content') { should match "LXC_DHCP_MAX=\"#{lxc_net[:'max_leases']}\"" }
    its('content') { should match "#{lxc_net[:'dnsmasq_conf']}" }
    its('content') { should match "LXC_DOMAIN=\"#{lxc_net[:'domain']}\"" }
  end

  # systemd-resolve --interface=${LXC_BRIDGE} \
  #              --set-dns=${LXC_ADDR} \
  #              --set-domain=${LXC_DOMAIN:-default}
  # FAILED=0
  describe file('/usr/lib/x86_64-linux-gnu/lxc/lxc-net') do
    search = /systemd-resolve\s*.*/
    search_array = [ "--interface=.*", "--set-dns=.*", "--set-domain=.*" ]
    search_array.each do |substring|
        regex = Regexp.new( search.source + substring)
        #/
        it { should exist }
        it { should be_file }
        it { should be_readable }
        it { should be_writable }
        it { should be_owned_by 'root' }
        its('mode') { should cmp '0755' }
        its('content') { should match regex }
    end
  end

  
  lxc_interface=Regexp.quote("(#{lxc_net[:'bridge']})")
  white_spaces="\\n(\s*.*:\s*.*\\n\\s*)+"
  lxc_interface=lxc_interface+white_spaces
  lxc_dns_ip=Regexp.quote("DNS Servers: #{lxc_net[:'ip']}")
  lxc_dns_domain=Regexp.quote("DNS Domain: #{lxc_net[:'domain']}")
  describe bash("ps aux | grep dnsmasq ") do
    its('stdout') { should match /-s #{lxc_net[:'domain']} -S \/#{lxc_net[:'domain']}\// }
  end
  describe bash('systemd-resolve --status') do
    lxc_vagrant_dns=lxc_interface+lxc_dns_ip
    its('stdout') { should match lxc_vagrant_dns }
  end
  describe bash('systemd-resolve --status') do
    lxc_vagrant_dns=lxc_interface+lxc_dns_domain
    its('stdout') { should match lxc_vagrant_dns }
  end
end
