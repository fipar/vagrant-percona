class mongodb::mongo_sample_data {
	exec { 'mongoimport device_measurements.json':
		command => '/usr/bin/bunzip2 -c /vagrant/sample_data/device_measurements.json.bz2 | /usr/bin/mongoimport --drop --db metrics --collection device_measurements --type json',
		timeout => 1800, 
		creates => '/var/lib/mongo/metrics.ns'
	}
}
