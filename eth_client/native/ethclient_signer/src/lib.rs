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
pub fn sign_transaction(payload_str: String, private_key: String) -> String {
    let payload = hex::decode(payload_str).unwrap();
    let rlp = Rlp::new(&payload);
    let mut iter = rlp.iter();
    let nonce: U256 = iter.next().unwrap().as_val().unwrap();
    let price: U256 = iter.next().unwrap().as_val().unwrap();
    let gas: U256 = iter.next().unwrap().as_val().unwrap();
    let to_iter = iter.next().unwrap();
    let mut to: Option<H160> = None;
    if false == to_iter.is_empty() {
        let to_val: H160 = to_iter.as_val().unwrap();
        to = Some(to_val);
    }

    let value: U256 = iter.next().unwrap().as_val().unwrap();
    let data: Vec<u8> = iter.next().unwrap().as_val().unwrap();
    let chain_id: u64 = iter.next().unwrap().as_val().unwrap();

    let mut pkey_data: [u8; 32] = Default::default();
    pkey_data.copy_from_slice(&hex::decode(private_key).unwrap());
    let pkey = H256(pkey_data);
    let tx = RawTransaction {
        to: to,
        nonce: nonce,
        value: value,
        gas: gas,
        gas_price: price,
        data: data,
    };

    let transaction_prefix = String::from("0x").to_owned();
    let signed_payload = hex::encode(tx.sign(&pkey, &chain_id));

    return transaction_prefix + &signed_payload;
}

rustler::init!("Elixir.EthClient", [sign_transaction]);
