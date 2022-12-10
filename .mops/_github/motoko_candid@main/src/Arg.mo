import Value "./Value";
import Type "./Type";


module {
  public type Arg = {
    value: Value.Value;
    _type: Type.Type;
  };
}