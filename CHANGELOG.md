# Changelog

## 0.3.0

* Downcase all fields' and attributes' names
* Made possible to selective remove generated indexes from the configuration -- `Mongoid::Giza::Configuration#remove_generated_indexes`
* Made possible to remove from the configuratio only the generated indexes of a model -- `Mongoid::Giza::clear_generated_sphinx_indexes_configuration`

## 0.2.0

* Use ERB to parse string settings of every section of the configuration
* Renamed `Mongoid::Giza::Indexer#full_index` to `Mongoid::Giza::Indexer#full_index!`
* Always convert `Mongoid::Giza::Index::Field` and `Mongoid::Giza::Index::Attribute` names to symbol

## 0.1.0

**Initial release**
