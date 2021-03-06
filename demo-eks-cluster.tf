module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.18"
  subnets         = module.vpc.private_subnets
  manage_aws_auth = false

  tags = {
    Environment = "demo"
    GitlabRepo  = "terraform-aws-eks"
    GitlabOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  # Block below to patch  ValidationError: gp3 is invalid #1205 
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1205
  workers_group_defaults = {  #
  	root_volume_type = "gp2"
  }
   
  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
