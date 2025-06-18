
cluster := $(shell terraform output -raw cluster)
service := $(shell terraform output -raw service)

all: deploy wait

deploy:
	aws ecs update-service --cluster ${cluster} --service ${service} --force-new-deployment | jq

wait:
	aws ecs wait services-stable --cluster ${cluster} --service ${service}
