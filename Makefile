.DEFAULT=build

build:
      docker build -t hmcts/zap-glue:latest

run:
  	docker run -it --rm --entrypoint sh hmcts/zap-glue:latest