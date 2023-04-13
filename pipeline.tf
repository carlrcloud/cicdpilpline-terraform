# lets create the codebuild project: plan and apply

resource "aws_codebuild_project" "tf-plan" {
  name         = "terraform-plan"
  description  = "plan stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.4"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/plan-buildspec.yaml")
  }

}
# this phase does the terraform apply

resource "aws_codebuild_project" "tf-apply" {
  name         = "terraform-apply"
  description  = "plan stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.4"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/apply-buildspec.yaml")
  }

}

# let's creeate the codepipeline to orchestrate all of this

resource "aws_codepipeline" "cicd_pipeline" {

  name     = "terraform-cicd-codepipeline"
  role_arn = aws_iam_role.tf_codepipeline_role.arn  

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.cicd.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["terraform-code"]
      configuration = {
        FullRepositoryId     = "carlrcloud/cicdpilpline-terraform"
        BranchName           = "main"
        ConnectionArn        = var.codestar_connector_credentials
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["terraform-code"]
      output_artifacts = ["source-output"]
      # configuration = {
      #   ProjectName = "tf-plan"
      # }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["source-output"]
      configuration = {
        ProjectName = "tf-apply"
      }
    }
  }

}