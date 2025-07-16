/// A module for converting between JSON and Motoko values.

import JSON "../../submodules/json.mo/src/JSON";

import Candid "../Candid";
import FromText "FromText";
import ToText "ToText";
import Utils "../Utils";

module {
    public type JSON = JSON.JSON;
    public let defaultOptions = Candid.defaultOptions;

    public let { fromText; toCandid } = FromText;

    public let { toText; fromCandid } = ToText;

    public let concatKeys = Utils.concatKeys;
};
