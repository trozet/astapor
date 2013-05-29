class foreman::install {
  if ! $foreman::custom_repo {
    foreman::install::repos { 'foreman':
      repo => $foreman::repo
    }
  }

  $repo = $foreman::custom_repo ? {
    true    => [],
    default => Foreman::Install::Repos['foreman'],
  }

  case $foreman::db_type {
    sqlite: {
      case $::operatingsystem {
        Debian,Ubuntu: { $package = 'ruby193-foreman-sqlite3' }
        default:       { $package = 'ruby193-foreman-sqlite' }
      }
    }
    postgresql: {
      $package = 'ruby193-foreman-postgresql'
    }
    mysql: {
      $package = 'ruby193-foreman-mysql'
    }
  }

  package { $package:
    ensure  => present,
    require => $repo,
  }
}
