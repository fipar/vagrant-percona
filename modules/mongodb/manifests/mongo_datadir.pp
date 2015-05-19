class mongodb::mongo_datadir {	

	# Need to set $datadir_dev from Vagrantfile for this to work right
	package {
		'xfsprogs': ensure => 'present';
	}

	exec {
		"mkfs_mongo_datadir":
			command => "mkfs.xfs -f /dev/$datadir_dev",
			require => Package['xfsprogs'],
			path => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
",
			unless => "mount | grep '/var/lib/mongo'";
		"mkdir_mongo_datadir":
			command => "mkdir -p /var/lib/mongo/",
			path => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
",
			unless => "test -d /var/lib/mongo";

	}


	mount {
		"/var/lib/mongo":
			ensure => "mounted",
			device => "/dev/$datadir_dev",
			fstype => "xfs",
			options => "noatime",
			atboot => "true",
			require => Exec["mkfs_mongo_datadir", "mkdir_mongo_datadir"];

	}


}