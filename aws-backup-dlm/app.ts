import * as core from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as iam from '@aws-cdk/aws-iam';
import * as dlm from '@aws-cdk/aws-dlm';
import * as backup from '@aws-cdk/aws-backup';
import * as events from '@aws-cdk/aws-events';

class OreStack extends core.Stack {
    constructor(scope: core.App, id: string, props?: core.StackProps) {
        super(scope, id, props);

        const vpc = new ec2.Vpc(this, 'Vpc', {
            cidr: '10.12.0.0/16',
            subnetConfiguration: [{
                cidrMask: 24,
                name: 'public',
                subnetType: ec2.SubnetType.PUBLIC,
            }]
        });

        const roleEc2 = new iam.Role(this, 'RoleEc2', {
            assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
            managedPolicies: [
                iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
            ]
        });

        const instance = new ec2.Instance(this, 'InstanceDLM', {
            vpc: vpc,
            keyName: process.env.KEY_NAME,
            instanceType: ec2.InstanceType.of(ec2.InstanceClass.T2, ec2.InstanceSize.NANO),
            machineImage: new ec2.AmazonLinuxImage({
                generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
                virtualization: ec2.AmazonLinuxVirt.HVM,
                storage: ec2.AmazonLinuxStorage.GENERAL_PURPOSE,
            }),
            role: roleEc2,
            blockDevices: [{
                deviceName: 'xvdh',
                volume: ec2.BlockDeviceVolume.ebs(2),
            }],
        });
        core.Tag.add(instance, 'Backup', 'true');
        core.Tag.add(instance, 'DLM', 'true');

        const roleDlm = new iam.Role(this, 'RoleDlm', {
            assumedBy: new iam.ServicePrincipal('dlm.amazonaws.com'),
            managedPolicies: [
                iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSDataLifecycleManagerServiceRole'),
            ],
        });

        new dlm.CfnLifecyclePolicy(this, 'DLM', {
            description: 'ec2 instande hourly backup',
            executionRoleArn: roleDlm.roleArn,
            policyDetails: {
                resourceTypes: ['INSTANCE'],
                targetTags: [
                    { key: 'DLM', value: 'true' },
                ],
                schedules: [{
                    name: 'hourly',
                    createRule: { interval: 1, intervalUnit: 'HOURS' },
                    retainRule: { count: 4 },
                    copyTags: true,
                }],
                parameters: {
                    excludeBootVolume: true,
                },
            },
            state: 'ENABLED',
        });

        const backupPlan = new backup.BackupPlan(this, 'Backup', {
            backupPlanRules: [{
                props: {
                    scheduleExpression: events.Schedule.expression("cron(0 * ? * * *)"),
                    startWindow: core.Duration.hours(1),
                    completionWindow: core.Duration.hours(8),
                    deleteAfter: core.Duration.days(1),
                }
            }],
        });
        backupPlan.addSelection('from-tag', {
            resources: [
                backup.BackupResource.fromTag('Backup', 'true'),
            ],
        });
    }
}

new OreStack(new core.App(), 'OreStack');
