import boto3

def lambda_handler(event, context):
    
    cloudformation_client = boto3.client('cloudformation')
    
    # delete CloudFormation stack
    response = cloudformation_client.delete_stack(StackName= "POCTemplate2AmazonLinux")


    return {
        'statusCode': 200,
        'body': 'Stack deletion initiated for POCTemplate2AmazonLinux'
    }