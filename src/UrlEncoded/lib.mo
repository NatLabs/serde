/// A module for converting between Motoko values and Url-Encoded `Text`.

import Candid "../Candid";
import FromText "./FromText";
import ToText "./ToText";

import Utils "../Utils";
module {
    public let { fromText; toCandid } = FromText;

    public let { toText; fromCandid } = ToText;

    public let concatKeys = Utils.concatKeys;
    public let defaultOptions = Candid.defaultOptions;

};
