
src=$(wildcard src/*.ts)
dist=$(src:src/%.ts=dist/%.js)
para=8

all: deploy

tsc: $(dist)
$(dist)&: $(src)
	tsc

build: package.zip
package.zip: $(dist)
	rm -f package.zip
	zip package.zip $(dist)

deploy: .build/deploy.txt
.build/deploy.txt: package.zip
	mkdir -p .build/
	aws lambda update-function-code --function-name throughput-func --zip-file fileb://package.zip > .build/deploy.txt

invoke: deploy
	aws lambda invoke \
		--cli-binary-format raw-in-base64-out \
		--function-name throughput-func \
		--log-type Tail \
		--payload '{"para":$(para)}' \
		/dev/null | jq .LogResult -r | base64 -d

put: tsc
	node dist/put.js
