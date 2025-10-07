FROM public.ecr.aws/docker/library/node:22

COPY package.json package-lock.json /app/

WORKDIR /app

RUN  npm ci --omit=dev

COPY . /app/
