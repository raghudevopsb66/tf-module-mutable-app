resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.test.id
  port             = 80
}
