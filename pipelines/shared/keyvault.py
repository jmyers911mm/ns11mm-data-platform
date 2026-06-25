"""
Key Vault client — shared across all NS11MM pipelines.

Usage in any pipeline:
    from shared.keyvault import secret
    value = secret("MY-SECRET-NAME")
"""

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

KV_URL = "https://kv-ns11mm-dp-dev.vault.azure.net/"

_client = None

def _get_client():
    global _client
    if _client is None:
        _client = SecretClient(vault_url=KV_URL, credential=DefaultAzureCredential())
    return _client

def secret(name: str) -> str:
    """Fetch a secret value from Azure Key Vault by name."""
    return _get_client().get_secret(name).value
