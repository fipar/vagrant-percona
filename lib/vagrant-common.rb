# Configure this node for AWS
# -- config: vm config from Vagrantfile
# -- name: name for the node displayed on the aws console
# -- instance_type: http://aws.amazon.com/ec2/instance-types/
# -- region: defaults to 'us-east-1'
# -- hostmanager_aws_ips: when using hostmanager, should we use 'public' or 'private' ips?

$aws_ip_cache = Hash.new
def provider_aws( name, config, instance_type, region = nil, security_groups = nil, hostmanager_aws_ips = nil )
	require 'yaml'

	aws_secrets_file = File.join( Dir.home, '.aws_secrets' )
	
	if( File.readable?( aws_secrets_file ))
		config.vm.provider "aws" do |aws, override|
			aws.instance_type = instance_type
		
			aws_config = YAML::load_file( aws_secrets_file )
			aws.access_key_id = aws_config.fetch("access_key_id")
			aws.secret_access_key = aws_config.fetch("secret_access_key")

			aws.tags = {
				'Name' => aws_config.fetch("instance_name_prefix") + " " + name
			}
		
			if region == nil
				aws.keypair_name = aws_config["keypair_name"]
				override.ssh.private_key_path = aws_config["keypair_path"]
      elsif aws_config['regions'][region] != nil
				aws.region = region
				aws.keypair_name = aws_config['regions'][region]["keypair_name"]
				override.ssh.private_key_path = aws_config['regions'][region]["keypair_path"]
      else
        # puts "Warning: AWS region #{region} not defined in your ~.aws_secrets file."
			end
		
			if security_groups != nil
				aws.security_groups = security_groups
			end
			
			if Vagrant.has_plugin?("vagrant-hostmanager")
				
				if hostmanager_aws_ips == "private" or hostmanager_aws_ips == nil
					awsrequest = "local-ipv4"
				elsif hostmanager_aws_ips == "public"
					awsrequest = "public-ipv4"
				end

				override.hostmanager.ip_resolver = proc do |vm|
					if $aws_ip_cache[name] == nil
						vm.communicate.execute("curl -s http://169.254.169.254/latest/meta-data/" + awsrequest + " 2>&1") do |type,data|
							$aws_ip_cache[name] = data if type == :stdout
						end
					end
					$aws_ip_cache[name]
				end
			end

      if block_given?
			  yield( aws, override )
      end
		end
	else
		puts "Skipping AWS because of missing/non-readable #{aws_secrets_file} file.  Read https://github.com/jayjanssen/vagrant-percona/blob/master/README.md#aws-setup for more information about setting up AWS."
	end
end

# Configure this node for Virtualbox
# -- config: vm config from Vagrantfile
# -- ram: amount of RAM (in MB)
def provider_virtualbox ( name, config, ram = 256, cpus = 1 )
	config.vm.provider "virtualbox" do |vb, override|
    vb.name = name
    vb.cpus = cpus
    vb.memory = ram
    
    vb.customize ["modifyvm", :id, "--ioapic", "on" ]

    # fix for slow dns https://github.com/mitchellh/vagrant/issues/1172
  	vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
		vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    
    # Custom ip resolver that works with DHCP or explicit addresses (and is fast)
    override.hostmanager.ip_resolver = proc do |vm, resolving_vm|
      if vm.id
        `VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
      end
    end

    if block_given?
      yield( vb, override )
    end
	end	
end

# Configure this node for VMware
# -- config: vm config from Vagrantfile
# -- ram: amount of RAM (in MB)
def provider_vmware ( name, config, ram = 256, cpus = 1 )
	config.vm.provider "vmware_fusion" do |v, override|
    v.name = name
    v.vmx["memsize"] = ram
    v.vmx["numvcpus"] = cpus

    if block_given?
      yield( v, override )
    end
	end	
end

# Provision this node with Puppet
# -- config: vm config from Vagrantfile
# -- manifest_file: puppet manifest to use (under puppet/manifests)
def provision_puppet( config, manifest_file )
  config.vm.provision manifest_file, type:"puppet", preserve_order: true do |puppet|
		puppet.manifest_file = manifest_file
    puppet.manifests_path = ["vm", "/vagrant/manifests"]
    puppet.options = "--verbose --modulepath /vagrant/modules"
    # puppet.options = "--verbose"
    if block_given?  
      yield( puppet )
    end
	end
end
