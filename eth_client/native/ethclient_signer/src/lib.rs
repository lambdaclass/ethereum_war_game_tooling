mod raw_transaction;
mod raw_ping_packet;
use ethereum_types::{H160, H256, U256};
use raw_transaction::RawTransaction;
use raw_ping_packet::{RawPingPacket,Endpoint};
use rlp::Rlp;
use std::net::{UdpSocket, Ipv4Addr};
use std::time::{SystemTime, Duration};
use secp256k1::{key::SecretKey, Message, Secp256k1};
use tiny_keccak::{Hasher, Keccak};

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

fn expiration() -> u64 {
    let time = SystemTime::now().checked_add(Duration::from_secs(20)).unwrap().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs();
    return time;
}

fn from_endpoint() -> Endpoint {
    let from_addr = Ipv4Addr::new(127, 0, 0, 1);
    let from_addr_u32: u32 = from_addr.into();
    Endpoint{address: from_addr_u32, udp_port: 30302, tcp_port: 0}
}

fn to_endpoint() -> Endpoint {
    let to_addr = Ipv4Addr::new(127, 0, 0, 1);
    let to_addr_u32: u32 = to_addr.into();
    Endpoint{address: to_addr_u32, udp_port: 30303, tcp_port: 30303}
}

fn get_priv_key() -> H256{
    let mut pkey_data: [u8; 32] = Default::default();
    pkey_data.copy_from_slice(&hex::decode("e90d75baafee04b3d9941bd8d76abe799b391aec596515dee11a9bd55f05709c".to_string()).unwrap());
    H256(pkey_data)
}

#[rustler::nif]
pub fn send_ping() -> Vec<u8> {
    let pkey = get_priv_key();

    let raw_ping = RawPingPacket {
        version: 4,
        from: from_endpoint(),
        to: to_endpoint(),
        expiration: expiration()
    };

    let encoded_packet = raw_ping.encode_packet(&pkey);
    

    let socket = UdpSocket::bind("127.0.0.1:30302").expect("couldn't bind to address");
    socket.send_to(&encoded_packet, "127.0.0.1:30303").expect("couldn't send data");
    // let mut buf = [0; 1000];
    // let (number_of_bytes, src_addr) = socket.recv_from(&mut buf).expect("Didn't receive data");
    // println!("{}", number_of_bytes);
    encoded_packet
}

#[rustler::nif]
pub fn sign_raw_bytes(raw_bytes: Vec<u8>, private_key: String) -> Vec<u8> {
    let mut pkey_data: [u8; 32] = Default::default();
    pkey_data.copy_from_slice(&hex::decode(private_key).unwrap());
    ecdsa_sign(&raw_bytes, &pkey_data)
}

fn ecdsa_sign(payload: &[u8], private_key: &[u8]) -> Vec<u8> {
    let s = Secp256k1::signing_only();
    let hashed = keccak256_hash(payload);
    let msg = Message::from_slice(&hashed).unwrap();
    let key = SecretKey::from_slice(private_key).unwrap();
    let (v, sig_bytes) = s.sign_recoverable(&msg, &key).serialize_compact();

    let mut r = sig_bytes[0..32].to_vec();
    let mut s = sig_bytes[32..64].to_vec();
    let mut ret : Vec<u8> = vec![];
    ret.append(&mut r);
    ret.append(&mut s);
    ret.push(v.to_i32() as u8);

    ret
}

fn keccak256_hash(bytes: &[u8]) -> Vec<u8> {
    let mut hasher = Keccak::v256();
    hasher.update(bytes);
    let mut resp: [u8; 32] = Default::default();
    hasher.finalize(&mut resp);
    resp.iter().cloned().collect()
}

rustler::init!("Elixir.EthClient", [sign_transaction, sign_raw_bytes, send_ping]);
