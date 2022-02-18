# create application load balancer
resource "aws_lb" "main" {
  name               = "${random_pet.ec2.id}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id,aws_subnet.public_2.id]

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name        = "${random_pet.ec2.id}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${random_pet.ec2.id}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group" "admin" {
  name        = "admin-tg"
  port        = 3333
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.private.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "admin" {
  target_group_arn = aws_lb_target_group.admin.arn
  target_id        = aws_instance.private.id
  port             = 3333
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
   type = "redirect"

   redirect {
     port        = 443
     protocol    = "HTTPS"
     status_code = "HTTP_301"
   }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.wwwdomain.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "https-admin" {
  load_balancer_arn = aws_lb.main.id
  port              = 3333
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.wwwdomain.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.admin.id
    type             = "forward"
  }
}
