import Order "mo:base/Order";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import NatX "mo:xtendedNumbers/NatX";

module {
  public type Tag = {
    #name : Text;
    #hash : Nat32;
  };

  public func hashName(name : Text) : Nat32 {
    // hash(name) = ( Sum_(i=0..k) utf8(name)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(name)|-1
    let bytes : [Nat8] = Blob.toArray(Text.encodeUtf8(name));
    Array.foldLeft<Nat8, Nat32>(bytes, 0, func (accum: Nat32, byte : Nat8) : Nat32 {
      (accum *% 223) +% NatX.from8To32(byte);
    });
  };

  public func hash(t : Tag) : Nat32 {
    switch (t) {
      case (#name(n)) hashName(n);
      case (#hash(h)) h;
    };
  };

  public func equal(t1: Tag, t2: Tag) : Bool {
    compare(t1, t2) == #equal;
  };

  public func compare(t1: Tag, t2: Tag) : Order.Order {
    Nat32.compare(hash(t1), hash(t2));
  };
}