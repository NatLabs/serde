import Iter "mo:base/Iter";

import Itertools "mo:itertools/Iter";

import CandidTypes "Candid/Types";
import UrlEncodedModule "UrlEncoded";
import JsonModule "JSON";
import CandidModule "Candid";

module {

    public type Options = CandidTypes.Options;

    public type Candid = CandidTypes.Candid;

    public let Candid = CandidModule;
    public let JSON = JsonModule;
    public let URLEncoded = UrlEncodedModule;

    public func concatKeys(keys : [[Text]]) : [Text] {
        Iter.toArray(
            Itertools.flattenArray(keys)
        )
    };
}