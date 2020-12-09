output "alb_dns" {
  description = "The DNS of the ALB"
  value       = module.myapp.alb_dns
}
