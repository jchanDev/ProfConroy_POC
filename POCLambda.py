import boto3

def lambda_handler(event, context):
    try:
        # Parse event data
        s3_event = event['Records'][0]['s3']
        bucket_name = s3_event['bucket']['name']
        object_key = s3_event['object']['key']

        # Specify the CloudFormation template URL
        cloudformation_template_url = "https://lambda-store-bucket-poc-2023.s3.us-west-2.amazonaws.com/POCTemplate2AmazonLinux.yml"

        # Launch CloudFormation stack
        cloudformation_client = boto3.client('cloudformation')
        response = cloudformation_client.create_stack(
            StackName='POCTemplate2AmazonLinux',
            TemplateURL=cloudformation_template_url,
        )

        return {
            'statusCode': 200,
            'body': 'Stack creation initiated'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }
