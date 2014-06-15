class php::install {
    $phppackages = ['php5-mysql', 'php5-curl', 'php5-gd', 'php5-intl', 'php-pear', 'php5-imagick', 'php5-imap', 'php5-mcrypt', 'php5-tidy', 'php5-sqlite', 'php5-memcache', 'php5-ming', 'php5-ps', 'php5-pspell', 'php5-recode', 'php5-snmp', 'php5-xmlrpc', 'php5-xsl', 'php5-cli', 'php5-common', 'php5-dev', 'php5-geoip', 'php5-gmp', 'php-apc', 'php5-xdebug']
    
    package { 'python-software-properties':
      ensure => installed
    }

    exec { 'add-apt-repository ppa:ondrej/php5':
        command => '/usr/bin/add-apt-repository ppa:ondrej/php5',
        require => Package["python-software-properties"],
    }

    exec { 'apt-get update for latest php':
        command => '/usr/bin/apt-get update',
        before => Package[$phppackages],
        require => Exec['add-apt-repository ppa:ondrej/php5'],
    }

    package { $phppackages: 
        ensure => installed
    }

    exec { 'pear-auto-discover':
        path => '/usr/bin:/usr/sbin:/bin',
        onlyif => 'test "`pear config-get auto_discover`" = "0"',
        command => 'pear config-set auto_discover 1 system',
    }

    exec { 'pear-update':
        path => '/usr/bin:/usr/sbin:/bin',
        command => 'pear update-channels && pear upgrade-all',
    }

    exec { 'install-phpunit':
        unless => "/usr/bin/which phpunit",
        command => '/usr/bin/pear install pear.phpunit.de/PHPUnit --alldeps',
        require => [Exec['pear-auto-discover'], Exec['pear-update']]
    }

    exec { 'install-phpdocumentor':
        unless => "/usr/bin/which phpdoc",
        command => "/usr/bin/pear install pear.phpdoc.org/phpDocumentor-alpha --alldeps",
        require => [Exec['pear-auto-discover'], Exec['pear-update']]
    }
}

class php::configure {
    exec { 'php-cli-set-timezone':
        path => '/usr/bin:/usr/sbin:/bin',
        command => 'sed -i \'s/^[; ]*date.timezone =.*/date.timezone = Africa\/Johannesburg/g\' /etc/php5/cli/php.ini',
        onlyif => 'test "`php -c /etc/php5/cli/php.ini -r \"echo ini_get(\'date.timezone\');\"`" = ""',
        require => Class['php::install']
    }

    exec { 'php-cli-disable-short-open-tag':
        path => '/usr/bin:/usr/sbin:/bin',
        command => 'sed -i \'s/^[; ]*short_open_tag =.*/short_open_tag = Off/g\' /etc/php5/cli/php.ini',
        onlyif => 'test "`php -c /etc/php5/cli/php.ini -r \"echo ini_get(\'short_open_tag\');\"`" = "1"',
        require => Class['php::install']
    }

    exec { 'php-fpm-set-timezone':
        path => '/usr/bin:/usr/sbin:/bin',
        command => 'sed -i \'s/^[; ]*date.timezone =.*/date.timezone = Africa\/Johannesburg/g\' /etc/php5/fpm/php.ini',
        onlyif => 'test "`php -c /etc/php5/fpm/php.ini -r \"echo ini_get(\'date.timezone\');\"`" = ""',
        require => Class['php::install'],
        notify => Service['php5-fpm']
    }

    exec { 'php-fpm-disable-short-open-tag':
        path => '/usr/bin:/usr/sbin:/bin',
        command => 'sed -i \'s/^[; ]*short_open_tag =.*/short_open_tag = Off/g\' /etc/php5/fpm/php.ini',
        onlyif => 'test "`php -c /etc/php5/fpm/php.ini -r \"echo ini_get(\'short_open_tag\');\"`" = "1"',
        require => Class['php::install'],
        notify => Service['php5-fpm']
    }
}

class php::run {
    service { php5-fpm:
        enable => true,
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        require => Class['php::install', 'php::configure'],
    }
}

class php {
    include php::install
    include php::configure
    include php::run
}
