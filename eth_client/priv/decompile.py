import sys
import json
from panoramix.decompiler import decompile_bytecode

def get_hash(function_def):
    func = {}
    func['selector'] = function_def['hash']
    func['name'] = function_def['abi_name']

    if function_def['payable']:
        # This needs some work
        func['stateMutability'] = "payable"
    else: 
        func['stateMutability'] = "nonpayable"
    if function_def['const']:
        func['stateMutability'] = "view"
    
    func['type'] = "function"
    
    return func

if len(sys.argv) != 2:
    print("usage: python3 decode_address.py <address>", sys.argv)
else:
    decompilation = decompile_bytecode(sys.argv[1])
    # Despite its name, it's not a json
    hashes = list(map(get_hash, decompilation.json["functions"]))
    print(json.dumps(hashes))
