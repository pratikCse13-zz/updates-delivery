variable "aws_profile" {
  description = "The profile number of the AWS account to which all the infrastrcuture will be provisioned."
}

variable "aws_region" {
  description = "The AWS Region where the infrastructure is to be provisioned. For eg. eu-central-1"
}

variable "environment" {}

variable "repo" {
  description = "Name of the repository. Supplied on Drone as environment variable."
}

variable "version" {
  description = "Commit Hash. Supplied on Drone as environment variable"
}

variable "build_number" {
  description = "THe build number of the drone"
}

variable "email_sender_address" {
  description = "the email address from which the email is sent out"
}
