import Array "mo:base/Array";
import FuncMode "./FuncMode";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import InternalTypes "./InternalTypes";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Tag "./Tag";
import Text "mo:base/Text";
import TypeCode "./TypeCode";
import Util "InternalTypes";

module {
  public type FuncType = {
    modes : [FuncMode.FuncMode];
    argTypes : [Type];
    returnTypes : [Type];
  };

  public type RecordFieldType = {
    tag : Tag.Tag;
    _type : Type;
  };

  public type VariantOptionType = RecordFieldType;

  public type ServiceType = {
    methods : [(Text, FuncType)];
  };

  public type PrimitiveType = {
    #Int;
    #Int8;
    #Int16;
    #Int32;
    #Int64;
    #Nat;
    #Nat8;
    #Nat16;
    #Nat32;
    #Nat64;
    #Null;
    #Bool;
    #Float32;
    #Float64;
    #Text;
    #Reserved;
    #Empty;
    #Principal;
  };

  public type CompoundType = {
    #Option : Type;
    #Vector : Type;
    #Record : [RecordFieldType];
   #Variant : [VariantOptionType];
    #Func : FuncType;
    #Service : ServiceType;
    #recursiveType : { id : Text; _type : CompoundType };
    #recursiveReference : Text;
  };

  public type Type = CompoundType or PrimitiveType;

  public func equal(v1 : Type, v2 : Type) : Bool {
    switch (v1) {
      case (#Option(o1)) {
        let o2 = switch (v2) {
          case (#Option(o2)) o2;
          case (_) return false;
        };
        equal(o1, o2);
      };
      case (#Vector(ve1)) {
        let ve2 = switch (v2) {
          case (#Vector(ve)) ve;
          case (_) return false;
        };
        equal(ve1, ve2);
      };
      case (#Record(r1)) {
        let r2 = switch (v2) {
          case (#Record(r2)) r2;
          case (_) return false;
        };

        InternalTypes.arraysAreEqual(
          r1,
          r2,
          ?(
            func(t1 : RecordFieldType, t2 : RecordFieldType) : Order.Order {
              Tag.compare(t1.tag, t2.tag);
            },
          ),
          func(t1 : RecordFieldType, t2 : RecordFieldType) : Bool {
            if (not Tag.equal(t1.tag, t2.tag)) {
              return false;
            };
            equal(t1._type, t2._type);
          },
        );
      };
      case (#Variant(va1)) {
        let va2 = switch (v2) {
          case (#Variant(va2)) va2;
          case (_) return false;
        };
        InternalTypes.arraysAreEqual(
          va1,
          va2,
          ?(
            func(t1 : VariantOptionType, t2 : VariantOptionType) : Order.Order {
              Tag.compare(t1.tag, t2.tag);
            },
          ),
          func(t1 : VariantOptionType, t2 : VariantOptionType) : Bool {
            if (not Tag.equal(t1.tag, t2.tag)) {
              return false;
            };
            equal(t1._type, t2._type);
          },
        );
      };
      case (#Func(f1)) {
        let f2 = switch (v2) {
          case (#Func(f2)) f2;
          case (_) return false;
        };

        // Mode Types
        let getModeValue = func(m : FuncMode.FuncMode) : Nat {
          switch (m) {
            case (#oneWay) 2;
            case (#_query) 1;
          };
        };
        let modesAreEqual = InternalTypes.arraysAreEqual(
          f1.modes,
          f2.modes,
          ?(
            func(m1 : FuncMode.FuncMode, m2 : FuncMode.FuncMode) : Order.Order {
              let mv1 : Nat = getModeValue(m1);
              let mv2 : Nat = getModeValue(m2);
              Nat.compare(mv1, mv2);
            },
          ),
          func(m1 : FuncMode.FuncMode, m2 : FuncMode.FuncMode) : Bool {
            m1 == m2;
          },
        );
        if (not modesAreEqual) {
          return false;
        };
        // Arg Types
        let argTypesAreEqual = InternalTypes.arraysAreEqual(
          f1.argTypes,
          f2.argTypes,
          null, // Dont reorder
          equal,
        );
        if (not argTypesAreEqual) {
          return false;
        };
        // Return types
        InternalTypes.arraysAreEqual(
          f1.returnTypes,
          f2.returnTypes,
          null, // Dont reorder
          equal,
        );
      };
      case (#Service(s1)) {
        let s2 = switch (v2) {
          case (#Service(s2)) s2;
          case (_) return false;
        };
        Util.arraysAreEqual(
          s1.methods,
          s2.methods,
          ?(
            func(t1 : (Text, FuncType), t2 : (Text, FuncType)) : Order.Order {
              Text.compare(t1.0, t2.0);
            },
          ),
          func(t1 : (Text, FuncType), t2 : (Text, FuncType)) : Bool {
            if (t1.0 != t1.0) {
              false;
            } else {
              equal(#Func(t1.1), #Func(t2.1));
            };
          },
        );
      };
      case (#recursiveType(r1)) {
        let r2 = switch (v2) {
          case (#recursiveType(r2)) r2;
          case (_) return false;
        };
        equal(r1._type, r2._type);
      };
      case (#recursiveReference(r1)) {
        let r2 = switch (v2) {
          case (#recursiveReference(r2)) r2;
          case (_) return false;
        };
        true;
      };
      case (a) a == v2;
    };
  };

  public func hash(t : Type) : Hash.Hash {
    switch (t) {
      case (#Option(o)) {
        let h = hashTypeCode(TypeCode.opt);
        let innerHash = hash(o);
        combineHash(h, innerHash);
      };
      case (#Vector(v)) {
        let h = hashTypeCode(TypeCode.vector);
        let innerHash = hash(v);
        combineHash(h, innerHash);
      };
      case (#Record(r)) {
        let h = hashTypeCode(TypeCode.record);
        Array.foldLeft<RecordFieldType, Hash.Hash>(
          r,
          h,
          func(v : Hash.Hash, f : RecordFieldType) : Hash.Hash {
            let innerHash = hash(f._type);
            combineHash(combineHash(v, Tag.hash(f.tag)), innerHash);
          },
        );
      };
      case (#Func(f)) {
        let h = hashTypeCode(TypeCode._func);
        let h2 = Array.foldLeft<Type, Hash.Hash>(
          f.argTypes,
          h,
          func(v : Hash.Hash, f : Type) : Hash.Hash {
            combineHash(v, hash(f));
          },
        );
        let h3 = Array.foldLeft<Type, Hash.Hash>(
          f.returnTypes,
          h2,
          func(v : Hash.Hash, f : Type) : Hash.Hash {
            combineHash(v, hash(f));
          },
        );
        Array.foldLeft<FuncMode.FuncMode, Hash.Hash>(
          f.modes,
          h3,
          func(v : Hash.Hash, f : FuncMode.FuncMode) : Hash.Hash {
            combineHash(
              v,
              switch (f) {
                case (#_query) 1;
                case (#oneWay) 2;
              },
            );
          },
        );
      };
      case (#Service(s)) {
        let h = hashTypeCode(TypeCode.service);
        Array.foldLeft<(Text, FuncType), Hash.Hash>(
          s.methods,
          h,
          func(v : Hash.Hash, f : (Text, FuncType)) : Hash.Hash {
            combineHash(h, combineHash(Text.hash(f.0), hash(#Func(f.1))));
          },
        );
      };
      case (#Variant(v)) {
        var h = hashTypeCode(TypeCode.variant);
        Array.foldLeft<VariantOptionType, Hash.Hash>(
          v,
          0,
          func(h : Hash.Hash, o : VariantOptionType) : Hash.Hash {
            let innerHash = hash(o._type);
            combineHash(combineHash(h, Tag.hash(o.tag)), innerHash);
          },
        );
      };
      case (#recursiveType(rT)) {
        hash(rT._type);
      };
      case (#recursiveReference(r)) {
        Text.hash(r);
      };
      case (#Int) hashTypeCode(TypeCode.int);
      case (#Int8) hashTypeCode(TypeCode.int8);
      case (#Int16) hashTypeCode(TypeCode.int16);
      case (#Int32) hashTypeCode(TypeCode.int32);
      case (#Int64) hashTypeCode(TypeCode.int64);
      case (#Nat) hashTypeCode(TypeCode.nat);
      case (#Nat8) hashTypeCode(TypeCode.nat8);
      case (#Nat16) hashTypeCode(TypeCode.nat16);
      case (#Nat32) hashTypeCode(TypeCode.nat32);
      case (#Nat64) hashTypeCode(TypeCode.nat64);
      case (#Null) hashTypeCode(TypeCode._null);
      case (#Bool) hashTypeCode(TypeCode.bool);
      case (#Float32) hashTypeCode(TypeCode.float32);
      case (#Float64) hashTypeCode(TypeCode.float64);
      case (#Text) hashTypeCode(TypeCode.text);
      case (#Reserved) hashTypeCode(TypeCode.reserved);
      case (#Empty) hashTypeCode(TypeCode.empty);
      case (#Principal) hashTypeCode(TypeCode.principal);
    };
  };

  private func hashTypeCode(i : Int) : Hash.Hash {
    Nat32.fromNat(Int.abs(i));
  };

  private func combineHash(seed : Hash.Hash, value : Hash.Hash) : Hash.Hash {
    // From `C++ Boost Hash Combine`
    seed ^ (value +% 0x9e3779b9 +% (seed << 6) +% (seed >> 2));
  };

};
