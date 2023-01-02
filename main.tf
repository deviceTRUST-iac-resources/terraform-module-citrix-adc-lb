#####
# Add LB Server SSL
#####

resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb.name)
  name      = "lb_srv_" + element(var.adc-lb["name"],count.index)
  ipaddress = element(var.adc-lb["ip"],count.index)
}

#####
# Add LB Service Groups
#####

resource "citrixadc_servicegroup" "lb_servicegroup" {
  count             = length(var.adc-lb.name)
  servicegroupname  = "lb_sg_" + element(var.adc-lb["name"],count.index) + "_" + element(var.adc-lb["type"],count.index) + "_" + element(var.adc-lb["port"],count.index)
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
  servicegroupname  = "lb_sg_" + element(var.adc-lb["name"],count.index) + "_" + element(var.adc-lb["type"],count.index) + "_" + element(var.adc-lb["port"],count.index)
  servername        = "lb_srv_" + element(var.adc-lb["name"],count.index) + "_" + element(var.adc-lb["type"],count.index) + "_" + element(var.adc-lb["port"],count.index)
  port              = element(var.adc-lb["port"],count.index)

  depends_on = [
    citrixadc_servicegroup.lb_servicegroup
  ]
}

#####
# Add and configure LB vServer - Type SSL
#####

resource "citrixadc_lbvserver" "lb_vserver_ssl" {
  count     = length(var.adc-lb.name)
  name      = "lb_vs_" + element(var.adc-lb["name"],count.index) + "_" + element(var.adc-lb["type"],count.index) + "_" + element(var.adc-lb["port"],count.index)

  servicetype = element(var.adc-lb["type"],count.index)
  # sslprofile = element(var.adc-lb-vserver-ssl["sslprofile"],count.index) ? SSL 
  sslprofile = ${element(var.adc-lb["type"],count.index) == SSL ? "ssl_prof_${var.adc-base.environmentname}" : NULL}
  ipv46 = element(var.adc-lb-vserver-ssl["ipv46"],count.index)
  port = element(var.adc-lb-vserver-ssl["port"],count.index)
  lbmethod = element(var.adc-lb-vserver-ssl["lbmethod"],count.index)
  persistencetype = element(var.adc-lb-vserver-ssl["persistencetype"],count.index)
  timeout = element(var.adc-lb-vserver-ssl["timeout"],count.index)
  httpprofilename = element(var.adc-lb-vserver-ssl["httpprofile"],count.index)
  tcpprofilename  = element(var.adc-lb-vserver-ssl["tcpprofile"],count.index)

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Add and configure LB vServer - Type not SSL
#####

resource "citrixadc_lbvserver" "lb_vserver_dns" {
  count     = length(var.adc-lb.name)
  name    = element(var.adc-lb-vserver-notssl["name"],count.index)

  servicetype = element(var.adc-lb-vserver-notssl["servicetype"],count.index)
  ipv46 = element(var.adc-lb-vserver-notssl["ipv46"],count.index)
  port = element(var.adc-lb-vserver-notssl["port"],count.index)
  lbmethod = element(var.adc-lb-vserver-notssl["lbmethod"],count.index)
  persistencetype = element(var.adc-lb-vserver-notssl["persistencetype"],count.index)
  timeout = element(var.adc-lb-vserver-notssl["timeout"],count.index)

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####

resource "citrixadc_lbvserver_servicegroup_binding" "lb_vserver_sg_binding" {
  count     = length(var.adc-lb.name)
  name              = element(var.adc-lb-vserver-sg-binding["name"],count.index)
  servicegroupname  = element(var.adc-lb-vserver-sg-binding["servicegroupname"],count.index)

  depends_on = [
    citrixadc_lbvserver.lb_vserver_ssl,
    citrixadc_lbvserver.lb_vserver_dns
  ]
}

#####
# Bind SSL certificate to SSL LB vServers
#####

resource "citrixadc_sslvserver_sslcertkey_binding" "lb_sslvserver_sslcertkey_binding" {
  count     = length(var.adc-lb.name)
  vservername = element(var.adc-lb-vserver-ssl["name"],count.index)
  certkeyname = "ssl_cert_democloud"
  snicert     = false

  depends_on = [
    citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
  ]
}

#####
# Save config
#####

resource "citrixadc_nsconfig_save" "lb_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_sslvserver_sslcertkey_binding.lb_sslvserver_sslcertkey_binding
  ]
}