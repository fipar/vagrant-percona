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
			unless => "mount | grep '/data/db'";
		"mkdir_mongo_datadir":
			command => "mkdir -p /data/db/",
			path => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
",
			unless => "test -d /data/db";

	}


	mount {
		"/data/db":
			ensure => "mounted",
			device => "/dev/$datadir_dev",
			fstype => "xfs",
			options => "noatime",
			atboot => "true",
			require => Exec["mkfs_mongo_datadir", "mkdir_mongo_datadir"];

	}


}