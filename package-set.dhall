let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.4/package-set.dhall sha256:30b7e5372284933c7394bad62ad742fec4cb09f605ce3c178d892c25a1a9722e
let vessel_package_set = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.20-20220131/package-set.dhall

let Package = { 
	name : Text, 
	version : Text, 
	repo : Text, 
	dependencies : List Text 
}

-- This is where you can add your own packages to the package-set
let additions = [
	{ 
		name = "motoko_candid", 
		version = "main", 
		repo = "https://github.com/tomijaga/motoko_candid", 
		dependencies = [] : List Text
	},
	{ 
		name = "xtendedNumbers", 
		version = "v1.0.0", 
		repo = "https://github.com/gekctek/motoko_numbers", 
		dependencies = [] : List Text
	},
	{ 
		name = "json", 
		version = "v0.2.0", 
		repo = "https://github.com/aviate-labs/json.mo", 
		dependencies = [] : List Text
	}
] : List Package

in  aviate_labs # vessel_package_set # additions
