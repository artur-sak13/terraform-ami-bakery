import pytest

from unops_notify import lambda_function


@pytest.fixture()
def cwlogs_event():
    """ Generates CloudWatch Event """

    return {
        "version": "0",
        "id": "12345678-9b15-3579-b619-7869ada6n04k",
        "detail-type": "Unops Build",
        "source": "com.unops.build",
        "account": "012345678901",
        "time": "2018-12-28T17:59:41Z",
        "region": "us-east-1",
        "resources": [
            "ami-0fd1c9a63f8fdb8a5"
        ],
        "detail": {
            "Name": "CentOS-7-1546018097",
            "AmiStatus": "Created"
        }
    }


def test_lambda_handler(cwlogs_event, mocker):
    ret = lambda_function.lambda_handler(cwlogs_event, None)

    if not ret['statusCode'] == 200:
        raise AssertionError()

    if not ret['body'] == 'ok':
        raise AssertionError()
