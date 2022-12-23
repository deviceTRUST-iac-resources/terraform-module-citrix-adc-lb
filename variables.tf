#####
# Variables for administrative connection to the ADC
#####

variable adc-base{
}

#####
# ADC Loadbalancing Server
#####

variable "adc-lb-server" {
}

#####
# ADC Loadbalancing Servicegroups
#####

variable adc-lb-servicegroup {
}

#####
# ADC Loadbalancing Servicegroup-Server-Bindings
#####

variable adc-lb-sg-server-binding {
}

#####
# ADC Loadbalancing vServer - Type SSL
#####

variable adc-lb-vserver-ssl{
}

#####
# ADC Loadbalancing vServer - Type not SSL
#####

variable adc-lb-vserver-notssl{
}

#####
# ADC Loadbalancing vServer-Servicegroup-Bindings
#####

variable adc-lb-vserver-sg-binding {
}