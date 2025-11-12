import os
import pytest
import requests
import yaml
from pathlib import Path

def load_config():
    config_path = Path(__file__).parent / 'config.yml'
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    for key, value in config['api'].items():
        if isinstance(value, str) and value.startswith('${') and value.endswith('}'):
            env_var = value[2:-1]
            config['api'][key] = os.environ.get(env_var, '')
    
    return config

@pytest.fixture(scope='session')
def config():
    return load_config()

class APIHelper:
    def __init__(self, base_url):
        self.base_url = base_url.strip()
    
    def make_request(self, endpoint, params=None, headers=None, method='GET'):
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        return requests.request(method, url, params=params, headers=headers)

@pytest.fixture(scope='session')
def api_helper(config):
    return APIHelper(config['api']['host'])

class APIClient:
    def __init__(self, api_helper):
        self.api_helper = api_helper
    
    def get(self, endpoint, headers=None, params=None):
        return self.api_helper.make_request(endpoint, params=params, headers=headers)

@pytest.fixture(scope='session')
def api_client(api_helper):
    return APIClient(api_helper)

@pytest.fixture(scope='session')
def valid_api_key(config):
    return config['api'].get('valid_api_key', '')

@pytest.fixture(scope='session')
def invalid_api_key():
    return 'invalid_api_key_12345'

@pytest.fixture(scope='session')
def valid_location():
    return 'New York'

@pytest.fixture(scope='session')
def oauth2_token(config):
    return config['api'].get('oauth2_token', '')
