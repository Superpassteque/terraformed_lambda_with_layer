import json
from basic import create_object_with_content, get_s3_object

def lambda_handler(event, context):
    
    
    suffix= "vv"
    
    key = "data/"
    filename = "example_file.txt"
    key+=filename

    targuet_bucket_name = "sp-public-tutorial-bucket-target-" +suffix
    source_bucket_name = "sp-public-tutorial-bucket-source-"+suffix
    
    obj = get_s3_object(source_bucket_name, key=key)
    body = obj.get()['Body'].read()
    body += b"DataTransformation"
    create_object_with_content(targuet_bucket_name, key , body=body)
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
 