# Changelog

## 0.6.2

* Allow underscore on fields' and attributes' names

## 0.6.1

* Only allow alphabetical characters on fields' and attributes' names (replaces everything else with **-**)
* Fields' name and attributes' name and type are read-only

## 0.6.0

* Mongoid 4 or higher is now required
* Removed charset_type option, since it has been removed from spinx since 2.2.2-beta. You can still define it in your confuguration if you're using an older sphinx version
* Renamed `Mongoid::Giza::GizaID` to `Mongoid::Giza::ID`
* Renamed `Mongoid::Giza::ID::next_id to Mongoid::Giza::ID::next`
* Renamed `giza_id` to `_giza_id`. Now it's a regular field instead of being dynamically assigned when needed
* Support for `default` and `bits` for attributes
* Removed *str2ordinal* and *str2wordcount* attribute types
* Automatically convert Date, Time and DateTime attributes to unix time
* Only support **ONE** fulltext query by *search block*. Instead of returning an Array o result Hashes now it only returns a result Hash

## 0.5.1

* Create a sparse unique index on `giza_id` field

## 0.5.0

* Clear the generated indexes configuration when regenerating dynamic indexes
* Removed `Mongoid::Giza::clear_generated_sphinx_indexes_configuration` method
* Added `Mongoid::Giza::remove_generated_sphinx_indexes` method to remove selected generated indexes
* Changed the indexes names parameter of `Mongoid::Giza::Search#initialize` from splat to array
* Renamed `Mongoid::Giza#generate_dynamic_sphinx_indexes` to `Mongoid::Giza#generate_sphinx_indexes`
* Renamed `Mongoid::Giza::regenerate_dynamic_sphinx_indexes` to `Mongoid::Giza::regenerate_sphinx_indexes`
* Renamed `Mongoid::Giza::Index#generate_xmlpipe2` to `Mongoid::Giza::Index#xmlpipe2`

## 0.4.0

* Do not render the configuration file on `Mongoid::Giza::Indexer#index!`
* Do not force the verbose indexing
* Added `Mongoid::Giza::giza_configuration` accessor
* Fix converting the index name to symbol
* Added `Mongoid::Giza::DynamicIndex#generate_index` method to generate the dynamic index for a single object
* Added `Mongoid::Giza#generate_dynamic_sphinx_indexes` method to generate all dynamic indexes for the object

## 0.3.0

* Downcase all fields' and attributes' names
* Made possible to selective remove generated indexes from the configuration -- `Mongoid::Giza::Configuration#remove_generated_indexes`
* Made possible to remove from the configuration only the generated indexes of a model -- `Mongoid::Giza::clear_generated_sphinx_indexes_configuration`

## 0.2.0

* Use ERB to parse string settings of every section of the configuration
* Renamed `Mongoid::Giza::Indexer#full_index` to `Mongoid::Giza::Indexer#full_index!`
* Always convert `Mongoid::Giza::Index::Field` and `Mongoid::Giza::Index::Attribute` names to symbol

## 0.1.0

**Initial release**
