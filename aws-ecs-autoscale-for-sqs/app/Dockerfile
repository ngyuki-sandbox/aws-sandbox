# syntax=docker/dockerfile:1
# check=error=true

FROM public.ecr.aws/docker/library/node:20

USER node

WORKDIR /app

COPY --chown=node . .

RUN npm ci --omit=dev

ENTRYPOINT []
CMD [ "node", "main.mjs" ]
