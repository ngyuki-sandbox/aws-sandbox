import { transform, generatePayload, post } from './index.mjs'

const input = {
    messageType: 'DATA_MESSAGE',
    owner: '000000000000',
    logGroup: '/hoge/dev/instance/hoge/app.log',
    logStream: 'hoge-dev-ap-a',
    subscriptionFilters: [ 'ERROR' ],
    logEvents: [
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is error message"}' },
      { id: '00000000000000000000000000000000000000000000000000000000', timestamp: 1669359314751, message: '{"channel": "app","level": "ERROR","message": "this is other message"}' },
    ]
};

const data = transform(input);
console.log(data);

const payload = generatePayload(data);
console.log(JSON.stringify(payload, null, 2));

post(payload);
