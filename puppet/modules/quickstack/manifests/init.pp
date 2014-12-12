# Quickstack init
class quickstack () inherits quickstack::params {
  $list = scenario_classes("$scenario", $scenarii)

  notify {"running $scenario":}
  quick_include($list)
}

