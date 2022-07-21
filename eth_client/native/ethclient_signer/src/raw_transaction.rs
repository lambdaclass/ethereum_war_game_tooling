extern crate ethereum_types;
extern crate num_traits;
extern crate rlp;
extern crate secp256k1;
extern crate serde;
extern crate serde_json;
extern crate tiny_keccak;

use ethereum_types::{H160, H256, U256};
use rlp::{RlpStream};
use secp256k1::{key::SecretKey, Message, Secp256k1};
use serde_derive::{Deserialize, Serialize};
use tiny_keccak::{Hasher, Keccak};
use rlp_derive::{RlpEncodable, RlpDecodable, RlpDecodableWrapper, RlpEncodableWrapper};

#[derive(
    Debug,
    Clone,
    PartialEq,
    Deserialize,
    Serialize,
    RlpDecodable,
    RlpEncodable,
)]
pub struct AccessListItem {
    /// Accessed address
    pub address: H160,
    /// Accessed storage keys
    pub storage_keys: Vec<H256>,
}

#[derive(
    Debug,
    Clone,
    PartialEq,
    Deserialize,
    Serialize,
    RlpEncodableWrapper,
    RlpDecodableWrapper,
    Default
)]
pub struct AccessList(pub Vec<AccessListItem>);

/// Description of a Transaction, pending or in the chain.
#[derive(Debug, Default, Clone, PartialEq, Deserialize, Serialize, RlpEncodable, RlpDecodable)]
pub struct RawTransaction {
    /// Chain Id
    pub chain_id: u64,
    /// Nonce
    pub nonce: U256,
    pub max_priority_fee_per_gas: U256,
    pub max_fee_per_gas: U256,
    /// Recipient (None when contract creation)
    pub gas: U256,
    pub to: Option<H160>,
    /// Transferred value
    pub value: U256,
    /// Gas amount
    /// Input data
    pub data: Vec<u8>,
    pub access_list: Option<AccessList>
}

impl RawTransaction {
    pub fn sign(&self, private_key: &H256, transaction_type: u8) -> Vec<u8> {
        let hash = self.hash(transaction_type);
        let sig = ecdsa_sign(&hash, &private_key.0, self.chain_id);
        let mut r_n = sig.r;
        let mut s_n = sig.s;
        while r_n[0] == 0 {
            r_n.remove(0);
        }
        while s_n[0] == 0 {
            s_n.remove(0);
        }
        let mut tx = RlpStream::new();
        tx.begin_unbounded_list();
        self.encode(&mut tx);
        tx.append(&sig.v);
        tx.append(&r_n);
        tx.append(&s_n);
        tx.finalize_unbounded_list();
        tx.out().to_vec()
    }

    pub fn hash(&self, transaction_type: u8) -> Vec<u8> {
        let mut encoded_tx = RlpStream::new();
        encoded_tx.begin_unbounded_list();
        self.encode(&mut encoded_tx);
        encoded_tx.finalize_unbounded_list();
        let mut encoded_tx_raw = encoded_tx.as_raw().to_vec();
        let mut to_hash = vec![transaction_type];

        to_hash.append(&mut encoded_tx_raw);
        keccak256_hash(&to_hash)
    }

    pub fn encode(&self, s: &mut RlpStream) {
        s.append(&self.chain_id);
        s.append(&self.nonce);
        s.append(&self.max_priority_fee_per_gas);
        s.append(&self.max_fee_per_gas);
        s.append(&self.gas);
        if let Some(ref t) = self.to {
            s.append(t);
        } else {
            s.append(&vec![]);
        }
        s.append(&self.value);
        s.append(&self.data);
        if let Some(ref t) = self.access_list {
            s.append(t);
        } else {
            s.append_list::<AccessList, AccessList>(&vec![]);
        }
    }
}

fn keccak256_hash(bytes: &[u8]) -> Vec<u8> {
    let mut hasher = Keccak::v256();
    hasher.update(bytes);
    let mut resp: [u8; 32] = Default::default();
    hasher.finalize(&mut resp);
    resp.iter().cloned().collect()
}

fn ecdsa_sign(hash: &[u8], private_key: &[u8], chain_id: u64) -> EcdsaSig {
    let s = Secp256k1::signing_only();
    let msg = Message::from_slice(hash).unwrap();
    let key = SecretKey::from_slice(private_key).unwrap();
    let (v, sig_bytes) = s.sign_recoverable(&msg, &key).serialize_compact();

    let v_normalized = if v.to_i32() > 1 {
        (v.to_i32() as u64) - chain_id * 2 - 35
    } else {
        v.to_i32() as u64
    };

    EcdsaSig {
        v: v_normalized,
        r: sig_bytes[0..32].to_vec(),
        s: sig_bytes[32..64].to_vec(),
    }
}

pub struct EcdsaSig {
    pub v: u64,
    pub r: Vec<u8>,
    pub s: Vec<u8>,
}
