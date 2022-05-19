import sys
import json
from panoramix.decompiler import decompile_address

def get_hash(function_def):
    return function_def['hash']

if len(sys.argv) != 2:
    print("usage: python3 decode_address.py <address>", sys.argv)
else:
    decompilation = decompile_address(sys.argv[1])

    # Despite its name, it's not a json. At least, Jason was complaining.
    hashes = list(map(get_hash, decompilation.json["functions"]))
    print(json.dumps(hashes))
