defmodule EthClientTest do
  use ExUnit.Case
  doctest EthClient
  alias EthClient.Account
  alias EthClient.Context
  alias ExUnit.CaptureIO

  @bin "../contracts/src/bin/Storage.bin"
  @abi "../contracts/src/bin/Storage.abi"

  @opcodes "[0] PUSH 0x80\n[1] PUSH 0x40\n[2] MSTORE\n[3] CALLVALUE\n[4] DUP1\n[5] ISZERO\n[6] PUSH 0x0010\n[7] JUMPI\n[8] PUSH 0x00\n[9] DUP1\n[10] REVERT\n[11] JUMPDEST\n[12] POP\n[13] PUSH 0x04\n[14] CALLDATASIZE\n[15] LT\n[16] PUSH 0x0041\n[17] JUMPI\n[18] PUSH 0x00\n[19] CALLDATALOAD\n[20] PUSH 0xE0\n[21] SHR\n[22] DUP1\n[23] PUSH 0x2E64CEC1\n[24] EQ\n[25] PUSH 0x0046\n[26] JUMPI\n[27] DUP1\n[28] PUSH 0x4EAF8B7C\n[29] EQ\n[30] PUSH 0x0064\n[31] JUMPI\n[32] DUP1\n[33] PUSH 0x6057361D\n[34] EQ\n[35] PUSH 0x0082\n[36] JUMPI\n[37] JUMPDEST\n[38] PUSH 0x00\n[39] DUP1\n[40] REVERT\n[41] JUMPDEST\n[42] PUSH 0x004E\n[43] PUSH 0x009E\n[44] JUMP\n[45] JUMPDEST\n[46] PUSH 0x40\n[47] MLOAD\n[48] PUSH 0x005B\n[49] SWAP2\n[50] SWAP1\n[51] PUSH 0x00D3\n[52] JUMP\n[53] JUMPDEST\n[54] PUSH 0x40\n[55] MLOAD\n[56] DUP1\n[57] SWAP2\n[58] SUB\n[59] SWAP1\n[60] RETURN\n[61] JUMPDEST\n[62] PUSH 0x006C\n[63] PUSH 0x00A7\n[64] JUMP\n[65] JUMPDEST\n[66] PUSH 0x40\n[67] MLOAD\n[68] PUSH 0x0079\n[69] SWAP2\n[70] SWAP1\n[71] PUSH 0x00D3\n[72] JUMP\n[73] JUMPDEST\n[74] PUSH 0x40\n[75] MLOAD\n[76] DUP1\n[77] SWAP2\n[78] SUB\n[79] SWAP1\n[80] RETURN\n[81] JUMPDEST\n[82] PUSH 0x009C\n[83] PUSH 0x04\n[84] DUP1\n[85] CALLDATASIZE\n[86] SUB\n[87] DUP2\n[88] ADD\n[89] SWAP1\n[90] PUSH 0x0097\n[91] SWAP2\n[92] SWAP1\n[93] PUSH 0x011F\n[94] JUMP\n[95] JUMPDEST\n[96] PUSH 0x00B0\n[97] JUMP\n[98] JUMPDEST\n[99] 00 opcode is unknown\n[100] JUMPDEST\n[101] PUSH 0x00\n[102] DUP1\n[103] SLOAD\n[104] SWAP1\n[105] POP\n[106] SWAP1\n[107] JUMP\n[108] JUMPDEST\n[109] PUSH 0x00\n[110] PUSH 0x01\n[111] SWAP1\n[112] POP\n[113] SWAP1\n[114] JUMP\n[115] JUMPDEST\n[116] DUP1\n[117] PUSH 0x00\n[118] DUP2\n[119] SWAP1\n[120] SSTORE\n[121] POP\n[122] POP\n[123] JUMP\n[124] JUMPDEST\n[125] PUSH 0x00\n[126] DUP2\n[127] SWAP1\n[128] POP\n[129] SWAP2\n[130] SWAP1\n[131] POP\n[132] JUMP\n[133] JUMPDEST\n[134] PUSH 0x00CD\n[135] DUP2\n[136] PUSH 0x00BA\n[137] JUMP\n[138] JUMPDEST\n[139] DUP3\n[140] MSTORE\n[141] POP\n[142] POP\n[143] JUMP\n[144] JUMPDEST\n[145] PUSH 0x00\n[146] PUSH 0x20\n[147] DUP3\n[148] ADD\n[149] SWAP1\n[150] POP\n[151] PUSH 0x00E8\n[152] PUSH 0x00\n[153] DUP4\n[154] ADD\n[155] DUP5\n[156] PUSH 0x00C4\n[157] JUMP\n[158] JUMPDEST\n[159] SWAP3\n[160] SWAP2\n[161] POP\n[162] POP\n[163] JUMP\n[164] JUMPDEST\n[165] PUSH 0x00\n[166] DUP1\n[167] REVERT\n[168] JUMPDEST\n[169] PUSH 0x00FC\n[170] DUP2\n[171] PUSH 0x00BA\n[172] JUMP\n[173] JUMPDEST\n[174] DUP2\n[175] EQ\n[176] PUSH 0x0107\n[177] JUMPI\n[178] PUSH 0x00\n[179] DUP1\n[180] REVERT\n[181] JUMPDEST\n[182] POP\n[183] JUMP\n[184] JUMPDEST\n[185] PUSH 0x00\n[186] DUP2\n[187] CALLDATALOAD\n[188] SWAP1\n[189] POP\n[190] PUSH 0x0119\n[191] DUP2\n[192] PUSH 0x00F3\n[193] JUMP\n[194] JUMPDEST\n[195] SWAP3\n[196] SWAP2\n[197] POP\n[198] POP\n[199] JUMP\n[200] JUMPDEST\n[201] PUSH 0x00\n[202] PUSH 0x20\n[203] DUP3\n[204] DUP5\n[205] SUB\n[206] SLT\n[207] ISZERO\n[208] PUSH 0x0135\n[209] JUMPI\n[210] PUSH 0x0134\n[211] PUSH 0x00EE\n[212] JUMP\n[213] JUMPDEST\n[214] JUMPDEST\n[215] PUSH 0x00\n[216] PUSH 0x0143\n[217] DUP5\n[218] DUP3\n[219] DUP6\n[220] ADD\n[221] PUSH 0x010A\n[222] JUMP\n[223] JUMPDEST\n[224] SWAP2\n[225] POP\n[226] POP\n[227] SWAP3\n[228] SWAP2\n[229] POP\n[230] POP\n[231] JUMP\n[232] INVALID\n[233] LOG2\n[234] PUSH 0x6970667358\n[235] 22 opcode is unknown\n[236] SLT\n[237] SHA3\n[238] C7 opcode is unknown\n[239] E6 opcode is unknown\n[240] BB opcode is unknown\n[241] PUSH 0x1A269403A5D8DE3BF85B738E5905FBFB7BDA8BBA76C64F\n[242] ADDRESS\n[243] ORIGIN\n[244] DUP10\n[245] 0D opcode is unknown\n[246] EF opcode is unknown\n[247] PUSH 0x736F6C6343\n[248] 00 opcode is unknown\n[249] ADDMOD\n[250] 0D opcode is unknown\n[251] 00 opcode is unknown\n[252] CALLER\n"

  setup_all do
    contract = EthClient.deploy(@bin, @abi)
    {:ok, contract: contract}
  end

  describe "Contract opcodes" do
    @tag bin: @bin, abi: @abi
    test "[SUCCESS] Decompiling a contract retrieves the opcodes", %{} do
      assert CaptureIO.with_io(fn -> EthClient.Contract.to_opcodes() end) ==
               {:ok, @opcodes}
    end

    @tag bin: @bin, abi: @abi
    test "[SUCCESS] Decompiling a non-existent contract retrieves raises a Match Error", %{} do
      assert_raise MatchError, fn ->
        EthClient.Contract.contract_to_opcodes!("0xffffffffffffffffffffffffffffffffffffffff")
      end
    end
  end
end
