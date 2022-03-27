title: Consul NIA Template
description: This template will create a virtual server that will be used by HashiCorp Consul Terraform Sync.
definitions:
  tenant:
    title: Name of tenant
    description: A unique name for this tenant
  app:
    title: Application
    description: A unique name for this application
  virtualAddress:
    title: Virtual Address
    description: IP addresses of virtual addresses (will create 80/443)
  virtualPort:
    title: Virtual Port
    description: Port that will be used
    type: integer
parameters:
  service: "nginx"
  virtualAddress: ${vip_address}
  virtualPort: 8080
  tenant: "Consul_Sync"
  app: "Nginx"
template: |
  {
    "class": "AS3",
    "action": "deploy",
    "persist": true,
    "declaration": {
        "class": "ADC",
        "schemaVersion": "3.0.0",
        "id": "urn:uuid:940bdb69-9bcd-4c5c-9a34-62777210b581",
        "label": "Consul",
        "remark": "Consul NIA Template",
        "{{tenant}}": {
          "class": "Tenant",
          "{{app}}": {
              "class": "Application",
              "webserver_vs": {
                "class": "Service_HTTP",
                "virtualPort": {{virtualPort}},
                "virtualAddresses": [
                    "{{virtualAddress}}"
                ],
                "pool": "nginx_pool",
                "persistenceMethods": [],
                "profileMultiplex": {
                "bigip": "/Common/oneconnect"
              }
              },
              "nginx_pool": {
                "class": "Pool",
                "monitors": [
                    "http"
                ],
                "members": [{
              "servicePort": 80,
              "addressDiscovery": "event"
            }]
              }
          }
        }
    }
  }
