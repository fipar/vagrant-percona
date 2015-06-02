class mongodb::mongo_server {
        file { '/etc/yum.repos.d/mongodb-org-3.0.repo':
                source => "/vagrant/modules/mongodb/files/mongodb-org-3.0.repo" 
        }
	package {
		'mongodb-org': 
			       ensure => 'installed',
			       require => File['/etc/yum.repos.d/mongodb-org-3.0.repo'];
	}
	exec {
	     "chown_mongo_datadir":
		command => "/bin/chown -R mongod.mongod /var/lib/mongo/",
		require => Package['mongodb-org'];
	}
	service {
		'mongod':
			enable => true,
			ensure => 'running',
			require => [ Package['mongodb-org'], exec['chown_mongo_datadir'] ];
	}
}
