# Web server cluster module

This folder contains example [Terraform](https://www.terraform.io/) configuration that define a module for deploying a 
cluster of web servers (using [EC2](https://aws.amazon.com/ec2/) and [Auto 
Scaling](https://aws.amazon.com/autoscaling/)) and a load balancer (using 
[ELB](https://aws.amazon.com/elasticloadbalancing/)) in an [Amazon Web Services (AWS) account](http://aws.amazon.com/). 
The load balancer listens on port 80 and returns the text "Hello, World" for the `/` URL.

## Quick start

Terraform modules are not meant to be deployed directly. Instead, you should be including them in other Terraform 
configurations. See `[stage/services/webserver-cluster]` and `[demo/services/webserver-cluster]` for examples.
