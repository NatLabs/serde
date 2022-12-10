import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import FloatX "mo:xtendedNumbers/FloatX";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import IntX "mo:xtendedNumbers/IntX";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import NatX "mo:xtendedNumbers/NatX";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Value "./Value";
import Type "./Type";
import Tag "./Tag";
import InternalTypes "./InternalTypes";
import TransparencyState "./TransparencyState";
import FuncMode "./FuncMode";
import TypeCode "./TypeCode";
import Arg "./Arg";

module {

  type Tag = Tag.Tag;
  type RecordFieldValue = Value.RecordFieldValue;
  type PrimitiveType = Type.PrimitiveType;
  type CompoundType = Type.CompoundType;
  type RecordFieldType = Type.RecordFieldType;
  type VariantOptionType = Type.VariantOptionType;
  type ReferenceType = InternalTypes.ReferenceType;
  type ShallowCompoundType<T> = InternalTypes.ShallowCompoundType<T>;
  type RecordFieldReferenceType<T> = InternalTypes.RecordFieldReferenceType<T>;
  type VariantOptionReferenceType<T> = InternalTypes.VariantOptionReferenceType<T>;


  public func encode(args: [Arg.Arg]) : Blob {
    let buffer = Buffer.Buffer<Nat8>(10);
    encodeToBuffer(buffer, args);
    Blob.fromArray(buffer.toArray());
  };

  public func encodeToBuffer(buffer : Buffer.Buffer<Nat8>, args : [Arg.Arg]) {
    // "DIDL" prefix
    buffer.add(0x44);
    buffer.add(0x49);
    buffer.add(0x44);
    buffer.add(0x4c);

    let argTypes = Buffer.Buffer<Type.Type>(args.size());
    let argValues = Buffer.Buffer<Value.Value>(args.size());
    for (arg in Iter.fromArray(args)) {
      argTypes.add(arg._type);
      argValues.add(arg.value);
    };

    let table : CompoundTypeTable = getTypeInfo(argTypes.toArray());
    encodeTypes(buffer, table); // Encode compound type table + primitive types
    encodeValues(buffer, table, argValues.toArray()); // Encode all the values for the types
  };

  type CompoundTypeTable = {
    compoundTypes : [ShallowCompoundType<ReferenceType>];
    typeCodes : [Int]
  };

  private func encodeTypes(buffer : Buffer.Buffer<Nat8>, table: CompoundTypeTable) {

    NatX.encodeNat(buffer, table.compoundTypes.size(), #unsignedLEB128); // Encode compound type count

    // Encode type table for compound types
    for (t in Iter.fromArray(table.compoundTypes)) {
      encodeType(buffer, t);
    };

    NatX.encodeNat(buffer, table.typeCodes.size(), #unsignedLEB128); // Encode type count
    for (code in Iter.fromArray(table.typeCodes)) {
      IntX.encodeInt(buffer, code, #signedLEB128); // Encode each type
    };
  };

  private func encodeType(buffer : Buffer.Buffer<Nat8>, t : ShallowCompoundType<ReferenceType>) {
    let typeCode : Int = switch(t){
      case (#Option(o)) TypeCode.opt;
      case (#Vector(v)) TypeCode.vector;
      case (#Record(r)) TypeCode.record;
      case (#Func(f)) TypeCode._func;
      case (#Service(s)) TypeCode.service;
      case (#Variant(v)) TypeCode.variant;
    };
    IntX.encodeInt(buffer, typeCode, #signedLEB128); // Encode compound type code
    switch (t) {
      case (#Option(o)) {
        IntX.encodeInt(buffer, o, #signedLEB128); // Encode reference index or type code
      };
      case (#Vector(v)) {
        IntX.encodeInt(buffer, v, #signedLEB128); // Encode reference index or type code
      };
      case (#Record(r)) {
        NatX.encodeNat(buffer, r.size(), #unsignedLEB128); // Encode field count
        for (field in Iter.fromArray(r)) {
          NatX.encodeNat(buffer, Nat32.toNat(Tag.hash(field.tag)), #unsignedLEB128); // Encode field tag
          IntX.encodeInt(buffer, field._type, #signedLEB128); // Encode reference index or type code
        };
      };
      case (#Func(f)) {
        let argCount = f.argTypes.size();
        NatX.encodeNat(buffer, argCount, #unsignedLEB128); // Encode arg count

        for (argType in Iter.fromArray(f.argTypes)) {
          IntX.encodeInt(buffer, argType, #signedLEB128); // Encode each arg
        };

        let returnArgCount = f.returnTypes.size();
        NatX.encodeNat(buffer, returnArgCount, #unsignedLEB128); // Encode return arg count

        for (argType in Iter.fromArray(f.returnTypes)) {
          IntX.encodeInt(buffer, argType, #signedLEB128); // Encode each return arg
        };

        let modeCount = f.modes.size();
        NatX.encodeNat(buffer, modeCount, #unsignedLEB128); // Encode mode count

        for (mode in Iter.fromArray(f.modes)) {
          let value: Int = switch(mode) {
            case (#_query) 1;
            case (#oneWay) 2; 
          };
          IntX.encodeInt(buffer, value, #signedLEB128); // Encode each mode
        };
      };
      case (#Service(s)) {
        NatX.encodeNat(buffer, s.methods.size(), #unsignedLEB128); // Encode method count

        for (method in Iter.fromArray(s.methods)) {
          encodeText(buffer, method.0); // Encode method name
          IntX.encodeInt(buffer, method.1, #signedLEB128); // Encode method type
        }
      };
      case (#Variant(v)) {
        NatX.encodeNat(buffer, v.size(), #unsignedLEB128); // Encode option count
        for (option in Iter.fromArray(v)) {
          NatX.encodeNat(buffer, Nat32.toNat(Tag.hash(option.tag)), #unsignedLEB128); // Encode option tag
          IntX.encodeInt(buffer, option._type, #signedLEB128); // Encode reference index or type code
        };
      };
    };
  };

  type ReferenceOrRecursiveType = {
    #indexOrCode: ReferenceType;
    #recursiveReference: Text;
  };
  type NonRecursiveCompoundType = {
    #Option : Type.Type;
    #Vector : Type.Type;
    #Record : [RecordFieldType];
   #Variant : [VariantOptionType];
    #Func : Type.FuncType;
    #Service : Type.ServiceType;
  };
  
  private func getTypeInfo(args : [Type.Type]) : CompoundTypeTable {
    let shallowTypes = Buffer.Buffer<ShallowCompoundType<ReferenceOrRecursiveType>>(args.size());
    let recursiveTypeIndexMap = TrieMap.TrieMap<Text, Nat>(Text.equal, Text.hash);
    let uniqueTypeMap = TrieMap.TrieMap<NonRecursiveCompoundType, Nat>(Type.equal, Type.hash);

    // Build shallow args and recursive types first, then resolve all recursive references
    let shallowArgs = Buffer.Buffer<ReferenceOrRecursiveType>(args.size());
    for (arg in Iter.fromArray(args)) {
      let t = buildShallowTypes(shallowTypes, recursiveTypeIndexMap, uniqueTypeMap, arg);
      shallowArgs.add(t);
    };
    
    let shallowTypesArray: [ShallowCompoundType<ReferenceOrRecursiveType>]  = shallowTypes.toArray();
    let resolvedCompoundTypes = Buffer.Buffer<ShallowCompoundType<ReferenceType>>(args.size());
    let typeIndexOrCodeList = Buffer.Buffer<Int>(args.size());
    for (sArg in Iter.fromArray(shallowArgs.toArray())) {
      let indexOrCode = resolveArg(sArg, shallowTypesArray, recursiveTypeIndexMap, resolvedCompoundTypes);
      typeIndexOrCodeList.add(indexOrCode);
    };
    {
      compoundTypes = resolvedCompoundTypes.toArray();
      typeCodes = typeIndexOrCodeList.toArray();
    };
  };

  private func resolveArg(
    arg: ReferenceOrRecursiveType,
    shallowTypeArray: [ShallowCompoundType<ReferenceOrRecursiveType>],
    recursiveTypeIndexMap: TrieMap.TrieMap<Text, Nat>,
    resolvedCompoundTypes: Buffer.Buffer<ShallowCompoundType<ReferenceType>>) : Int {
      switch (arg) {
        case (#indexOrCode(i)) {
          if (i < 0) {
            return i; // Primitive
          };
          let mapArg = func (t: ReferenceOrRecursiveType) : ReferenceType {
            resolveArg(t, shallowTypeArray, recursiveTypeIndexMap, resolvedCompoundTypes);
          };
          // Compound
          let t: ShallowCompoundType<ReferenceType> = switch (shallowTypeArray[Int.abs(i)]) {
            case (#Option(o)) {
              let innerResolution = mapArg(o);
              #Option(innerResolution);
            };
            case (#Vector(v)) {
              let innerResolution: Int = mapArg(v);
              #Vector(innerResolution);
            };
            case (#Record(r)) {
              let resolvedFields = Array.map(r, func(f: RecordFieldReferenceType<ReferenceOrRecursiveType>): RecordFieldReferenceType<ReferenceType> {
                let innerResolution: Int = mapArg(f._type);
                { tag=f.tag; _type=innerResolution }
              });
              #Record(resolvedFields);
            };
            case (#Variant(v)) {
              let resolvedOptions = Array.map(v, func(o: VariantOptionReferenceType<ReferenceOrRecursiveType>): VariantOptionReferenceType<ReferenceType> {
                let innerResolution: Int = mapArg(o._type);
                { tag=o.tag; _type=innerResolution }
              });
             #Variant(resolvedOptions);
            };
            case (#Func(f)) {
              let argTypes = Array.map(f.argTypes, mapArg);
              let returnTypes = Array.map(f.returnTypes, mapArg);
              #Func({
                modes=f.modes;
                argTypes=argTypes;
                returnTypes=returnTypes;
              });
            };
            case (#Service(s)) {
              let methods = Array.map<(Text, ReferenceOrRecursiveType), (Text, ReferenceType)>(s.methods, func (m) {
                let t = mapArg(m.1);
                (m.0, t);
              });
              #Service({
                methods=methods;
              });
            };
          };
          let index = resolvedCompoundTypes.size();
          resolvedCompoundTypes.add(t);
          index;
        };
        case (#recursiveReference(r)) {
          switch(recursiveTypeIndexMap.get(r)) {
            case (null) Debug.trap("Unable to find named type reference '" # r # "'");
            case (?i) i; 
          };
        };
      }
  };


  private func buildShallowTypes(
    buffer: Buffer.Buffer<ShallowCompoundType<ReferenceOrRecursiveType>>,
    recursiveTypes: TrieMap.TrieMap<Text, Nat>,
    uniqueTypeMap: TrieMap.TrieMap<NonRecursiveCompoundType, Nat>,
    t: Type.Type) : ReferenceOrRecursiveType {
    
    let compoundType: NonRecursiveCompoundType = switch (t) {
      case (#Option(o)) #Option(o);
      case (#Vector(v)) #Vector(v);
      case (#Variant(v))#Variant(v);
      case (#Record(r)) #Record(r);
      case (#Func(f)) #Func(f);
      case (#Service(s)) #Service(s);
      case (#recursiveType(rT)) {
        let innerReferenceType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, rT._type);
        switch (innerReferenceType){
          case (#indexOrCode(i)) {
            if (i < 0) {
              Debug.trap("Recursive types can only be compound types");
            };
            recursiveTypes.put(rT.id, Int.abs(i));
            return #indexOrCode(i);
          };
          case (#recursiveReference(r)) Debug.trap("A named recursived type cannot itself be a recursive reference");
        };
      };
      case (#recursiveReference(r)) {
        return #recursiveReference(r);
      };
      // Primitives are just type codes
      case (#Int) return #indexOrCode(TypeCode.int);
      case (#Int8) return #indexOrCode(TypeCode.int8);
      case (#Int16) return #indexOrCode(TypeCode.int16);
      case (#Int32) return #indexOrCode(TypeCode.int32);
      case (#Int64) return #indexOrCode(TypeCode.int64);
      case (#Nat) return #indexOrCode(TypeCode.nat);
      case (#Nat8) return #indexOrCode(TypeCode.nat8);
      case (#Nat16) return #indexOrCode(TypeCode.nat16);
      case (#Nat32) return #indexOrCode(TypeCode.nat32);
      case (#Nat64) return #indexOrCode(TypeCode.nat64);
      case (#Null) return #indexOrCode(TypeCode._null);
      case (#Bool) return #indexOrCode(TypeCode.bool);
      case (#Float32) return #indexOrCode(TypeCode.float32);
      case (#Float64) return #indexOrCode(TypeCode.float64);
      case (#Text) return #indexOrCode(TypeCode.text);
      case (#Reserved) return #indexOrCode(TypeCode.reserved);
      case (#Empty) return #indexOrCode(TypeCode.empty);
      case (#Principal) return #indexOrCode(TypeCode.principal);
    };
    switch (uniqueTypeMap.get(compoundType)) {
      case (null) {}; // No duplicate found, continue
      case (?i) return #indexOrCode(i); // Duplicate type, return index
    };
    

    let rT: ShallowCompoundType<ReferenceOrRecursiveType> = switch (compoundType) {
      case (#Option(o)) {
        let innerTypeReference: ReferenceOrRecursiveType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, o);
        #Option(innerTypeReference);
      };
      case (#Vector(v)) {
        let innerTypeReference: ReferenceOrRecursiveType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, v);
        #Vector(innerTypeReference);
      };
      case (#Record(r)) {
        let fields : [RecordFieldReferenceType<ReferenceOrRecursiveType>] = Iter.toArray(Iter.map<RecordFieldType, RecordFieldReferenceType<ReferenceOrRecursiveType>>(Iter.fromArray(r), func (f: RecordFieldType) : RecordFieldReferenceType<ReferenceOrRecursiveType> {
          let indexOrCode : ReferenceOrRecursiveType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, f._type);
          { tag = f.tag; _type = indexOrCode };
        }));
        #Record(fields);
      };
      case (#Variant(v)) {
        let options : [VariantOptionReferenceType<ReferenceOrRecursiveType>] = Iter.toArray(Iter.map<VariantOptionType, VariantOptionReferenceType<ReferenceOrRecursiveType>>(Iter.fromArray(v), func (o: VariantOptionType) : VariantOptionReferenceType<ReferenceOrRecursiveType> {
          let indexOrCode : ReferenceOrRecursiveType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, o._type);
          { tag = o.tag; _type = indexOrCode };
        }));
       #Variant(options);
      };
      case (#Func(fn)) {
        let funcTypesToReference = func (types : [Type.Type]) : [ReferenceOrRecursiveType] {          
          let refTypeBuffer = Buffer.Buffer<ReferenceOrRecursiveType>(types.size());
          for (t in Iter.fromArray(types)) {
            let refType : ReferenceOrRecursiveType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, t);
            refTypeBuffer.add(refType);
          };
          refTypeBuffer.toArray();
        };
        let argTypes : [ReferenceOrRecursiveType] = funcTypesToReference(fn.argTypes);
        let returnTypes : [ReferenceOrRecursiveType] = funcTypesToReference(fn.returnTypes);
        #Func({
          modes=fn.modes;
          argTypes=argTypes;
          returnTypes=returnTypes;
        });
      };
      case (#Service(s)) {
        let methods : [(Text, ReferenceOrRecursiveType)] = Array.map<(Text, Type.FuncType), (Text, ReferenceOrRecursiveType)>(s.methods, func (a: (Text, Type.FuncType)) : (Text, ReferenceOrRecursiveType) {
          let refType : ReferenceOrRecursiveType = buildShallowTypes(buffer, recursiveTypes, uniqueTypeMap, #Func(a.1));
          (a.0, refType);
        });
        #Service({
          methods=methods;
        });
      };
    };
    let index = buffer.size();
    uniqueTypeMap.put(compoundType, index);
    buffer.add(rT);
    #indexOrCode(index);
  };


  private func encodeValues(buffer : Buffer.Buffer<Nat8>, table: CompoundTypeTable, args : [Value.Value]) {
    var i = 0;
    for (arg in Iter.fromArray(args)) {
      encodeValue(buffer, arg, table.typeCodes[i], table.compoundTypes);
      i += 1;
    };
  };

  private func encodeValue(buffer : Buffer.Buffer<Nat8>, value : Value.Value, t : ReferenceType, types: [ShallowCompoundType<ReferenceType>]) {
    if (t < 0) {
      return switch (value) {
        case (#Int(i)) IntX.encodeInt(buffer, i, #signedLEB128);
        case (#Int8(i8)) IntX.encodeInt8(buffer, i8);
        case (#Int16(i16)) IntX.encodeInt16(buffer, i16, #lsb);
        case (#Int32(i32)) IntX.encodeInt32(buffer, i32, #lsb);
        case (#Int64(i64)) IntX.encodeInt64(buffer, i64, #lsb);
        case (#Nat(n)) NatX.encodeNat(buffer, n, #unsignedLEB128);
        case (#Nat8(n8)) NatX.encodeNat8(buffer, n8);
        case (#Nat16(n16)) NatX.encodeNat16(buffer, n16, #lsb);
        case (#Nat32(n32)) NatX.encodeNat32(buffer, n32, #lsb);
        case (#Nat64(n64)) NatX.encodeNat64(buffer, n64, #lsb);
        case (#Null) {}; // Nothing to encode
        case (#Bool(b)) buffer.add(if (b) 0x01 else 0x00);
        case (#Float32(f)) {
          let floatX : FloatX.FloatX = FloatX.fromFloat(f, #f32);
          FloatX.encode(buffer, floatX, #lsb);
        };
        case (#Float64(f)) {
          let floatX : FloatX.FloatX = FloatX.fromFloat(f, #f64);
          FloatX.encode(buffer, floatX, #lsb);
        };
        case (#Text(t)) {
          encodeText(buffer, t);
        };
        case (#Reserved) {}; // Nothing to encode 
        case (#Empty) {}; // Nothing to encode
        case (#Principal(p)) encodeTransparencyState<Principal>(buffer, p, encodePrincipal);
        case (_) Debug.trap("Invalid type definition. Doesn't match value");
      }
    };

    // Compound types
    let i = Int.abs(t);
    switch (value) {
      case (#Option(o)) {
        switch (o) {
          case (null) buffer.add(0x00); // Indicate there is no value
          case (?v) {
            buffer.add(0x01); // Indicate there is a value
            let innerType : ReferenceType = switch(types[i]) {
              case (#Option(inner)) inner;
              case (_) Debug.trap("Invalid type definition. Doesn't match value");
            };
            encodeValue(buffer, v, innerType, types); // Encode value
          };
        };
      };
      case (#Vector(ve)) {
        let innerType : ReferenceType = switch(types[i]) {
          case (#Vector(inner)) inner;
          case (_) Debug.trap("Invalid type definition. Doesn't match value");
        };
        NatX.encodeNat(buffer, ve.size(), #unsignedLEB128); // Encode the length of the vector
        for (v in Iter.fromArray(ve)) {
          encodeValue(buffer, v, innerType, types); // Encode each value
        };
      };
      case (#Record(r)) {
        let innerTypes : TrieMap.TrieMap<Tag, ReferenceType> = switch(types[i]) {
          case (#Record(inner)) {
            let innerKV = Iter.fromArray(Array.map<RecordFieldReferenceType<ReferenceType>, (Tag, ReferenceType)>(inner, func(i) { (i.tag, i._type) }));
            TrieMap.fromEntries<Tag, ReferenceType>(innerKV, Tag.equal, Tag.hash);
          };
          case (_) Debug.trap("Invalid type definition. Doesn't match value");
        };
        // Sort properties by the hash of the
        let sortedKVs : [RecordFieldValue] = Array.sort<RecordFieldValue>(r, InternalTypes.tagObjCompare);
        
        for (kv in Iter.fromArray(sortedKVs)) {
          let innerType = switch(innerTypes.get(kv.tag)) {
            case (?t) t;
            case (_) Debug.trap("Invalid type definition. Doesn't match value");
          };
          encodeValue(buffer, kv.value, innerType, types); // Encode each value in order
        };
      };
      case (#Func(f)) {
        encodeTransparencyState<Value.Func>(buffer, f, func(b, f) {
          let innerType : InternalTypes.FuncReferenceType<ReferenceType> = switch(types[i]) {
            case (#Func(inner)) inner;
            case (_) Debug.trap("Invalid type definition. Doesn't match value");
          };
          encodeValue(buffer, #Principal(f.service), TypeCode.principal, types); // Encode the service
          encodeValue(buffer, #Text(f.method), TypeCode.text, types); // Encode the method
        });
      };
      case (#Service(s)) encodeTransparencyState<Principal>(buffer, s, encodePrincipal);
      case (#Variant(v)) {
        let innerTypes : [InternalTypes.VariantOptionReferenceType<ReferenceType>] = switch(types[i]) {
          case (#Variant(inner)) inner;
          case (_) Debug.trap("Invalid type definition. Doesn't match value");
        };
        var typeIndex : ?Nat = firstIndexOf<InternalTypes.VariantOptionReferenceType<ReferenceType>>(innerTypes, func (t) { Tag.equal(t.tag, v.tag) });
        switch(typeIndex) {
          case (?i) {
            NatX.encodeNat(buffer, i, #unsignedLEB128); // Encode tag value
            encodeValue(buffer, v.value, innerTypes[i]._type, types); // Encode value
          };
          case (null) Debug.trap("Invalid type definition. Doesn't match value");
        };
      };
      case (_) Debug.trap("Invalid type definition. Doesn't match value");
    };
  };

  private func encodeTransparencyState<T>(buffer: Buffer.Buffer<Nat8>, r: TransparencyState.TransparencyState<T>, encodeInner: (Buffer.Buffer<Nat8>, T) -> ()) {
    switch (r) {
      case (#opaque) {
        buffer.add(0x00); // 0 if opaque
      };
      case (#transparent(t)) {
        buffer.add(0x01); // 1 if transparent
        encodeInner(buffer, t);
      }
    }
  };

  private func encodePrincipal(buffer: Buffer.Buffer<Nat8>, p: Principal) {
    let bytes : [Nat8] = Blob.toArray(Principal.toBlob(p));
    NatX.encodeNat(buffer, bytes.size(), #unsignedLEB128); // Encode the byte length
    for (b in Iter.fromArray(bytes)) {
      buffer.add(b); // Encode the raw principal bytes
    };
  };

  private func firstIndexOf<T>(a : [T], isMatch: (T) -> Bool) : ?Nat {
    var i : Nat = 0;
    for (item in Iter.fromArray(a)){
      if (isMatch(item)) {
        return ?i;
      };
      i += 1;
    };
    return null;
  };

  private func encodeText(buffer: Buffer.Buffer<Nat8>, t: Text) {
    let utf8Bytes : Blob = Text.encodeUtf8(t);
    NatX.encodeNat(buffer, utf8Bytes.size(), #unsignedLEB128);
    for (byte in utf8Bytes.vals()) {
      buffer.add(byte);
    };
  }
};