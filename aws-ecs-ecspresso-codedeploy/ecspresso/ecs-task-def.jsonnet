local vars = import 'vars.json';

{
  family: vars.family,
  networkMode: 'awsvpc',
  requiresCompatibilities: ['FARGATE'],
  cpu: '256',
  memory: '512',
  executionRoleArn: vars.executionRoleArn,
  taskRoleArn: vars.taskRoleArn,
  runtimePlatform: {
    operatingSystemFamily: 'LINUX',
    cpuArchitecture: 'X86_64',
  },
  containerDefinitions: [
    {
      name: 'app',
      image: 'public.ecr.aws/docker/library/nginx:alpine',
      essential: true,
      command: [
        'sh',
        '-c',
        'echo "$MESSAGE" > /usr/share/nginx/html/index.html && exec nginx -g \'daemon off;\'',
      ],
      environment: [
        { name: 'MESSAGE', value: 'hello from ecspresso' },
      ],
      portMappings: [
        { containerPort: 80, protocol: 'tcp' },
      ],
      logConfiguration: {
        logDriver: 'awslogs',
        options: {
          'awslogs-group': vars.logGroup,
          'awslogs-region': vars.region,
          'awslogs-stream-prefix': 'ecs',
        },
      },
    },
  ],
}
