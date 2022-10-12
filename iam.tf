resource "aws_iam_policy" "parameter-store-access" {
  name        = "RoboShop_${var.COMPONENT}_${var.ENV}_ParameterStore_Access"
  path        = "/"
  description = "RoboShop_${var.COMPONENT}_${var.ENV}_ParameterStore_Access"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:us-east-1:739561048503:parameter/mutable*",
          "arn:aws:ssm:us-east-1:739561048503:parameter/nexus*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "parameter-store-access" {
  name = "RoboShop_${var.COMPONENT}_${var.ENV}_ParameterStore_Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "RoboShop_${var.COMPONENT}_${var.ENV}_ParameterStore_Access"
  }
}

resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.parameter-store-access.name
  policy_arn = aws_iam_policy.parameter-store-access.arn
}

resource "aws_iam_instance_profile" "parameter-store-access" {
  name = "RoboShop_${var.COMPONENT}_${var.ENV}_ParameterStore_Access"
  role = aws_iam_role.parameter-store-access.name
}



