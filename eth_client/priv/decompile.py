import sys
import json
from panoramix.decompiler import decompile_bytecode

def get_hash(function_def):
    func = {}
    func['selector'] = function_def['hash']
    # We do want the name, but if it's unknown <> hash then it's useless
    func['name'] = function_def['abi_name']
    func['stateMutability'] = "pure"
    func['inputs'] = function_def['params']
    func['input_types'] = function_def['params']

    # inputs: Enum.map(method_map["inputs"], fn input -> input["name"] end),
    #   # What's the difference between type and internal type?
    #   input_types: Enum.map(method_map["inputs"], fn input -> input["internalType"] end)
    #TODO: get pure/view
    # NB: if that breaks, it might be because of the usage of const/payable as fields of the ABI
    #     use stateMutability instead (might need to fork panoramix)

    # method = %{
    #   name: String.to_atom(method_map["name"]),
    #   state_mutability: method_map["stateMutability"],
    #   inputs: Enum.map(method_map["inputs"], fn input -> input["name"] end),
    #   # What's the difference between type and internal type?
    #   input_types: Enum.map(method_map["inputs"], fn input -> input["internalType"] end)
    # }
    return func

if len(sys.argv) != 2:
    print("usage: python3 decode_address.py <address>", sys.argv)
else:
    decompilation = decompile_bytecode(sys.argv[1])
    # Despite its name, it's not a json
    hashes = list(map(get_hash, decompilation.json["functions"]))
    print(json.dumps(hashes))
