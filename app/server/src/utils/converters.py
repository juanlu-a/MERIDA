import uuid
import base64

def short_uuid(name: str) -> base64:
    """Genera un ID usando uuid."""
    u = uuid.uuid4()
    return base64.urlsafe_b64encode(u.bytes).rstrip(b'=').decode('utf-8')
