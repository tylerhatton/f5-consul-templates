variable "prefix" {
  default = "f5-azure-consul-ws"
}

variable "environment" {
  default = "test"
}

variable "cidr" {
  default = "10.0.0.0/8"
}

variable "region" {
  default = "centralus"
}

variable "instance_type" {
  default = "Standard_DS3_v2"
}

variable "image_name" {
  default = "f5-bigip-virtual-edition-25m-better-hourly"
}

variable "publisher" {
  default = "f5-networks"
}

variable "product" {
  default = "f5-big-ip-better"
}

variable "bigip_version" {
  default = "16.1.201000"
}

variable "admin_username" {
  default = "f5admin"
}

variable "DO_URL" {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.27.1/f5-declarative-onboarding-1.27.1-2.noarch.rpm"
}

variable "AS3_URL" {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.32.1/f5-appsvcs-3.32.1-1.noarch.rpm"
}

variable "TS_URL" {
  description = "URL to download the BIG-IP Telemetry Streaming Extension (TS) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.20.1/f5-telemetry-1.20.1-1.noarch.rpm"
}

variable "FAST_URL" {
  description = "URL to download the BIG-IP F5 Application Services Templates (FAST) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.16.0/f5-appsvcs-templates-1.16.0-1.noarch.rpm"
}

variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  type        = string
  default     = "/config/cloud/aws/node_modules"
}

variable "onboard_log" {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  type        = string
  default     = "/var/log/startup-script.log"
}
