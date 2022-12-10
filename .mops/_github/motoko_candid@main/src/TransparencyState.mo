
module {
  public type TransparencyState<T> = {
    #opaque;
    #transparent : T;
  };
}