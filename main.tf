#####
# Add LB Server SSL
#####
resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb-srv.name)
  name      = "lb_srv_${element(var.adc-lb-srv["name"],count.index)}"
  ipaddress = element(var.adc-lb-srv["ip"],count.index)
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
  servername        = "lb_srv_${element(var.adc-lb["backend-server"],count.index)}"
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
  ipv46           = var.adc-lb-generic.lb-ip
  port            = var.adc-lb-generic.lb-port
  lbmethod        = var.adc-lb-generic.lbmethod
  persistencetype = var.adc-lb-generic.persistencetype
  timeout         = var.adc-lb-generic.timeout
  sslprofile      = element(var.adc-lb["type"],count.index) == "SSL" ? var.adc-lb-generic.sslprofilename : null
  httpprofilename = element(var.adc-lb["type"],count.index) == "DNS" || element(var.adc-lb["type"],count.index) == "TCP" ? null : var.adc-lb-generic.httpprofilename
  tcpprofilename  = element(var.adc-lb["type"],count.index) == "DNS" ? null : var.adc-lb-generic.tcpprofilename

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
# Save config
#####
resource "citrixadc_nsconfig_save" "lb_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
  ]
}