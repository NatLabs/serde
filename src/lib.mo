
import CandidType "Candid/Types";
import UrlEncodedModule "UrlEncoded";
import JsonModule "JSON";
import CandidModule "Candid";
import CborModule "CBOR";

import Utils "Utils";

module {

    public type Options = CandidType.Options;

    public type Candid = CandidType.Candid;
    public let Candid = CandidModule;

    public type CandidType = CandidType.CandidType;

    public let JSON = JsonModule;
    public let URLEncoded = UrlEncodedModule;
    public let CBOR = CborModule;

    public let concatKeys = Utils.concatKeys;
    public let defaultOptions = CandidType.defaultOptions;
}