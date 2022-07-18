mod raw_transaction;
use ethereum_types::{H160, H256, U256};
use raw_transaction::RawTransaction;
use rlp::Rlp;

/// Signs an ethereum payload. This library assumes that the provided payload string
/// is the RLP encoding of the following list:
/// [nonce, gas_price, gas_limit, recipient, value, data, chain_id].
/// The returned signed payload is ready to immediately broadcast to the
/// corresponding chain.
#[rustler::nif]
pub fn sign_transaction(payload_str: String, private_key: String, transaction_type: u8) -> String {
    let payload = hex::decode(payload_str).unwrap();
    let rlp = Rlp::new(&payload);
    let mut iter = rlp.iter();
    let chain_id: U256 = iter.next().unwrap().as_val().unwrap();
    let nonce: U256 = iter.next().unwrap().as_val().unwrap();
    let max_priority_fee_per_gas: U256 = iter.next().unwrap().as_val().unwrap();
    let max_fee_per_gas: U256 = iter.next().unwrap().as_val().unwrap();
    let gas_limit: U256 = iter.next().unwrap().as_val().unwrap();
    let to_iter = iter.next().unwrap();
    let mut to: Option<H160> = None;
    if false == to_iter.is_empty() {
        let to_val: H160 = to_iter.as_val().unwrap();
        to = Some(to_val);
    }

    let value: U256 = iter.next().unwrap().as_val().unwrap();
    let data: Vec<u8> = iter.next().unwrap().as_val().unwrap();
    let access_list_iter = iter.next().unwrap();
    let mut access_list: Option<Vec<u8>> = None;
    if false == access_list_iter.is_empty() {
        let access_list_val: Vec<u8> = access_list_iter.as_val().unwrap();
        access_list = Some(access_list_val);
    }

    println!("chain_id: {} nonce: {} max_priority_fee_per_gas: {} max_fee_per_gas: {} gas_limit: {} to: {:?} amount: {} access_list: {:?}", chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, to, value, access_list);

    let mut pkey_data: [u8; 32] = Default::default();
    pkey_data.copy_from_slice(&hex::decode(private_key).unwrap());
    let pkey = H256(pkey_data);
    let tx = RawTransaction {
        nonce: nonce,
        to: to,
        value: value,
        max_priority_fee_per_gas: max_priority_fee_per_gas,
        max_fee_per_gas: max_fee_per_gas,
        gas: gas_limit,
        data: data,
        access_list: access_list,
        chain_id: chain_id
    };

    let transaction_prefix = String::from("0x").to_owned();
    let mut signature = tx.sign(&pkey, transaction_type);
    let mut transaction_payload = vec![transaction_type];
    transaction_payload.append(&mut signature);

    return transaction_prefix + &hex::encode(transaction_payload);
}

rustler::init!("Elixir.EthClient", [sign_transaction]);
