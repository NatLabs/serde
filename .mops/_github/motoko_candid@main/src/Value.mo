import Array "mo:base/Array";
import FloatX "mo:xtendedNumbers/FloatX";
import InternalTypes "InternalTypes";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Tag "./Tag";
import TransparencyState "./TransparencyState";

module {
  type Tag = Tag.Tag;
  type TransparencyState<T> = TransparencyState.TransparencyState<T>;

  public type RecordFieldValue = {
    tag: Tag;
    value: Value;
  };

  public type Func = {
    service : TransparencyState<Principal>;
    method : Text;
  };

  public type VariantOptionValue = RecordFieldValue;

  public type Value = {
    #Int : Int;
    #Int8 : Int8;
    #Int16 : Int16;
    #Int32 : Int32;
    #Int64 : Int64;
    #Nat : Nat;
    #Nat8 : Nat8;
    #Nat16 : Nat16;
    #Nat32 : Nat32;
    #Nat64 : Nat64;
    #Null;
    #Bool : Bool;
    #Float32 : Float;
    #Float64 : Float;
    #Text : Text;
    #Reserved;
    #Empty;
    #Option : ?Value;
    #Vector : [Value];
    #Record : [RecordFieldValue];
    #Variant : VariantOptionValue;
    #Func : TransparencyState<Func>;
    #Service : TransparencyState<Principal>;
    #Principal : TransparencyState<Principal>;
  };

  public func equal(v1: Value, v2: Value): Bool {
    switch (v1) {
      case (#Float32(f1)) {
        let f2 = switch (v2) {
          case(#Float32(f2)) f2;
          case(#Float64(f2)) f2;
          case (_) return false;
        };
        FloatX.nearlyEqual(f1, f2, 0.0000001, 0.000001);
      };
      case (#Float64(f1)) {
        let f2 = switch (v2) {
          case(#Float32(f2)) f2;
          case(#Float64(f2)) f2;
          case (_) return false;
        };
        FloatX.nearlyEqual(f1, f2, 0.0000001, 0.000001);
      };
      case (#Option(o1)) {
        let o2 = switch (v2) {
          case(#Option(o2)) o2;
          case (_) return false;
        };
        switch (o1) {
          case (null) return o2 == null;
          case (?o1) {
            switch(o2) {
              case (null) return false;
              case (?o2) equal(o1, o2);
            }
          }
        };
      };
      case (#Vector(ve1)) {
        let ve2 = switch (v2) {
          case(#Vector(ve)) ve;
          case (_) return false;
        };
        InternalTypes.arraysAreEqual(
          ve1,
          ve2,
          null, // Dont reorder
          equal
        );
      };
      case (#Record(r1)) {
        let r2 = switch (v2) {
          case(#Record(r2)) r2;
          case (_) return false;
        };

        InternalTypes.arraysAreEqual(
          r1,
          r2,
          ?(func (t1: RecordFieldValue, t2: RecordFieldValue) : Order.Order {
            Tag.compare(t1.tag, t2.tag)
          }),
          func (t1: RecordFieldValue, t2: RecordFieldValue) : Bool {
            if (not Tag.equal(t1.tag, t2.tag)) {
              return false;
            };
            equal(t1.value, t2.value);
          }
        );
      };
      case (#Variant(va1)) {
        let va2 = switch (v2) {
          case(#Variant(va2)) va2;
          case (_) return false;
        };
        if (not Tag.equal(va1.tag, va2.tag)) {
          return false;
        };
        if (not equal(va1.value, va2.value)) {
          return false;
        };
        true;
      };
      case (#Func(f1)) {
        let f2 = switch (v2) {
          case(#Func(f2)) f2;
          case (_) return false;
        };
        switch (f1){
          case (#opaque) f2 == #opaque;
          case (#transparent(t1)) {
            switch (f2) {
              case (#opaque) false;
              case (#transparent(t2)) {
                if (t1.method != t2.method) {
                  false;
                } else {
                  t1.service == t2.service
                }
              };
            }
          }
        }
      };
      case (#Service(s1)) {
        let s2 = switch (v2) {
          case(#Service(s2)) s2;
          case (_) return false;
        };
        s1 == s2
      };
      case (a) a == v2;
    };
  };
}