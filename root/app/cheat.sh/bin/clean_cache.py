import sys
import redis
REDIS = redis.Redis(host='redis', port=6379, db=0)

for key in sys.argv[1:]:
    REDIS.delete(key)

