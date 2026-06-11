import redis
import json
import os
from functools import wraps

class RedisCache:
    def __init__(self):
        self.client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'localhost'),
            port=int(os.getenv('REDIS_PORT', 6379)),
            decode_responses=True,
            socket_connect_timeout=3,
            socket_timeout=3
        )
    
    def get(self, key):
        try:
            data = self.client.get(key)
            return json.loads(data) if data else None
        except:
            return None
    
    def set(self, key, value, ttl=300):
        try:
            self.client.setex(key, ttl, json.dumps(value))
        except:
            pass
    
    def delete(self, key):
        try:
            self.client.delete(key)
        except:
            pass
    
    def delete_pattern(self, pattern):
        try:
            keys = self.client.keys(pattern)
            if keys:
                self.client.delete(*keys)
        except:
            pass

# Singleton instance
cache = RedisCache()