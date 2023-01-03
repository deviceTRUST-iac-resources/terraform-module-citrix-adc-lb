locals {
  httpprofilename  = "http_prof_${var.adc-base.environmentname}"
  tcpprofilename   = "tcp_prof_${var.adc-base.environmentname}"
  lbmethod         = "LEASTCONNECTION"
  persistencetype  = "SOURCEIP"
  timeout          = "2"
  lb-ip            = "0.0.0.0"
  lb-port          = 0
  sslprofilename   = "ssl_prof_${var.adc-base.environmentname}_fe_TLS1213"
  sslcertkeyname   = "ssl_cert_${var.adc-base.environmentname}"
  sslsnicert       = "false"
}

#####
# Add LB Server SSL
#####

resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb.name)
  name      = "lb_srv_${element(var.adc-lb["name"],count.index)}"
  ipaddress = element(var.adc-lb["backend-server"],count.index)
}

#####
# Add LB Service Groups
#####

resource "citrixadc_servicegroup" "lb_servicegroup" {
  count             = length(var.adc-lb.name)
  servicegroupname  = "lb_sg_${element(var.adc-lb["name"],count.index)}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"
  servicetype       = element(var.adc-lb["type"],count.index)

  depends_on = [
    citrixadc_server.lb_server
  ]
}

#####
# Bind LB Server to Service Groups
#####

resource "citrixadc_servicegroup_servicegroupmember_binding" "lb_sg_server_binding" {
  count             = length(var.adc-lb.name)
  servicegroupname  = "lb_sg_${element(var.adc-lb["name"],count.index)}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"
  servername        = "lb_srv_${element(var.adc-lb["name"],count.index)}"
  port              = element(var.adc-lb["port"],count.index)

  depends_on = [
    citrixadc_servicegroup.lb_servicegroup
  ]
}

#####
# Add and configure LB vServer - Type SSL
#####

resource "citrixadc_lbvserver" "lb_vserver" {
  count           = length(var.adc-lb.name)
  name            = "lb_vs_${element(var.adc-lb["name"],count.index)}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"

  servicetype     = element(var.adc-lb["type"],count.index)
  # sslprofile = element(var.adc-lb["sslprofile"],count.index) ? SSL 
  ipv46           = local.lb-ip
  port            = local.lb-port
  lbmethod        = local.lbmethod
  persistencetype = local.persistencetype
  timeout         = local.timeout
  sslprofile      = element(var.adc-lb["type"],count.index) == "SSL" ? local.sslprofilename : null
  httpprofilename = element(var.adc-lb["type"],count.index) == "DNS" || element(var.adc-lb["type"],count.index) == "TCP" ? null : local.httpprofilename
  tcpprofilename  = element(var.adc-lb["type"],count.index) == "DNS" ? null : local.tcpprofilename

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####

resource "citrixadc_lbvserver_servicegroup_binding" "lb_vserver_sg_binding" {
  count             = length(var.adc-lb.name)
  name              = "lb_vs_${element(var.adc-lb["name"],count.index)}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"
  servicegroupname  = "lb_sg_${element(var.adc-lb["name"],count.index)}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}"

  depends_on = [
    citrixadc_lbvserver.lb_vserver
  ]
}

#####
# Bind SSL certificate to SSL LB vServers
#####

#resource "citrixadc_sslvserver_sslcertkey_binding" "lb_sslvserver_sslcertkey_binding" {
#  count       = length(var.adc-lb.name)
#  vservername = element(var.adc-lb["type"],count.index) == "SSL" ?  "lb_vs_${element(var.adc-lb["name"],count.index)}_${element(var.adc-lb["type"],count.index)}_${element(var.adc-lb["port"],count.index)}" : null
#  certkeyname = element(var.adc-lb["type"],count.index) == "SSL" ? local.sslcertkeyname : null
#  snicert     = element(var.adc-lb["type"],count.index) == local.sslsnicert ? "false" : null

#  depends_on = [
#    citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
#  ]
#}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "lb_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
  ]
}