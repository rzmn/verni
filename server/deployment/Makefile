include .env

create:
	yc serverless container create --name $(SERVERLESS_CONTAINER_NAME)
	yc serverless container allow-unauthenticated-invoke --name  $(SERVERLESS_CONTAINER_NAME)

create_gw_spec:
	$(shell sed "s/SERVERLESS_CONTAINER_ID/${SERVERLESS_CONTAINER_ID}/;s/SERVICE_ACCOUNT_ID/${SERVICE_ACCOUNT_ID}/" api-gw.yaml.example > api-gw.yaml)
create_gw: create_gw_spec
	yc serverless api-gateway create --name $(SERVERLESS_CONTAINER_NAME) --spec api-gw.yaml

create_db:
	yc ydb database create $(YDB_NAME) --serverless

build:
	docker build -t cr.yandex/$(YC_IMAGE_REGISTRY_ID)/$(SERVERLESS_CONTAINER_NAME) --platform=linux/amd64 ..
push: build
	docker push cr.yandex/$(YC_IMAGE_REGISTRY_ID)/$(SERVERLESS_CONTAINER_NAME)

deploy: push
	$(shell sed 's/=.*/=/' .env > .env.example)
	yc serverless container revision deploy --container-name $(SERVERLESS_CONTAINER_NAME) --image 'cr.yandex/$(YC_IMAGE_REGISTRY_ID)/$(SERVERLESS_CONTAINER_NAME):latest' --service-account-id $(SERVICE_ACCOUNT_ID)  --environment='$(shell tr '\n' ',' < .env)' --core-fraction 5 --execution-timeout $(SERVERLESS_CONTAINER_EXEC_TIMEOUT)

all: deploy