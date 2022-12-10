import Encoder "../src/Encoder";
import Decoder "../src/Decoder";
import Arg "../src/Arg";
import Debug "mo:base/Debug";

actor Sample {
  func call_raw(p : Principal, m : Text, a : Blob) : async Blob {

      // Parse parameters
      let args: [Arg.Arg] = switch(Decoder.decode(a)) {
        case (null) Debug.trap("Invalid candid");
        case (?c) c;
      };

      // Validate request...
      
      // Process request...

      // Return result
      let returnArgs: [Arg.Arg] = [
        {
          _type=#Bool;
          value=#Bool(true)
        }
      ];
      Encoder.encode(returnArgs);
  };
};
