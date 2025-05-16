import os
import json
import gzip
import base64
import requests
from io import BytesIO

def lambda_handler(event, context):
    # Decodificar y descomprimir los logs
    log_data = decode_cloudwatch_logs(event)

    log_events = log_data.get("logEvents", [])
    if not log_events:
        print("No log events found.")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': "No error logs found."})
        }

    # Enviar cada mensaje de log a Slack
    for log_event in log_events:
        log_message = log_event.get("message", "")
        if log_message:
            print(f"Sending to Slack: {log_message}")
            send_to_slack(log_message)

    return {
        'statusCode': 200,
        'body': json.dumps({'message': f'Sent {len(log_events)} log events to Slack'})
    }

def decode_cloudwatch_logs(event):
    try:
        compressed_payload = base64.b64decode(event["awslogs"]["data"])
        with gzip.GzipFile(fileobj=BytesIO(compressed_payload)) as gzipfile:
            content = gzipfile.read()
            return json.loads(content)
    except Exception as e:
        print(f"Failed to decode log event: {e}")
        return {}

def send_to_slack(message):
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
    
    if not webhook_url:
        raise ValueError("SLACK_WEBHOOK_URL is not set in environment variables.")

    payload = {
        "text": f":warning: ERROR detected in logs:\n```{message}```"
    }

    headers = {
        "Content-Type": "application/json"
    }

    response = requests.post(webhook_url, data=json.dumps(payload), headers=headers)

    if response.status_code != 200:
        raise Exception(f"Failed to send message to Slack: {response.status_code}, {response.text}")
