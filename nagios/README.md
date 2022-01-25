Nagios 3 checks


`check_librenms_link.pl` -- poll a librenms instance from nagios as return data in a nagios state that will work well with nagios and nagvis in a similar way to https://exchange.nagios.org/directory/Plugins/Network-Connections,-Stats-and-Bandwidth/Monitoring-Interface-Bandwidth-Utilization-Using-Cacti-Data/details. Librenms in my install is served with a self-generated https cert, which isn't much use (I hide it behind a proxy with a real cert and authentication), so the check ignores SSL certificates

Configure it with the following nagios config

```
define command{
        command_name check_libre_bandwidth
        command_line $USER1$/check_librenms_link.pl token=abcdef1234567890 base=192.168.0.1 portid=$SERVICELIBREID$
}
define service{
        name                                    bandwidth-libre-service
        use                                     generic-service
        max_check_attempts                      3
        normal_check_interval                   1
        retry_check_interval                    1
        check_command                   check_libre_bandwidth
        notes                           <a href="https://librenms.server/graphs/id=$_SERVICELIBREID$/type=port_bits"><img src="https://librenms.server/graph.php?height=167&width=580&id=$_SERVICELIBREID$&type=port_bits"></a>
        contact_groups                          Admins
        notifications_enabled                   0
        register                                0                       
}

define service{
        use                             bandwidth-libre-service               
        host_name                       MyHost
        service_description             Bandwidth - Gi1/0/1 Uplink        
        _libreid                        737
        }
```


