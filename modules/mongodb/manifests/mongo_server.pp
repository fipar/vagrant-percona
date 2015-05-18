class mongodb::mongo_server {
        file { '/etc/yum.repos.d/mongodb-org-3.0.repo':
                source => "/vagrant/modules/mongodb/files/mongodb-org-3.0.repo" 
        }
	package {
		'mongodb-org': 
			       ensure => 'installed',
			       require => File['/etc/yum.repos.d/mongodb-org-3.0.repo'];
	}
	service {
		'mongod':
			enable => true,
			ensure => 'running',
			require => Package['mongodb-org'];
	}
}
