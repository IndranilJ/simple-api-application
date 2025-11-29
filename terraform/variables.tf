variable "project_id" {
  type = string
#   default = "test-sample-api-479708"
}
variable "region"     {
  type    = string
  default = ""
#   default = "asia-south1"
}
variable "repository_id" {
  type    = string
  default = ""
#   default = "hello-api-repo"
}
variable "service_name"  {
  type    = string
  default = ""
#   default = "hello-api"
}
variable "image_tag"     {
  type    = string
  default = ""
#   default = "latest"
}
variable "allow_unauth"  {
  type    = bool
  default = true
}
variable "cpu"           {
  type    = number
  default = 1
}
variable "memory"        {
  type    = string
  default = "512Mi"
}
variable "env" {
  type = map(string)
  default = {
    APP_ENV = "prod"
  }
}