You want to quickly test your new amazing cloud-native app on an AWS Kubernetes cluster? 
You need to fully automate your EKS deployment on AWS?

Perfect, you are in the right place. In this post you will find the operation to:

- Prepare your AWS IAM account and policies
- Prepare your Terraform Cloud Workplace
- Adapt the Terraform code to your needs
- Build, destroy and build again your cluster
- Deploy your app and access it

You will need to clone this repo : https://github.com/cisel-dev/eks-terraform-demo

First we will create a new IAM user **demo-eks**  with Programmatic access and the rights to use all the stuff needed to create an EKS cluster in a brand new VPC. It is really a hard point to find exactly which rights and policy we need to give and it depend on you environment. These right below will always work. You will probably want to limit these rights, particularly with regard to administrative rights.

We create a  new **EksAdminGroup** group with these two AWS Managed policy **AmazonEKSClusterPolicy**and 
**AdministratorAccess**. 

Then you have to add the user to this new **EksAdminGroup** group.


![2020-12-22 12_02_22-IAM Management Console – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608635011957/9xaEZKmsy.png)

Next step will be to setup the Workplace in Terraform Cloud. It's not mandatory to do so, you can work with local tfstate if you want. But we recommend to at least have a try to this free service (5 users).
Create an account on https://app.terraform.io/ and then link you Github or Gitlab Version Control System (VCS) with your Terraform Cloud.

To do so, simply follow the Terraform documentation below:

- GitLab : https://www.terraform.io/docs/cloud/vcs/gitlab-eece.html

- GitHub :  https://www.terraform.io/docs/cloud/vcs/github-app.html

![2020-12-22 13_48_34-VCS Provider _ ciselcloud _ Terraform Cloud – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608641399595/IKGNz5ciO.png)

After you successfully added your VCS we will create a Terraform Workplace. To do so you need to clone our repo and to push it to your Git. Then you can create a Workplace and select the newly created repo in the list.

![2020-12-22 16_24_26-Write Blog Post – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608650702981/TlmnuUqgl.png)

The Workplace will take some time to synchronize. If everything is good you will see it in the list.

![2020-12-22 13_47_46-Workspaces _ ciselcloud _ Terraform Cloud – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608641405702/E9BvwIYYu.png)

You will have to create Terraform Variables that will be used to connect to your AWS to create the cluster and all the resources. Use the values of the **AWS_ACCESS_KEY_ID** and the **AWS_SECRET_ACCESS_KEY** for the **demo-eks** user and put them in variables of your Workplace. Set these variables as sensitive.
Terraform Cloud creates an ephemeral VM to run Terraform operations (which create and manage your infrastructure). 


![image.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608642152117/BilpM8oE-.png)

Create a new API Token to be used from your Workstation when you will interact with Terraform: https://app.terraform.io/app/settings/tokens


You will need to edit some values to be able to run this project.

demo-eks-backend.tf : Fill with your Terraform values
```
terraform {
  backend "remote" {
    organization = "your-organisation"

    workspaces {
      name = "your-workplace"
    }
  }
}
```
demo-eks-vpc.tf : Change the AWS Region if needed
```
...
variable "region" {
  default     = "eu-west-3"
  description = "AWS region"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = "eu-west-3"
}
...
```

Okay, **let's deploy an EKS cluster using Terraform!**

Go to your project folder and run ```terraform login```
Then write ```yes``` in the prompt and give the API token that we just created.

![2020-12-22 14_32_44-demo-eks-kubernetes.tf - demo-terraform-eks-cluster [WSL_ Ubuntu-18.04] - Visual.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608644019884/IsgVZwIrF.png)

Then initialize terraform with the command ```terraform init```

![2020-12-22 14_44_00-demo-eks-kubernetes.tf - demo-terraform-eks-cluster [WSL_ Ubuntu-18.04] - Visual.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608644669386/rBVG-3UTq.png)

Execute ```terraform plan``` and review what will be created

Finally ```terraform apply``` to deploy the infrastructure

Again, answer ```yes``` when asked in the prompt. 

You can see the status of the RUN in the Terraform Cloud web UI

If you do not answer yes to the prompt you will see the status NEED CONFIRMATION
![2020-12-22 14_46_51-Workspaces _ ciselcloud _ Terraform Cloud – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608644916381/no2ucme_e.png)

or RUNNING when terraform is still creating
![2020-12-22 14_47_20-Workspaces _ ciselcloud _ Terraform Cloud – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608644922630/qb3g6iDDj.png)

The deployment can take a few minutes. Running apply in the remote Terraform Cloud backend. Output will stream here. Pressing Ctrl-C will cancel the remote apply if it's still pending. If the apply started it will stop streaming the logs, but will not stop the apply running  remotely.

The final output of the run will give you precious information about your newly created EKS cluster.  
Your kubeconfig content, you will need to create a **kubeconfig** file with this output and the run ```export KUBECONFIG=kubeconfig```
![2020-12-22 15_24_29-Greenshot Éditeur d'Image.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608647098539/gzM_Xv_ne.png)

We will need the  aws-iam-authenticator tool to interact with AWS, follow the installation link below
https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

The command to configure your access to EKS. Give the access key ID and secret of **demo-eks**
```
aws configure
aws eks --region $(terraform output region) update-kubeconfig --name $(terraform output cluster_name)
```

Check your cluster status
```
kubectl cluster-info
kubectl get nodes -o wide
kubectl get all -A
```

When you do not need your cluster any more you can destroy it. And of course create it again the next time you need it.

To destroy the cluster you will first need to remove the config_map from the terraform state. 

```
terraform destroy
yes
```

You can see the status **Deleting ** of your cluster in the AWS console. After a few minutes your cluster and all the resources are deleted from AWS.
![2020-12-22 15_57_20-Amazon EKS – Mozilla Firefox.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1608649169893/naI7XOMLe.png)

Ooooops you had forgotten that you had to show some funny stuff on Kubernetes to your colleagues this afternoon? Dont't worry, create again your AKS Cluster in AWS.

```
terraform init
terraform plan
terraform apply
```

Feel free to contact us directly if you have any question at cloud@cisel.ch 

https://www.cisel.ch