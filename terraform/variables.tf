data "http" "myip" {
    url = "http://ipv4.icanhazip.com"
}

locals {
  root_ip_address = "${chomp(data.http.myip.body)}"
}

