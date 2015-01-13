define quickstack::pacemaker::vips(
  $public_vip,
  $private_vip,
  $admin_vip,
  $pcmk_group = $title,
  ) {

  Exec['stonith-setup-complete'] ->
  quickstack::pacemaker::resource::ip { "ip-${pcmk_group}-pub":
    ip_address => "$public_vip",
  }

  if ( $public_vip != $private_vip ) {
    Exec['stonith-setup-complete'] ->
    Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-pub"] ->
    quickstack::pacemaker::resource::ip { "ip-${pcmk_group}-prv":
      ip_address => "$private_vip",
    } ->
    quickstack::pacemaker::constraint::colocation { "ip-${pcmk_group}-pub-prv-colo" :
      source => "ip-${pcmk_group}-prv-${private_vip}",
      target => "ip-${pcmk_group}-pub-${public_vip}",
    }
  }

  if ( ($admin_vip != $private_vip) and ($admin_vip != $public_vip) ) {
    Exec['stonith-setup-complete'] ->
    Quickstack::Pacemaker::Resource::Ip["ip-${pcmk_group}-pub"] ->
    quickstack::pacemaker::resource::ip { "ip-${pcmk_group}-adm":
      ip_address => "$admin_vip",
    } ->
    quickstack::pacemaker::constraint::colocation { "ip-${pcmk_group}-pub-adm-colo" :
      source => "ip-${pcmk_group}-adm-${admin_vip}",
      target => "ip-${pcmk_group}-pub-${public_vip}",
    }
  }
}
