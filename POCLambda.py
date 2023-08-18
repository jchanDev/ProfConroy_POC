import boto3

def lambda_handler(event, context):
    
    # Parse event data
    s3_event = event['Records'][0]['s3']
    print("s3event: " + s3_event)
    bucket_name = s3_event['bucket']['name']
    print("bucketname: " + bucket_name)
    object_key = s3_event['object']['key']
    print("objectkey: " + object_key)

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

    
    # except Exception as e:
    #     s3 = boto3.client('s3')

    #     # Specify the S3 bucket and file path
    #     bucket_name = 'csm-match-mock-data-matched'
    #     file_key = 'error_log.txt'

    #     # Create the error message
    #     error_message = f"Error: {str(e)}"

    #     # Upload the error message as a text file to S3
    #     s3.put_object(Bucket=bucket_name, Key=file_key, Body=error_message)

    #     # Return a response indicating failure
    #     return {
    #         'statusCode': 500,
    #         'body': 'An error occurred'
    #     }