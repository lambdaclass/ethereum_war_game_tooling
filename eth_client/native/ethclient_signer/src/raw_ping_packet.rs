extern crate ethereum_types;
extern crate num_traits;
extern crate rlp;
extern crate secp256k1;
extern crate serde;
extern crate serde_json;
extern crate tiny_keccak;

use ethereum_types::H256;
use rlp::RlpStream;
use secp256k1::{key::SecretKey, Message, Secp256k1};
use serde_derive::{Deserialize, Serialize};
use tiny_keccak::{Hasher, Keccak};

const PING: u8 = 1;

#[derive(Debug, Default, Clone, PartialEq, Deserialize, Serialize)]
pub struct RawPingPacket {
    pub version: u8,
    pub from: Endpoint,
    pub to: Endpoint,
    pub expiration: u64
}

#[derive(Debug, Default, Clone, PartialEq, Deserialize, Serialize)]
pub struct Endpoint {
    pub address: u32, 
    pub udp_port: u16, 
    pub tcp_port: u16, 
}



// 0 | 32 | 32+65 |  
// hash(sign + body) | firma(body) | body
impl RawPingPacket {
    pub fn encode_packet(&self, private_key: &H256) -> Vec<u8> {
        let mut encoded_body = encode_body(self);
        let mut signed_body = sign_body(&mut encoded_body, private_key);
        let mut packet = build_hash(&mut encoded_body.clone(),&mut signed_body.clone());   
        packet.append(&mut signed_body);
        packet.append(&mut encoded_body);
        packet
    }
}   


fn encode_body(raw_packet: &RawPingPacket) -> Vec<u8> {
    let mut s = RlpStream::new();
    s.begin_unbounded_list();
    s.append(&raw_packet.version);
    let mut s1 = RlpStream::new();
    s1.begin_unbounded_list();
    s1.append(&raw_packet.from.address);
    s1.append(&raw_packet.from.udp_port);
    s1.append(&raw_packet.from.tcp_port);
    s1.finalize_unbounded_list();
    s.append(&s1.out().to_vec());
    let mut s2 = RlpStream::new();
    s2.begin_unbounded_list();
    s2.append(&raw_packet.to.address);
    s2.append(&raw_packet.to.udp_port);
    s2.append(&raw_packet.to.tcp_port);
    s2.finalize_unbounded_list();
    s.append(&s2.out().to_vec());
    s.append(&raw_packet.expiration);
    s.finalize_unbounded_list();
    let mut body = s.out().to_vec();
    body.insert(0, PING);
    body
}

fn sign_body(encoded_body: &mut Vec<u8>, private_key:  &H256) -> Vec<u8> {
    let hash_body = keccak256_hash(&encoded_body);
    let mut signed_body = ecdsa_sign(&hash_body, &private_key.0);
    let mut vec: Vec<u8> = Vec::new();
    let v = signed_body.v as u8;
    vec.append(&mut signed_body.r);
    vec.append(&mut signed_body.s);
    vec.push(v);
    vec
}

fn build_hash(encoded_body: &mut Vec<u8>, signed_body: &mut Vec<u8>) -> Vec<u8>  {
    signed_body.append(encoded_body);
    keccak256_hash(&signed_body)
}

pub struct EcdsaSig {
    pub v: u64,
    pub r: Vec<u8>,
    pub s: Vec<u8>,
}

fn keccak256_hash(bytes: &[u8]) -> Vec<u8> {
    let mut hasher = Keccak::v256();
    hasher.update(bytes);
    let mut resp: [u8; 32] = Default::default();
    hasher.finalize(&mut resp);
    resp.iter().cloned().collect()
}

fn ecdsa_sign(hash: &[u8], private_key: &[u8]) -> EcdsaSig {
    let s = Secp256k1::signing_only();
    let msg = Message::from_slice(hash).unwrap();
    let key = SecretKey::from_slice(private_key).unwrap();
    let (v, sig_bytes) = s.sign_recoverable(&msg, &key).serialize_compact();
    EcdsaSig {
        v: v.to_i32() as u64,
        r: sig_bytes[0..32].to_vec(),
        s: sig_bytes[32..64].to_vec(),
    }
}
