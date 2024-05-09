
import CandidTypes "Candid/Types";
import UrlEncodedModule "UrlEncoded";
import JsonModule "JSON";
import CandidModule "Candid";
import CborModule "CBOR";

import Utils "Utils";

module {

    public type Options = CandidTypes.Options;

    public type Candid = CandidTypes.Candid;
    public let Candid = CandidModule;

    public let JSON = JsonModule;
    public let URLEncoded = UrlEncodedModule;
    public let CBOR = CborModule;

    public let concatKeys = Utils.concatKeys;
    public let defaultOptions = CandidTypes.defaultOptions;
}