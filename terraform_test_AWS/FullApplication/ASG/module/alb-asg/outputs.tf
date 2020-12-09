output "alb_dns" {
  description = "The DNS name of the ALB"
  value       = module.alb.this_lb_dns_name
}
