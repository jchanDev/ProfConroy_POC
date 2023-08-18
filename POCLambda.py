import boto3

def lambda_handler(event, context):
    # Replace these values with your own
    stack_name = 'POCTemplate2AmazonLinux'
    template_url = 'https://lambda-store-bucket-poc-2023.s3.us-west-2.amazonaws.com/POCTemplate2AmazonLinux.yml'
    
    cloudformation = boto3.client('cloudformation')
    
    try:
        response = cloudformation.create_stack(
            StackName=stack_name,
            TemplateURL=template_url,
            OnFailure='ROLLBACK'
        )
        
        return {
            'statusCode': 200,
            'body': 'Stack creation initiated successfully'
        }
    except Exception as e:
        s3 = boto3.client('s3')

        # Specify the S3 bucket and file path
        bucket_name = 'csm-match-mock-data-matched'
        file_key = 'error_log.txt'

        # Create the error message
        error_message = f"Error: {str(e)}"

        # Upload the error message as a text file to S3
        s3.put_object(Bucket=bucket_name, Key=file_key, Body=error_message)

        # Return a response indicating failure
        return {
            'statusCode': 500,
            'body': 'An error occurred'
        }