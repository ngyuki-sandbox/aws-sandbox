import * as core from '@aws-cdk/core';
import * as sns from '@aws-cdk/aws-sns';
import * as sqs from '@aws-cdk/aws-sqs';
import * as lambda from '@aws-cdk/aws-lambda';
import * as logs from '@aws-cdk/aws-logs';
import * as events from '@aws-cdk/aws-events';
import * as targets from '@aws-cdk/aws-events-targets';
import * as sources from '@aws-cdk/aws-lambda-event-sources';

class AppStack extends core.Stack {
    constructor(scope: core.App, id: string, props?: core.StackProps) {
        super(scope, id, props);

        const helloTopic = new sns.Topic(this, 'HelloTopic', {
            topicName: 'hello-cdk-topic',
        });

        const helloQueue1 = new sqs.Queue(this, 'HelloQueue1', {
            queueName: 'hello-cdk-queue1',
        });

        const helloQueue2 = new sqs.Queue(this, 'HelloQueue2', {
            queueName: 'hello-cdk-queue2',
        });

        const helloLambda = new lambda.Function(this, 'HelloLambda', {
            functionName: 'hello-cdk-lambda',
            handler: 'index.handler',
            runtime: lambda.Runtime.NODEJS_12_X,
            memorySize: 128,

            // コードのディレクトリを指定
            code: lambda.Code.asset('src/'),

            // イベントソースを指定する
            events: [new sources.SqsEventSource(helloQueue1)],

            // トピックの ARN を環境変数に入れる
            environment: {
                SNS_TOTIC_ARN: helloTopic.topicArn,
            },

            // ロググループの失効期間を設定する Lambda が作成される
            // ロググループ自体が管理されるわけではないので destroy してもロググループは残る
            logRetention: logs.RetentionDays.ONE_DAY,
        });

        // イベントソースを props ではなくメソッドで指定する
        helloLambda.addEventSource(new sources.SqsEventSource(helloQueue2));

        // Lambda 関数に SNS トピックにパブリッシュするポリシーを与える
        helloTopic.grantPublish(helloLambda);

        // スケジュール実行のためのルールを作成
        new events.Rule(this, 'hello-rule', {
            schedule: events.Schedule.expression('rate(1 minute)'),
            targets: [new targets.LambdaFunction(helloLambda)]
        });
    }
}

const app = new core.App();
new AppStack(app, 'AppStack');
