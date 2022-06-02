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

// ping sends a ping message to the given node and waits for a reply.
// func (t *UDPv4) ping(n *enode.Node) (seq uint64, err error) {
// 	rm := t.sendPing(n.ID(), &net.UDPAddr{IP: n.IP(), Port: n.UDP()}, nil)
// 	if err = <-rm.errc; err == nil {
// 		seq = rm.reply.(*v4wire.Pong).ENRSeq
// 	}
// 	return seq, err
// }

// func (t *UDPv4) sendPing(toid enode.ID, toaddr *net.UDPAddr, callback func()) *replyMatcher {
// 	req := t.makePing(toaddr)
// 	packet, hash, err := v4wire.Encode(t.priv, req)
// 	if err != nil {
// 		errc := make(chan error, 1)
// 		errc <- err
// 		return &replyMatcher{errc: errc}
// 	}
// 	// Add a matcher for the reply to the pending reply queue. Pongs are matched if they
// 	// reference the ping we're about to send.
// 	rm := t.pending(toid, toaddr.IP, v4wire.PongPacket, func(p v4wire.Packet) (matched bool, requestDone bool) {
// 		matched = bytes.Equal(p.(*v4wire.Pong).ReplyTok, hash)
// 		if matched && callback != nil {
// 			callback()
// 		}
// 		return matched, matched
// 	})
// 	// Send the packet.
// 	t.localNode.UDPContact(toaddr)
// 	t.write(toaddr, toid, req.Name(), packet)
// 	return rm
// }

// func (t *UDPv4) makePing(toaddr *net.UDPAddr) *v4wire.Ping {
// 	return &v4wire.Ping{
// 		Version:    4,
// 		From:       t.ourEndpoint(),
// 		To:         v4wire.NewEndpoint(toaddr, 0),
// 		Expiration: uint64(time.Now().Add(expiration).Unix()),
// 		ENRSeq:     t.localNode.Node().Seq(),
// 	}
// }
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
        let mut body = self.encode_body();
        let mut header = self.encode_header(&body, private_key);
        header.append(&mut body);
        header
    }

    fn encode_body(&self) -> Vec<u8> {
        let mut s = RlpStream::new();
        s.begin_unbounded_list();
        s.append(&self.version);
        s.append(&self.from.address);
        s.append(&self.from.udp_port);
        s.append(&self.from.tcp_port);
        s.append(&self.to.address);
        s.append(&self.to.udp_port);
        s.append(&self.to.tcp_port);
        s.append(&self.expiration);
        s.finalize_unbounded_list();
        s.out().to_vec()
    }

    fn encode_header(&self,body: &Vec<u8>, private_key: &H256) -> Vec<u8> {
        let hash_body = keccak256_hash(&body);
        let mut sign = self.sign(hash_body, private_key);
        sign.append(&mut body.clone());
        let mut sig_body_hash = keccak256_hash(&sign);
        sig_body_hash.append(&mut sign);
        sig_body_hash
    }

    fn sign(&self, hash_body: Vec<u8>, private_key: &H256) -> Vec<u8> {
        let signed_body = ecdsa_sign(&hash_body, &private_key.0);
        let mut sign = RlpStream::new();
        sign.begin_unbounded_list();
        sign.append(&signed_body.v);
        sign.append(&signed_body.r);
        sign.append(&signed_body.s);
        sign.finalize_unbounded_list();
        sign.out().to_vec()
    }
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

