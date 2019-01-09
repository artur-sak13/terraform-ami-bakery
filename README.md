# terraform-ami-bakery

[![Codacy](https://img.shields.io/codacy/grade/ef0eff7cf3de45d78d065b90504892f5.svg?style=for-the-badge)](https://app.codacy.com/app/artur-sak13/terraform-ami-bakery)

A Terraform module for automating AMI builds using AWS CodePipeline

## Getting Started

### Usage

Plan the infrastructure changes

```console
make plan
```

Create the infrastructure

```console
make apply
```

Update state file against real resources

```console
make refresh
```

Run the included Lambda notification webhook locally

```console
make run
```

### Using the `Makefile`

```console
$ make help
all                            Runs terraform plan and apply
apply                          Run terraform apply
destroy                        Run terraform destroy
plan                           Run terraform plan
refresh                        Refresh terraform state
run                            Runs the lambda function locally
```