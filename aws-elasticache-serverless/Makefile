
all:

build: ecr_repository_url=$(shell terraform -chdir=terraform/ output -raw ecr_repository_url)
build:
	docker build -t ${ecr_repository_url} app/
	aws ecr get-login-password | docker login --username AWS --password-stdin ${ecr_repository_url}
	docker push ${ecr_repository_url}
	terraform -chdir=terraform/ apply

logs: log_group_name=$(shell terraform -chdir=terraform/ output -raw log_group_name)
logs:
	aws logs tail "${log_group_name}" --follow --format short
