import boto3
from datetime import datetime, timedelta, timezone
import re
import json

def get_initial_info(events, context):
    instance_id = events['InstanceId']
    elbv2 = boto3.client('elbv2')
    ec2 = boto3.client('ec2')

    # --- 1. Generate Backup AMI Name ---
    response = ec2.describe_instances(InstanceIds=[instance_id])
    reservations = response.get('Reservations', [])
    name_tag = instance_id  # Fallback to instance ID if no Name tag

    if reservations:
        instances = reservations[0].get('Instances', [])
        if instances:
            tags = instances[0].get('Tags', [])
            for tag in tags:
                if tag['Key'] == 'Name':
                    name_tag = tag['Value']
                    break

    # Create timestamp in JST (UTC+9)
    jst = timezone(timedelta(hours=+9))
    timestamp = datetime.now(jst).strftime('%Y%m%dT%H%M%S')

    # Sanitize AMI Name (EC2 limit: 127 chars, allowed chars: alphanumeric, parenthesized, hyphen, underscore, dot, slash, at)
    sanitized_name = re.sub(r'[^a-zA-Z0-9()\[\]\.\-_/@]', '_', name_tag)
    ami_name = f"{sanitized_name}-{timestamp}"

    # Truncate to fit within 127 characters
    if len(ami_name) > 127:
        allowed_name_len = 127 - len(timestamp) - 1
        sanitized_name = sanitized_name[:allowed_name_len]
        ami_name = f"{sanitized_name}-{timestamp}"

    print(f"Generated AMI Name: {ami_name}")

    # --- 2. Check ALB Target Group ---
    paginator = elbv2.get_paginator('describe_target_groups')
    pages = paginator.paginate()

    is_in_alb = False
    tg_arn = None

    for page in pages:
        for tg in page['TargetGroups']:
            current_tg_arn = tg['TargetGroupArn']

            try:
                health_descriptions = elbv2.describe_target_health(TargetGroupArn=current_tg_arn)

                for target in health_descriptions['TargetHealthDescriptions']:
                    if target['Target']['Id'] == instance_id:
                        print(f"Instance {instance_id} found in Target Group {current_tg_arn}")
                        is_in_alb = True
                        tg_arn = current_tg_arn
                        break
                if is_in_alb:
                    break
            except elbv2.exceptions.TargetGroupNotFoundException:
                print(f"Target Group {current_tg_arn} not found, skipping.")
                continue

    if not is_in_alb:
        print(f"Instance {instance_id} not found in any Target Group.")

    return {
        'IsInAlb': is_in_alb,
        'TargetGroupArn': tg_arn,
        'AmiName': ami_name
    }

if __name__ == "__main__":
    data = get_initial_info({ "InstanceId": "i-06ffad08289c5e0e0"}, {})
    print(json.dumps(data, indent=4, ensure_ascii=False))
